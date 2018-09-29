//
//  UserTableViewCell.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/21.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit

protocol UserTableViewCellDelegate {
  func didTappedAvatorImage(indexPath: IndexPath)
}

class UserTableViewCell: UITableViewCell {
  
  // MARK: - Porperties
  @IBOutlet weak var avatorImage: UIImageView!
  @IBOutlet weak var fullNameLabel: UILabel!
  
  var indexPath: IndexPath!
  var delegate: UserTableViewCellDelegate?
  
  let tapGestureRecognizer = UITapGestureRecognizer()
  
  // MARK: - Initializers
  override func awakeFromNib() {
    super.awakeFromNib()
    
    configAvatorTapGesture()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  func generateCellWith(fuser: FUser, indexPath: IndexPath) {
    self.indexPath = indexPath
    self.fullNameLabel.text = fuser.fullname
    
    if fuser.avatar != "" {
      imageFromData(pictureData: fuser.avatar) { [weak self] (avatorImage) in
        if avatorImage != nil {
          self!.avatorImage.image = avatorImage!.circleMasked
        }
      }
    }
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
