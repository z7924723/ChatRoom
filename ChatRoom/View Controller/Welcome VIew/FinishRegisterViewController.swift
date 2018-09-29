//
//  FinishRegisterViewController.swift
//  ChatRoom
//
//  Created by PinguMac on 2018/9/20.
//  Copyright © 2018年 PinguMac. All rights reserved.
//

import UIKit
import ProgressHUD

class FinishRegisterViewController: UIViewController {
  
  // MARK: - Porperties
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var surnameTextField: UITextField!
  @IBOutlet weak var countryTextField: UITextField!
  @IBOutlet weak var cityTextField: UITextField!
  @IBOutlet weak var phoneTextFiled: UITextField!
  @IBOutlet weak var avatarImageView: UIImageView!
  
  var email: String!
  var password: String!
  var avatorImage: UIImage?
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  // MARK: - Actions
  @IBAction func cancelButton(_ sender: UIButton) {
    disMissKeyboard()
    cleanTextFields()
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func doneButton(_ sender: UIButton) {
    disMissKeyboard()
    ProgressHUD.show("Register ID...")
    
    if nameTextField.text != "" && surnameTextField.text != "" && countryTextField.text != "" && cityTextField.text != "" && phoneTextFiled.text != "" {
      
      FUser.registerUserWith(email: email, password: password, firstName: nameTextField.text!, lastName: surnameTextField.text!) { [weak self] (error) in
        if error != nil {
          ProgressHUD.showError(error!.localizedDescription)
          print("Error: \(error!.localizedDescription)")
          return
        }
        
        ProgressHUD.dismiss()
        self!.registerUser()
      }
    } else {
      ProgressHUD.showError("All fields are required!")
    }
  }
  
  // MARK: - Helper
  func registerUser() {
    let fullName = nameTextField.text! + " " + surnameTextField.text!
    var tempDictionary: Dictionary = [kFIRSTNAME: nameTextField.text!,
                                      kLASTNAME: surnameTextField.text!,
                                      kFULLNAME: fullName,
                                      kCOUNTRY: countryTextField.text!,
                                      kCITY: cityTextField.text!,
                                      kPHONE: phoneTextFiled.text!] as [String: Any]
    
    if avatorImage == nil {
      imageFromInitials(firstName: nameTextField.text!, lastName: surnameTextField.text!) {
        [weak self] (initAvatorImage) in
        let avatorImage = initAvatorImage.jpegData(compressionQuality: 0.7)
        let avator = avatorImage!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        tempDictionary[kAVATAR] = avator
        self!.finishRegisteration(withValue: tempDictionary)
      }
    } else {
      let avatorData = avatorImage!.jpegData(compressionQuality: 0.7)
      let avator = avatorData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
      
      tempDictionary[kAVATAR] = avator
      self.finishRegisteration(withValue: tempDictionary)
    }
  }
  
  func finishRegisteration(withValue: [String: Any]) {
    updateCurrentUserInFirestore(withValues: withValue) { (error) in
      if error != nil {
        DispatchQueue.main.async {
          ProgressHUD.showError(error!.localizedDescription)
          print("Register error: \(error!.localizedDescription)")
        }
        
        return
      }
      
      ProgressHUD.dismiss()
      self.goToChatRoom()
    }
  }
  
  func goToChatRoom() {
    disMissKeyboard()
    cleanTextFields()
    
    let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainApplication") as! UITabBarController
   
    self.present(mainView, animated: true, completion: nil)
  }
  
  func disMissKeyboard() {
    self.view.endEditing(true)
  }
  
  func cleanTextFields() {
    nameTextField.text = ""
    surnameTextField.text = ""
    countryTextField.text = ""
    cityTextField.text = ""
    phoneTextFiled.text = ""
  }
}
