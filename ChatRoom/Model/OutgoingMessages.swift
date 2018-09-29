//
//  OutgoingMessage.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/28.
//  Copyright © 2018 PinguMac. All rights reserved.
//

import Foundation

class OutgoingMessages {
  
  // MARK: - Porperties
  let messaageDictionary: NSMutableDictionary
  
  // MARK: - Initializers
  
  // For Text Message
  init(message: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
    messaageDictionary = NSMutableDictionary(objects: [message,
                                                       senderId,
                                                       senderName,
                                                       dateFormatter().string(from: date),
                                                       status,
                                                       type],
                                             forKeys: [kMESSAGE as NSCopying,
                                                       kSENDERID as NSCopying,
                                                       kSENDERNAME as NSCopying,
                                                       kDATE as NSCopying,
                                                       kSTATUS as NSCopying,
                                                       kTYPE as NSCopying])
  }
    
  func sendMessage(chatRoomID: String, messaageDictionary: NSMutableDictionary, memberIds: [String], membersToPush: [String]) {
    
    let messageId = UUID().uuidString
    
    messaageDictionary[kMESSAGEID] = messageId
    
    for memberId in memberIds {
      reference(.Message).document(memberId).collection(chatRoomID).document(messageId).setData(messaageDictionary as! [String : Any])
      
      
      
      
    }
  }
  
}
