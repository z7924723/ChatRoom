//
//  ChatsViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/22.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit

class ChatsViewController: UIViewController {
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  // MARk: - Actions
  @IBAction func createNewChat(_ sender: Any) {
    let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UsersTableView") as! UsersTableViewController
    
    self.navigationController?.pushViewController(userVC, animated: true)
  }
  
}
