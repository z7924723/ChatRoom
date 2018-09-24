//
//  Recent.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/24.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import Foundation

func startPrivateChat(user1: FUser, user2: FUser) -> String {
  
  let user1Id = user1.objectId
  let user2Id = user2.objectId
  
  var chatRoomId = ""
  
  let value = user1Id.compare(user2Id).rawValue
  
  if value < 0 {
    chatRoomId = user1Id + user2Id
  } else {
    chatRoomId = user2Id + user1Id
  }
  
  let members = [user1Id, user2Id]
  
  createRecent(members: members,
               chatRoomId: chatRoomId,
               withUserUserName: "",
               type: kPRIVATE,
               users: [user1, user2],
               avatorOfGroup: nil)
  
  return chatRoomId
}

func createRecent(members: [String], chatRoomId: String, withUserUserName: String, type: String, users: [FUser]?, avatorOfGroup: String?) {
  
  var tempMembers = members
  
  reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
    
    guard let snapshot = snapshot else {
      return
    }
    
    if !snapshot.isEmpty {
      for recent in snapshot.documents {
        let currentRecent = recent.data() as NSDictionary
        
        if let currentUserId = currentRecent[kUSERID] {
          if tempMembers.contains(currentUserId as! String) {
            tempMembers.remove(at: tempMembers.index(of: currentUserId as! String)!)
          }
        }
      }
    }
    
    for userId in tempMembers {
      createRecentItem(userId: userId,
                       chatRoomId: chatRoomId,
                       members: members,
                       withUserUserName: withUserUserName,
                       type: type,
                       users: users,
                       avatorOfGroup: avatorOfGroup)
    }
    
  }
  
}

func createRecentItem(userId: String, chatRoomId: String, members: [String], withUserUserName: String, type: String, users: [FUser]?, avatorOfGroup: String?) {
  
  let localReference = reference(.Recent).document()
  let recentId = localReference.documentID
  
  let date = dateFormatter().string(from: Date())
  
  var recent: [String : Any]!
  
  if type == kPRIVATE {
    var withUser: FUser?
    
    if users != nil && users!.count > 0 {
      if userId == FUser.currentId() {
        withUser = users!.last
      } else {
        withUser = users?.first
      }
    }
    
    recent = [kRECENTID : recentId,
              kUSERID : userId,
              kCHATROOMID : chatRoomId,
              kMEMBERS : members,
              kMEMBERSTOPUSH : members,
              kWITHUSERFULLNAME : withUser!.fullname,
              kWITHUSERUSERID : withUser!.objectId,
              kLASTMESSAGE : "",
              kCOUNTER : 0,
              kDATE : date,
              kTYPE : type,
              kAVATAR : withUser!.avatar] as [String : Any]
  } else {
    if avatorOfGroup != nil {
      recent = [kRECENTID : recentId,
                kUSERID : userId,
                kCHATROOMID : chatRoomId,
                kMEMBERS : members,
                kMEMBERSTOPUSH : members,
                kWITHUSERFULLNAME : withUserUserName,
                kLASTMESSAGE : "",
                kCOUNTER : 0,
                kDATE : date,
                kTYPE : type,
                kAVATAR : avatorOfGroup!] as [String : Any]
    }
  }
  
  // Save recent chat to firebase
  localReference.setData(recent)
  
}
