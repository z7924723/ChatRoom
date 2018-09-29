//
//  JSQMessagesInputToolbar.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/28.
//  Copyright © 2018 PinguMac. All rights reserved.
//

import JSQMessagesViewController

// To fix Iphone X Layout
extension JSQMessagesInputToolbar {
  override open func didMoveToWindow() {
    super.didMoveToWindow()
    guard let window = window else { return }
    if #available(iOS 11.0, *) {
      let anchor = window.safeAreaLayoutGuide.bottomAnchor
      bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
    }
  }
}
