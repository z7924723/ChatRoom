//
//  ChatsViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/22.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ChatsViewController: UIViewController {
  
  // MARK: - Porperties
  @IBOutlet weak var tableView: UITableView!
  
  var recentChats: [NSDictionary] = []
  var filteredChats: [NSDictionary] = []
  var recentListener: ListenerRegistration!
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    loadRecentChats()
  }
  
  // MARK: - Actions
  @IBAction func createNewChat(_ sender: Any) {
    let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UsersTableView") as! UsersTableViewController
    
    self.navigationController?.pushViewController(userVC, animated: true)
  }
  
  // MARK: - Helper
  func loadRecentChats() {
    
    recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (snapshot, error) in
      
      guard let snapshot = snapshot else { return }
      
      if !snapshot.isEmpty {
        let sorted = (dictionaryFromSnapshots(snapshots: snapshot.documents) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
        
        for recent in sorted {
          if (recent[kLASTMESSAGE] as! String) != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
            self.recentChats.append(recent)
          }
        }
        
        self.tableView.reloadData()
      }
      
    })
  }
  
}

extension ChatsViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    return recentChats.count
    
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "RecentChatTableViewCell", for: indexPath) as! RecentChatsTableViewCell
    let recent = recentChats[indexPath.row]
    
    cell.generateCellWith(recentChat: recent, indexPath: indexPath)
    
    return cell
    
  }
  
}

extension ChatsViewController: UITableViewDelegate {
  
}
