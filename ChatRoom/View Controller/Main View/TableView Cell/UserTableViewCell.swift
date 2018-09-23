//
//  UserTableViewCell.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/21.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
  
  // MARK: - Porperties
  @IBOutlet weak var avatorImage: UIImageView!
  @IBOutlet weak var fullNameLabel: UILabel!
  
  var indexPath: IndexPath!
  
  let tapGestureRecognizer = UITapGestureRecognizer()
  
  // MARK: - Initializers
  override func awakeFromNib() {
    super.awakeFromNib()
    
    tapGestureRecognizer.addTarget(self, action: #selector(self.avatorTap))
    avatorImage.isUserInteractionEnabled = true
    avatorImage.addGestureRecognizer(tapGestureRecognizer)
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  func generateCellWith(fuser: FUser, indexPath: IndexPath) {
    self.indexPath = indexPath
    self.fullNameLabel.text = fuser.fullname
    
    if fuser.avatar != "" {
      imageFromData(pictureData: fuser.avatar) { (avatorImage) in
        if avatorImage != nil {
          self.avatorImage.image = avatorImage!.circleMasked
        }
      }
    }
  }
  
  @objc func avatorTap() {
    print("avator tap at \(indexPath)")
  }
}
