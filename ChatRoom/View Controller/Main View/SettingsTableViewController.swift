//
//  SettingsTableViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/20.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
  
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return 3
  }
  
  // MARk: - Actions
  @IBAction func logOutButton(_ sender: UIButton) {
    FUser.logOutCurrentUser { (success) in
      if success {
        self.showLoginView()
      }
    }
  }
  
  func showLoginView() {
    let welcomeView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Welcome")
    
    self.present(welcomeView, animated: true, completion: nil)
  }
  
}
