//
//  LoginVC.swift
//  OperrToDo
//
//  Created by Shenll_IMac on 26/02/19.
//  Copyright © 2019 STS. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginVC: UIViewController , UITextFieldDelegate , SQLiteDelegate{
    
    //MARK: - UITextField declarations
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    //MARK: - UIButton declarations
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var registerHereButton: UIButton!

    //MARK: - UIView declarations
    @IBOutlet weak var loginView: UIView!

    //MARK: - Model declarations
    var util = Util()
    var sqliteManager = SQLiteManager()

    //MARK: - View delegates
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loginView.layer.masksToBounds = true
        self.loginView.layer.cornerRadius = 20
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
    @IBAction func actionSignin(_ sender: UIButton) {
        
        // MARK: - empty fields and valid email validation
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
                Auth.auth().signIn(withEmail: email!, password: password!, completion: { (user, error) in
                    if let error = error {
                        if let errCode = AuthErrorCode(rawValue: error._code) {
                            switch errCode {
                            case .userNotFound:
                                self.util.showAlert(alert: ERROR, message: "User account not found. Try registering.")
                            case .wrongPassword :
                                self.util.showAlert(alert: ERROR, message: "Incorrect username/password combination.")
                            default:
                                self.util.showAlert(alert: ERROR, message: error.localizedDescription)
                            }
                        }
                        return
                    }
                    UserDefaults.standard.set(user!.user.uid, forKey: USER_ID)
                    self.performSeague("ToDoListingSegue")
                })
            }else{
                sqliteManager.FetchUserFromDB(tbl_name: TABLE_USER, whereField1: EMAIL, whereFieldValue1: self.emailTextField.text!, whereField2: PASSWORD, whereFieldValue2: util.stringToMD5(self.passwordTextField.text!))
            }
        }
    }
    
    @IBAction func actionRegisterHere(_ sender: UIButton) {
        self.performSeague("SignUpSegue")
    }

    // MARK: - Navigation
    func performSeague(_ segueIdentifier: String?) {
        DispatchQueue.main.async(execute: {
            self.performSegue(withIdentifier: segueIdentifier ?? "", sender: self)
        })
    }
    
    // MARK: - SQLite Delegate

    func SQLiteQueryExecutionDidSucced(queryResult: Any) {
        let UserId = (queryResult as! String)
        print("UserId = >" , UserId)
        UserDefaults.standard.set(UserId, forKey: USER_ID)
        self.performSeague("ToDoListingSegue")
    }
    
    func SQLiteQueryExecutionDidFailurewithError(errror: String) {
        self.util.showAlert(alert: ERROR, message: "Incorrect username/password combination.")
    }

}
