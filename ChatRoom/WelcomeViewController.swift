//
//  ViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/18.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
  
  // MARK: - Porperties
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var pwdTextField: UITextField!
  @IBOutlet weak var repeadPwdTextField: UITextField!
  
  // Mark: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  // Mark: - Actions
  @IBAction func login(_ sender: UIButton) {
  }
  
  @IBAction func register(_ sender: UIButton) {
  }
  
  @IBAction func backgroundTap(_ sender: Any) {
  }
}

