//
//  ProfileTableViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/23.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit

class ProfileTableViewController: UITableViewController {
  
  // MARK: - Porperties
  @IBOutlet weak var avatorImage: UIImageView!
  @IBOutlet weak var fullNameLabel: UILabel!
  @IBOutlet weak var phoneNumberLabel: UILabel!
  @IBOutlet weak var callButton: UIButton!
  @IBOutlet weak var messageButton: UIButton!
  @IBOutlet weak var blockUserButton: UIButton!
  
  var user: FUser?
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureUI()
  }
  
  // MARK: - Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return ""
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return UIView()
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    
    if section == 0 {
      return 0
    }
    
    return 30
    
  }
  
  // MARK: - Actions
  @IBAction func callButtonPressed(_ sender: UIButton) {
  }
  
  @IBAction func messageButtonPressed(_ sender: UIButton) {
  }
  
  @IBAction func blockUserButtonPressed(_ sender: UIButton) {
    
    var currentBlockIds = FUser.currentUser()!.blockedUsers
    
    if currentBlockIds.contains(user!.objectId) {
      currentBlockIds.remove(at: currentBlockIds.index(of: user!.objectId)!)
    } else {
      currentBlockIds.append(user!.objectId)
    }
    
    updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID : currentBlockIds]) { (error) in
      
      if error != nil {
        print("Block user error: \(error?.localizedDescription)")
        return
      }
      
      self.updateBlockStatus()
      
    }
    
  }
  
  // MARK: - Helper
  private func configureUI() {
    if user != nil {
      self.title = "Profile"
      fullNameLabel.text = user!.fullname
      phoneNumberLabel.text = user!.phoneNumber
      
      updateBlockStatus()
      
      imageFromData(pictureData: user!.avatar) { (avatorImage) in
        if avatorImage != nil {
          self.avatorImage.image = avatorImage!.circleMasked
        }
      }
    }
  }
  
  func updateBlockStatus() {
    
    if user!.objectId != FUser.currentId() {
      blockUserButton.isHidden = false
      messageButton.isHidden = false
      callButton.isHidden = false
    } else {
      blockUserButton.isHidden = true
      messageButton.isHidden = true
      callButton.isHidden = true
    }
    
    if FUser.currentUser()!.blockedUsers.contains(user!.objectId) {
      blockUserButton.setTitle("Unblock User", for: .normal)
    } else {
      blockUserButton.setTitle("Block User", for: .normal)
    }
    
  }
  
}
