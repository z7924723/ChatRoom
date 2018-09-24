//
//  RecentChatsTableViewCell.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/24.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit

protocol RecentChatsTableViewCellDelegate {
  func didTappedAvatorImage(indexPath: IndexPath)
}

class RecentChatsTableViewCell: UITableViewCell {
  
  // MARK: - Porperties
  @IBOutlet weak var avatorImage: UIImageView!
  @IBOutlet weak var fullNameLabel: UILabel!
  @IBOutlet weak var lastMessageLabel: UILabel!
  @IBOutlet weak var messageCountLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var messageCountBackgroundView: UIView!
  
  var indexPath: IndexPath!
  var delegate: RecentChatsTableViewCellDelegate?
  
  let tapGestureRecognizer = UITapGestureRecognizer()
  
  // MARK: - Initializers
  override func awakeFromNib() {
    super.awakeFromNib()
    
    messageCountBackgroundView.layer.cornerRadius = messageCountBackgroundView.frame.width / 2
    
    configAvatorTapGesture()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  
  }
  
  func generateCellWith(recentChat: NSDictionary, indexPath: IndexPath) {
    
    self.indexPath = indexPath
    self.fullNameLabel.text = recentChat[kWITHUSERFULLNAME] as? String
    self.lastMessageLabel.text = recentChat[kLASTMESSAGE] as? String
    self.messageCountLabel.text = recentChat[kCOUNTER] as? String
    
    if let avatorString = recentChat[kAVATAR] {
      imageFromData(pictureData: avatorString as! String) { (avatorImage) in
        
        if avatorImage != nil {
          self.avatorImage.image = avatorImage?.circleMasked
        }
      }
    }
    
    if recentChat[kCOUNTER] as! Int != 0 {
      self.messageCountLabel.text = "\(recentChat[kCOUNTER] as! Int)"
      self.messageCountBackgroundView.isHidden = false
      self.messageCountLabel.isHidden = false
    } else {
      self.messageCountBackgroundView.isHidden = true
      self.messageCountLabel.isHidden = true
    }
    
    var date: Date!
    
    if let created = recentChat[kDATE] {
      if (created as! String).count != dateLength {
        date = Date()
      } else {
        date = dateFormatter().date(from: created as! String)
      }
    } else {
      date = Date()
    }
    
    self.dateLabel.text = timeElapsed(date: date)
    
  }
  
  func configAvatorTapGesture() {
    tapGestureRecognizer.addTarget(self, action: #selector(self.avatorTap))
    avatorImage.isUserInteractionEnabled = true
    avatorImage.addGestureRecognizer(tapGestureRecognizer)
  }
  
  @objc func avatorTap() {
    delegate?.didTappedAvatorImage(indexPath: indexPath)
  }
  
}
