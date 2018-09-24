//
//  UserTableViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/22.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class UsersTableViewController: UITableViewController {

  // MARK: - Porperties
  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var filterSegment: UISegmentedControl!
  
  var allUsers: [FUser] = []
  var filterUsers: [FUser] = []
  var allUsersGroupped = NSDictionary() as! [String: [FUser]]
  var sectionTitleList: [String] = []
  
  let searchController = UISearchController(searchResultsController: nil)
  
  private enum segmentValue {
    static let city = 0
    static let country = 1
    static let all = 2
  }
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureView()
    configureSearchController()
    
    loadUser(filter: kCITY)
  }
  
  // MARK: - Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    
    if searchController.isActive && searchController.searchBar.text != "" {
      return 1
    } else {
      return allUsersGroupped.count
    }
  
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    if searchController.isActive && searchController.searchBar.text != "" {
      return filterUsers.count
    } else {
      let sectionTitle = self.sectionTitleList[section]
      let users = self.allUsersGroupped[sectionTitle]
      
      return users!.count
    }
    
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as! UserTableViewCell
    
    var user: FUser
    
    if searchController.isActive && searchController.searchBar.text != "" {
      user = filterUsers[indexPath.row]
    } else {
      let sectionTitle = self.sectionTitleList[indexPath.section]
      let users = self.allUsersGroupped[sectionTitle]
      
      user = users![indexPath.row]
    }
    
    cell.generateCellWith(fuser: user, indexPath: indexPath)
    cell.delegate = self
    
    return cell
    
  }
  
  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    
    if searchController.isActive && searchController.searchBar.text != "" {
      return nil
    } else {
      return self.sectionTitleList
    }
    
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    
    if searchController.isActive && searchController.searchBar.text != "" {
      return ""
    } else {
      return sectionTitleList[section]
    }
    
  }
  
  override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
    
    return index
    
  }
  
  // MARK: - Table view delegate
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    tableView.deselectRow(at: indexPath, animated: true)
    
    // Filter user from search
    var user: FUser
    
    if searchController.isActive && searchController.searchBar.text != "" {
      user = filterUsers[indexPath.row]
    } else {
      let sectionTitle = self.sectionTitleList[indexPath.section]
      let users = self.allUsersGroupped[sectionTitle]
      
      user = users![indexPath.row]
    }
    
    startPrivateChat(user1: FUser.currentUser()!, user2: user)
    
  }

  // MARK: - Actions
  @IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
    
    switch sender.selectedSegmentIndex {
    case segmentValue.city:
      loadUser(filter: kCITY)
      
    case segmentValue.country:
      loadUser(filter: kCOUNTRY)
      
    case segmentValue.all:
      loadUser(filter: "")
      
    default:
      return
    }
    
  }
  
  // MARK: - Helper
  private func configureView() {
    self.title = "Users"
    self.navigationItem.largeTitleDisplayMode = .never
  }
  
  private func configureSearchController() {
    self.navigationItem.searchController = searchController
    searchController.searchResultsUpdater = self
    searchController.dimsBackgroundDuringPresentation = false
    self.definesPresentationContext = true
  }
  
  private func loadUser(filter: String) {
    
    ProgressHUD.show()
    
    let query: Query = queryFrom(filter: filter)
    
    query.getDocuments { (snapshot, error) in
      self.allUsers = []
      self.sectionTitleList = []
      self.allUsersGroupped = [:]
      
      if error != nil {
        print("Load user query error: \(error!.localizedDescription)")
        ProgressHUD.dismiss()
        self.tableView.reloadData()
        return
      }
      
      guard let snapshot = snapshot else {
        ProgressHUD.dismiss()
        return
      }
      
      if !snapshot.isEmpty {
        for userDictionary in snapshot.documents {
          let userDictionary = userDictionary.data() as NSDictionary
          let fuser = FUser(_dictionary: userDictionary)
          
          if fuser.objectId != FUser.currentId() {
            self.allUsers.append(fuser)
          }
        }
        
        self.splitDataIntoSection()
        self.tableView.reloadData()
      }
      
      self.tableView.reloadData()
      ProgressHUD.dismiss()
    }
    
  }
  
  func queryFrom(filter: String) -> Query {
    
    var query: Query!
    
    switch filter {
    case kCITY:
      query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
      
    case kCOUNTRY:
      query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
      
    default:
      query = reference(.User).order(by: kFIRSTNAME, descending: false)
      
    }
    
    return query
  }
  
}

extension UsersTableViewController: UISearchResultsUpdating {
  
  func updateSearchResults(for searchController: UISearchController) {
    
    filterContentForSearchText(searchText: searchController.searchBar.text!)
    
  }
  
  // MARK: - Helper
  private func filterContentForSearchText(searchText: String, scope: String = "All") {
    
    filterUsers = allUsers.filter({ (user) -> Bool in
      return user.fullname.lowercased().contains(searchText.lowercased())
    })
    
    tableView.reloadData()
    
  }
  
  private func splitDataIntoSection() {
    
    var sectionTitle: String = ""
    
    for index in 0..<self.allUsers.count {
      let currentUser = self.allUsers[index]
      let firstChar = currentUser.fullname.first!
      let firstCharString = "\(firstChar)"
      
      if firstCharString != sectionTitle {
        sectionTitle = firstCharString
        self.allUsersGroupped[sectionTitle] = []
        self.sectionTitleList.append(sectionTitle)
      }
      
      self.allUsersGroupped[firstCharString]?.append(currentUser)
    }
    
  }
  
}

extension UsersTableViewController: UserTableViewCellDelegate {
  
  func didTappedAvatorImage(indexPath: IndexPath) {
    let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileTableView") as! ProfileTableViewController
    
    var user: FUser
    
    if searchController.isActive && searchController.searchBar.text != "" {
      user = filterUsers[indexPath.row]
    } else {
      let sectionTitle = self.sectionTitleList[indexPath.section]
      let users = self.allUsersGroupped[sectionTitle]
      
      user = users![indexPath.row]
    }
    
    profileVC.user = user
    self.navigationController?.pushViewController(profileVC, animated: true)
  }
  
}
