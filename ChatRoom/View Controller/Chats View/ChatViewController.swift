//
//  ChatViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/28.
//  Copyright © 2018 PinguMac. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import AVKit
import AVFoundation
import FirebaseFirestore

class ChatViewController: JSQMessagesViewController {
  
  // MARK: - Porperties
  var chatRoomId: String!
  var memberIds: [String]!
  var membersToPush: [String]!
  var titleName: String!
  var isGroup: Bool?
  var group: NSDictionary?
  var withUsers: [FUser] = []
  
  var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleRed())
  var incomingBubble = JSQMessagesBubbleImageFactory()?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
  
  var messages: [JSQMessage] = []
  var objectMessages: [NSDictionary] = []
  var loadedMessages: [NSDictionary] = []
  var allPictureMessages: [String] = []
  var initialLoadComplete = false
  
  var maxMessageNumber = 0
  var minMessageNumber = 0
  var loadOldMessage = false
  var loadedMessagesCount = 0
  
  var typingListener: ListenerRegistration?
  var newChatListener: ListenerRegistration?
  var updateChatListener: ListenerRegistration?
  
  let legitTypes = [kAUDIO, kPICTURE, kTEXT, kLOCATION, kVIDEO]
  
  let leftBarButtonView: UIView = {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
    return view
  }()
  
  let avatorButton: UIButton = {
    let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
    return button
  }()
  
  let titleLabel: UILabel = {
    let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
    title.textAlignment = .left
    title.font = UIFont(name: title.font.fontName, size: 14)
    return title
  }()
  
  let subTitleLabel: UILabel = {
    let subTitle = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
    subTitle.textAlignment = .left
    subTitle.font = UIFont(name: subTitle.font.fontName, size: 14)
    return subTitle
  }()
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.senderId = FUser.currentId()
    self.senderDisplayName = FUser.currentUser()!.firstname
    
    customView()
    customSendButton()
    
    loadMessages()
  }
  
  // MARK: - Helper
  private final func customView() {
    self.navigationItem.largeTitleDisplayMode = .never
    self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
    
    collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
    collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
    
    customNavigationItem()
  }
  
  private final func customNavigationItem() {
    let infoBarButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
    
    leftBarButtonView.addSubview(avatorButton)
    leftBarButtonView.addSubview(titleLabel)
    leftBarButtonView.addSubview(subTitleLabel)
    let leftBarButton = UIBarButtonItem(customView: leftBarButtonView)
    
    self.navigationItem.rightBarButtonItem = infoBarButton
    self.navigationItem.leftBarButtonItems?.append(leftBarButton)
    
    if isGroup! {
      avatorButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
    } else {
      avatorButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
    }
    
    getUsersFromFirestore(withIds: memberIds) { [weak self] (withUsers) in
      
      guard let self = self else { return }
      
      self.withUsers = withUsers
      
      // Get avator
      if !(self.isGroup!) {
        self.setUIForSingleChat()
      }
    }
  }
  
  private final func setUIForSingleChat() {
    let withUser = withUsers.first!
    
    imageFromData(pictureData: withUser.avatar) { (image) in
      
      if image != nil {
        avatorButton.setImage(image!.circleMasked, for: .normal)
      }
      
    }
    
    titleLabel.text = withUser.fullname
    
    if withUser.isOnline {
      subTitleLabel.text = "Online"
    } else {
      subTitleLabel.text = "Offline"
    }
    
    avatorButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
  }
  
  private func customSendButton() {
    self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
    self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
  }
  
  private func loadMessages() {
    
    // Get last 11 messages
    reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: limitMessages).getDocuments { [weak self] (snapshot, error) in
      
      guard let self = self else { return }
      
      guard let snapshot = snapshot else {
        // Initial loading is done
        self.initialLoadComplete = true
        
        // Listent for new chats
        
        return
      }
      
      let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
      
      // Remove bad message
      self.loadedMessages = self.removeBadMessages(allMessages: sorted)
      
      // Insert messages
      self.insertMessages()
      self.finishReceivingMessage(animated: true)
      
      self.initialLoadComplete = true
      print("we have \(self.messages.count) messages")
      // Get Picture messages
      
      
      // Get old message in background
      self.getOldMessageInBackground()
      
      // Start listening for new chats
      self.listenForNewChats()
    }
    
  }
  
  private func listenForNewChats() {
    var lastMessageDate = "0"
    
    if loadedMessages.count > 0 {
      lastMessageDate = loadedMessages.last![kDATE] as! String
    }
    
    newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ [weak self] (snapshot, error) in
      
      guard let self = self else { return }
      
      guard let snapshot = snapshot else { return }
      
      if !snapshot.isEmpty {
        for different in snapshot.documentChanges {
          if (different.type == .added) {
            let item = different.document.data() as NSDictionary
            
            if let type = item[kTYPE] {
              if self.legitTypes.contains(type as! String) {
                
                // For Picture message
                if (type as! String) == kPICTURE {
                  
                }
                
                // For other message
                if self.insertInitialLoadMessage(messageDictionary: item) {
                  JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                }
                
                self.finishReceivingMessage()
              }
            }
            
          }
        }
      }
    })
    
  }
  
  private func getOldMessageInBackground() {
    if loadedMessages.count > kNUMBEROFMESSAGES {
      let firstMessageData = loadedMessages.first![kDATE] as! String
      
      reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageData).getDocuments { [weak self] (snapshot, error) in
        
        guard let self = self else { return }
        
        guard let snapshot = snapshot else { return }
        
        let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)])) as! [NSDictionary]
        
        self.loadedMessages = self.removeBadMessages(allMessages: sorted) + self.loadedMessages
        
        // Get picture message
        
        self.maxMessageNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
        self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
        
        
      }
      
      
    }
  }
  
  private func removeBadMessages(allMessages: [NSDictionary]) -> [NSDictionary] {
    
    var tempMessages = allMessages
    
    for message in tempMessages {
      if message[kTYPE] != nil {
        if !self.legitTypes.contains(message[kTYPE] as! String) {
          tempMessages.remove(at: tempMessages.index(of: message)!)
        }
      } else {
        tempMessages.remove(at: tempMessages.index(of: message)!)
      }
    }
    
    return tempMessages
    
  }
  
  private func insertMessages() {
    
    maxMessageNumber = loadedMessages.count - loadedMessagesCount
    minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
    
    if minMessageNumber < 0 {
      minMessageNumber = 0
    }
    
    for num in minMessageNumber ..< maxMessageNumber {
      let messageDictionary = loadedMessages[num]
      
      // Insert Message
      insertInitialLoadMessage(messageDictionary: messageDictionary)
      
      loadedMessagesCount += 1
    }
    
    self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
  }
  
  private func insertInitialLoadMessage(messageDictionary: NSDictionary) -> Bool {
    
    let incomingMessage = IncomingMessages(collectionView_: self.collectionView!)
    
    // Check if incoming
    if (messageDictionary[kSENDERID] as! String) != FUser.currentId() {
      // Update message status for read or not
      
    }
    
    let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
    
    if message != nil {
      objectMessages.append(messageDictionary)
      messages.append(message!)
    }
    
    return isIncoming(messageDictionary: messageDictionary)
    
  }
  
  private func loadMoreMessage(maxNumber: Int, minNumber: Int) {
    if loadOldMessage {
      maxMessageNumber = minNumber - 1
      minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
    }
    
    if minMessageNumber < 0 {
      minMessageNumber = 0
    }
    
    for index in (minMessageNumber...maxMessageNumber).reversed() {
      let messageDictionary = loadedMessages[index]
      
      insertNewMessage(messageDictionary: messageDictionary)
      loadedMessagesCount += 1
    }
    
    loadOldMessage = true
    self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
  }
  
  private func insertNewMessage(messageDictionary: NSDictionary) {
    let incomingMessage = IncomingMessages(collectionView_: self.collectionView!)
    let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
    
    objectMessages.insert(messageDictionary, at: 0)
    messages.insert(message!, at: 0)
    
  }
  
  private func isIncoming(messageDictionary: NSDictionary) -> Bool {
    
    if FUser.currentId() == messageDictionary[kSENDERID] as! String {
      return false
    } else {
      return true
    }
    
  }
  
  // MARK: - Actions
  @objc func backAction() {
    self.navigationController?.popViewController(animated: true)
  }
  
  @objc func infoButtonPressed() {
    print("show picture")
  }
  
  @objc func showGroup() {
    print("show Group")
  }
  
  @objc func showUserProfile() {
    let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileTableView") as! ProfileTableViewController
    
    profileVC.user = withUsers.first!
    
    self.navigationController?.pushViewController(profileVC, animated: true)
  }
}

extension ChatViewController {
  
  // MARK: - JSQMessages delegate functions
  override func didPressAccessoryButton(_ sender: UIButton!) {
    
    let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
    let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
      print("Camera")
    }
    
    let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
      print("Photo")
    }
    
    let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
      print("Video")
    }
    
    let shareLocation = UIAlertAction(title: "Location Library", style: .default) { (action) in
      print("Location")
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
    }
    
    takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
    sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
    shareVideo.setValue(UIImage(named: "video"), forKey: "image")
    shareLocation.setValue(UIImage(named: "location"), forKey: "image")
    
    optionMenu.addAction(takePhotoOrVideo)
    optionMenu.addAction(sharePhoto)
    optionMenu.addAction(shareVideo)
    optionMenu.addAction(shareLocation)
    optionMenu.addAction(cancelAction)
    
    self.present(optionMenu, animated: true, completion: nil)
  }
  
  override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
    
    if text != "" {
      sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
      updateSendButton(isSend: false)
    } else {
      updateSendButton(isSend: true)
    }
    
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
    
    loadMoreMessage(maxNumber: maxMessageNumber, minNumber: minMessageNumber)
    self.collectionView.reloadData()
  }
  
  // MARK: - Helper
  private func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
    
    var outgoingMessage: OutgoingMessages?
    let currentUser = FUser.currentUser()!
    
    // Text Message
    if let text = text {
      outgoingMessage = OutgoingMessages(message: text, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
    }
    
    JSQSystemSoundPlayer.jsq_playMessageSentSound()
    self.finishSendingMessage()
    
    outgoingMessage!.sendMessage(chatRoomID: chatRoomId,
                                 messaageDictionary: outgoingMessage!.messaageDictionary,
                                 memberIds: memberIds,
                                 membersToPush: membersToPush)
  }
  
  private func updateSendButton(isSend: Bool) {
    
    if isSend {
      self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
    } else {
      self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
    }
    
  }
}

extension ChatViewController {
  
  // MARK: - JSQMessages DataSource functions
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
    
    let data = messages[indexPath.row]
    
    if data.senderId == FUser.currentId() {
      cell.textView.textColor = .white  // Incoming
    } else {
      cell.textView.textColor = .black  // Outcoming
    }
    
    return cell
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
    return messages[indexPath.row]
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return messages.count
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
    let data = messages[indexPath.row]
    
    if data.senderId == FUser.currentId() {
      return outgoingBubble
    } else {
      return incomingBubble
    }
    
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
    
    if (indexPath.item % 3) == 0 {
      let message = messages[indexPath.row]
      
      return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
    }
    
    return nil
    
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
    
    if (indexPath.item % 3) == 0 {
      return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    return 0.0
    
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
    
    let message = objectMessages[indexPath.row]
    
    let status: NSAttributedString!
    let attributedStringColor = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
    
    switch message[kSTATUS] as! String {
    case kDELIVERED:
      status = NSAttributedString(string: kDELIVERED)
      
    case kREAD:
      let statusText = "Read " + readTimeFrom(dateString: message[kREADDATE] as! String)
      status = NSAttributedString(string: statusText, attributes: attributedStringColor)
      
    default:
      status = NSAttributedString(string: "✅")
    }
    
    if indexPath.row == (messages.count - 1) {
      // Last message
      return status
    } else {
      return NSAttributedString(string: "")
    }
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
    
    let data = messages[indexPath.row]
    
    if data.senderId == FUser.currentId() {
      return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    return 0.0
  }
  
  // MARK: - Helper
  private func readTimeFrom(dateString: String) -> String {
    let date = dateFormatter().date(from: dateString)
    
    let currentDateFormat = dateFormatter()
    currentDateFormat.dateFormat = "HH:mm"
    
    return currentDateFormat.string(from: date!)
  }
}

extension ChatViewController {
  
  // MARK: - JSQMessage Text view delegate functions
  override func textViewDidChange(_ textView: UITextView) {
    
    if textView.text != "" {
      updateSendButton(isSend: true)
    } else {
      updateSendButton(isSend: false)
    }
  }
}
