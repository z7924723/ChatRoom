//
//  ChatsViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/22.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ChatsViewController: UIViewController {
  
  // MARK: - Porperties
  @IBOutlet weak var tableView: UITableView!
  
  var recentChats: [NSDictionary] = []
  var filteredChats: [NSDictionary] = []
  var recentListener: ListenerRegistration!
  
  let searchController = UISearchController(searchResultsController: nil)
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = true
    searchController.searchResultsUpdater = self
    searchController.dimsBackgroundDuringPresentation = false
    definesPresentationContext = true
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    loadRecentChats()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    recentListener.remove()
  }
  
  // MARK: - Actions
  @IBAction func createNewChat(_ sender: Any) {
    let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UsersTableView") as! UsersTableViewController
    
    self.navigationController?.pushViewController(userVC, animated: true)
  }
  
  @IBAction func groupChat(_ sender: UIButton) {
    print("group press")
  }
  
  // MARK: - Helper
  func loadRecentChats() {
    
    recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ [weak self] (snapshot, error) in
      
      guard let snapshot = snapshot else { return }
      
      if let error = error {
        print("Error retreiving collection: \(error)")
      }
      
      if !snapshot.isEmpty {
        let sorted = (dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
        
        for recent in sorted {
          if (recent[kLASTMESSAGE] as! String != "") && (recent[kCHATROOMID] != nil) && (recent[kRECENTID] != nil) {
            self!.recentChats.append(recent)
          }
        }
        
        self!.tableView.reloadData()
      }
    })
    
  }
  
  func showUserProfile(user: FUser) {
    let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileTableView") as! ProfileTableViewController
    
    profileVC.user = user
    
    self.navigationController?.pushViewController(profileVC, animated: true)
  }
}

extension ChatsViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if (searchController.isActive) && (searchController.searchBar.text != "") {
      return filteredChats.count
    } else {
      return recentChats.count
    }
    
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "RecentChatTableViewCell", for: indexPath) as! RecentChatsTableViewCell
    var recent: NSDictionary
    
    cell.delegate = self
    
    if (searchController.isActive) && (searchController.searchBar.text != "") {
      recent = filteredChats[indexPath.row]
    } else {
      recent = recentChats[indexPath.row]
    }
    
    cell.generateCellWith(recentChat: recent, indexPath: indexPath)
    
    return cell
    
  }
  
}

extension ChatsViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
    var tempRecent: NSDictionary!
    
    if (searchController.isActive) && (searchController.searchBar.text != "") {
      tempRecent = filteredChats[indexPath.row]
    } else {
      tempRecent = recentChats[indexPath.row]
    }
    
    var muteTitle = "Unmute"
    var mute = false

    if (tempRecent[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId()) {
      muteTitle = "mute"
      mute = true
    }
    
    let deleteAction = UITableViewRowAction(style: .default, title: "Delete") {
      [weak self] (action, indexPath) in
      self!.recentChats.remove(at: indexPath.row)
      deleteRecentChat(recentChat: tempRecent)
      self!.tableView.reloadData()
    }
    
    let muteAction = UITableViewRowAction(style: .default, title: muteTitle) {
      [weak self] (action, indexPath) in
      print("mute \(indexPath)")
    }
    
    muteAction.backgroundColor = #colorLiteral(red: 0, green: 0.2279537671, blue: 1, alpha: 1)
    
    return [deleteAction, muteAction]
    
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    var recent: NSDictionary!
    
    if (searchController.isActive) && (searchController.searchBar.text != "") {
      recent = filteredChats[indexPath.row]
    } else {
      recent = recentChats[indexPath.row]
    }
    
    restartRecentChat(recentChat: recent)
    
    let chatVC = ChatViewController()
    chatVC.hidesBottomBarWhenPushed = true
    chatVC.chatRoomId = (recent[kCHATROOMID] as? String)!
    chatVC.memberIds = (recent[kMEMBERS] as? [String])!
    chatVC.membersToPush = (recent[kMEMBERSTOPUSH] as? [String])!
    chatVC.titleName = (recent[kWITHUSERFULLNAME] as? String)!
    
    navigationController?.pushViewController(chatVC, animated: true)

  }
}

extension ChatsViewController: RecentChatsTableViewCellDelegate {
  
  func didTappedAvatorImage(indexPath: IndexPath) {
    
    var recentChat: NSDictionary!
    
    if (searchController.isActive) && (searchController.searchBar.text != "") {
      recentChat = filteredChats[indexPath.row]
    } else {
      recentChat = recentChats[indexPath.row]
    }
    
    if recentChat[kTYPE] as! String == kPRIVATE {
      reference(.User).document(recentChat[kWITHUSERUSERID] as! String).getDocument { [weak self] (snapshot, error) in
        guard let snapshot = snapshot else { return }
        
        if snapshot.exists {
          let userDictionary = snapshot.data() as NSDictionary
          let tempUser = FUser(_dictionary: userDictionary)
          
          self!.showUserProfile(user: tempUser)
        }
      }
    }
    
  }
  
}

extension ChatsViewController: UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {
    
    filterContentForSearchText(searchText: searchController.searchBar.text!)
    
  }

  private func filterContentForSearchText(searchText: String, scope: String = "All") {
    
    filteredChats = recentChats.filter({ (recentChat) -> Bool in
      return (recentChat[kWITHUSERFULLNAME] as! String).lowercased().contains(searchText.lowercased())
    })
    
    tableView.reloadData()
    
  }
}
