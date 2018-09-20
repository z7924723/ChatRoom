//
//  CollectionReference.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/19.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum FCollectionReference: String {
  case User
  case Typing
  case Recent
  case Message
  case Group
  case Call
}

func reference(_ collectionReference: FCollectionReference) -> CollectionReference {
  return Firestore.firestore().collection(collectionReference.rawValue)
}
