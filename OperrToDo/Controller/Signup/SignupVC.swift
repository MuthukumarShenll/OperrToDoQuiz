//
//  SignupVC.swift
//  OperrToDo
//
//  Created by Shenll_IMac on 26/02/19.
//  Copyright © 2019 STS. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignupVC: UIViewController , UITextFieldDelegate , SQLiteDelegate {

    //MARK: - UITextField declarations
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    //MARK: - UIButton declarations
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loginHereButton: UIButton!

    //MARK: - UIView declarations
    @IBOutlet weak var signUpView: UIView!

    //MARK: - Model declarations
    var util: Util = Util()
    let sqliteManager = SQLiteManager()
    
    //MARK: - View delegates
    override func viewDidLoad() {
        super.viewDidLoad()
        self.signUpView.layer.masksToBounds = true
        self.signUpView.layer.cornerRadius = 20
        sqliteManager.delegate = self
    }
    
    //MARK: -  UITextField Delegates
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - UIButton Actions
    @IBAction func actionSignUp(_ sender: UIButton) {
        if((self.emailTextField.text?.count)! == 0 ){
            self.emailTextField.becomeFirstResponder()
            util.showAlert(alert: ERROR, message: NO_EMAIL_ALERT)
        }else if(util.validEmailAddress(testStr: self.emailTextField.text!) == false ){
            self.emailTextField.becomeFirstResponder()
            util.showAlert(alert: ERROR, message: VALID_EMAIL_ALERT )
        }else if((self.passwordTextField.text?.count)! == 0 || (self.passwordTextField.text!.trimmingCharacters(in: .whitespaces).count) == 0){
            self.passwordTextField.becomeFirstResponder()
            util.showAlert(alert: ERROR, message: NO_PASSWORD_ALERT)
        }else{
            if(util.IsNetworkConnected()){
                let email = self.emailTextField.text
                let password = self.passwordTextField.text
                Auth.auth().createUser(withEmail: email!, password: password!, completion: { (user, error) in
                    if let error = error {
                        if let errCode = AuthErrorCode(rawValue: error._code) {
                            switch errCode {
                            case .invalidEmail:
                                self.util.showAlert(alert: ERROR, message: "Enter a valid email.")
                            case .emailAlreadyInUse :
                                self.util.showAlert(alert: ERROR, message: "Email already in use.")
                            default:
                                self.util.showAlert(alert: ERROR, message: error.localizedDescription)
                            }
                        }
                        return
                    }
                    UserDefaults.standard.set(user!.user.uid, forKey: USER_ID)
                    DispatchQueue.main.async(execute: {
                        let dic = [ID : user!.user.uid ,
                                   EMAIL : self.emailTextField.text!,
                                   PASSWORD : self.util.stringToMD5(self.passwordTextField.text!) ]
                        
                        self.sqliteManager.InsertRecordInDB(tbl_name: TABLE_USER, keyValueDictionary: dic as NSDictionary)
                    })
                })
            }else{
                util.showAlert(alert: ERROR, message: NO_INTERNET_ALERT)
            }
        }
    }

    @IBAction func actionLoginHere(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    // MARK: - Navigation
    func performSeague(_ segueIdentifier: String?) {
        DispatchQueue.main.async(execute: {
            self.performSegue(withIdentifier: segueIdentifier ?? "", sender: self)
        })
    }
    
    // MARK: - SQLite Delegate

    func SQLiteQueryExecutionDidSucced(queryResult: Any) {
        self.performSeague("ToDoListingSegue")
    }
    
    func SQLiteQueryExecutionDidFailurewithError(errror: String) {
        print(errror)
    }

}
