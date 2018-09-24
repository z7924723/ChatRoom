//
//  ViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/18.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit
import ProgressHUD

class WelcomeViewController: UIViewController {
  
  // MARK: - Porperties
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var pwdTextField: UITextField!
  @IBOutlet weak var repeadPwdTextField: UITextField!
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "welcomeToFinishReg" {
      let vc = segue.destination as! FinishRegisterViewController
      vc.email = emailTextField.text
      vc.password = pwdTextField.text
    }
  }
  
  // MARK: - Actions
  @IBAction func login(_ sender: UIButton) {
    disMissKeyboard()
    
    if emailTextField.text != "" && pwdTextField.text != "" {
      loginUser()
    } else {
      ProgressHUD.showError("Email and password are missing.")
    }
  }
  
  @IBAction func register(_ sender: UIButton) {
    disMissKeyboard()
    
    if emailTextField.text != "" && pwdTextField.text != "" && repeadPwdTextField.text != "" {
      if pwdTextField.text == repeadPwdTextField.text {
        registerUser()
      } else {
        ProgressHUD.showError("Password don't match.")
      }
    } else {
      ProgressHUD.showError("All fields are require!")
    }
  }
  
  @IBAction func backgroundTap(_ sender: Any) {
    disMissKeyboard()
  }
  
  // MARK: - Helper
  func loginUser() {
    ProgressHUD.show("Login...")
    
    FUser.loginUserWith(email: emailTextField.text!, password: pwdTextField.text!) { (error) in
      if error != nil {
        ProgressHUD.show(error?.localizedDescription)
        return
      }
      ProgressHUD.dismiss()
      self.goToChatRoom()
    }
  }
  
  func registerUser() {
    performSegue(withIdentifier: "welcomeToFinishReg", sender: self)
//    cleanTextFields()
    disMissKeyboard()
  }
  
  func disMissKeyboard() {
    self.view.endEditing(true)
  }
  
  func cleanTextFields() {
    emailTextField.text = ""
    pwdTextField.text = ""
    repeadPwdTextField.text = ""
  }
  
  func goToChatRoom() {
    cleanTextFields()
    disMissKeyboard()
    
    NotificationCenter.default.post(name: .USER_DID_LOGIN_NOTIFICATION, object: nil, userInfo: [kUSERID: FUser.currentId()])
    
    let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainApplication") as! UITabBarController
    
    self.present(mainView, animated: true, completion: nil)
  }
}

