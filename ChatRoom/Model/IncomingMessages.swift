//
//  IncomingMessage.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/29.
//  Copyright © 2018 PinguMac. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessages {
  
  // MARK: - Porperties
  var collectionView: JSQMessagesCollectionView
  
  // MARK: - Initializers
  init(collectionView_: JSQMessagesCollectionView) {
    self.collectionView = collectionView_
  }
  
  func createMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage? {
    
    var message: JSQMessage?
    
    let type = messageDictionary[kTYPE] as! String
    
    switch type {
    case kTEXT:
      // create text message
      message = createTextMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
      
    case kPICTURE:
      // create picture message
      print("create picture message")
      
    case kVIDEO:
      // create video message
      print("create video message")
      
    case kAUDIO:
      // create audio message
      print("create audio message")
      
    case kLOCATION:
      // create location message
      print("create location message")
      
    default:
      print("Unknown message type")
    }
    
    if message != nil {
      return message
    } else {
      return nil
    }
    
  }
  
  func createTextMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
    
    let name = messageDictionary[kSENDERNAME] as! String
    let senderId = messageDictionary[kSENDERID] as! String
    let text = messageDictionary[kMESSAGE] as! String
    
    var date: Date!
    
    if let created = messageDictionary[kDATE] {
      if (created as! String).count != dateLength {
        date = Date()
      } else {
        date = dateFormatter().date(from: created as! String)
      }
    } else {
      date = Date()
    }
    
    return JSQMessage(senderId: senderId, senderDisplayName: name, date: date, text: text)
  }
}
