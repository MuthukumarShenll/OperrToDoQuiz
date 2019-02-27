//
//  ToDoAddEditVC.swift
//  OperrToDo
//
//  Created by Shenll_IMac on 26/02/19.
//  Copyright © 2019 STS. All rights reserved.
//

import UIKit
import Firebase

class ToDoAddEditVC: UIViewController , UITextFieldDelegate ,firebaseCallDelegate {

    //MARK: - UIView declarations
    @IBOutlet weak var toDoAddView : UIView!
    
    //MARK: - UITextField declarations
    @IBOutlet weak var toDoTextField: UITextField!

    //MARK: - UIButton declarations
    @IBOutlet weak var saveButton : UIButton!
    @IBOutlet weak var cancelButton : UIButton!
    
    //MARK: - String declarations
    var strUserId = String()
    var strSelectedKey = String()
    var strAddorEdit = String()

    //MARK: - NSMutableDictionary declarations
    var selectedObj = NSMutableDictionary()

    //MARK: - Object declarations
    var firebaseDelegate = FirebaseDelegates()
  
    //MARK: - Model declarations
    var util: Util = Util()

    //MARK: - UIView Delegates
    override func viewDidLoad() {
        firebaseDelegate.delegate = self

        self.toDoAddView.layer.masksToBounds = true
        self.toDoAddView.layer.cornerRadius = 10.0
        if(self.strAddorEdit == "add"){
            self.saveButton.setTitle("Save", for: .normal)
        }else{
            self.toDoTextField.text = (self.selectedObj.value(forKey: TODO_MSG) as! String)
            self.strSelectedKey = (self.selectedObj.value(forKey: ID) as! String)
            self.saveButton.setTitle("Update", for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.strUserId = UserDefaults.standard.value(forKey: USER_ID) as! String
    }
    
    //MARK: -  UITextField Delegates
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: -  Update ToDo
    func updateToDoList(){
        let ToDoDict = [ID : self.strSelectedKey , USER_ID : self.strUserId, TODO : self.toDoTextField.text!]
        self.firebaseDelegate.updateData(todoDict: (ToDoDict as NSDictionary))
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - UIButton actions

    @IBAction func actionSave(_ sender: UIButton) {
        if(util.IsNetworkConnected()){
            if(self.strAddorEdit == "add"){
                let ToDoDict = [USER_ID : self.strUserId,TODO : self.toDoTextField.text!]
                self.firebaseDelegate.insertData(todoDict: (ToDoDict as NSDictionary))
            }else{
                self.updateToDoList()
            }
        }else{
            util.showAlert(alert: ERROR, message: NO_INTERNET_ALERT)
        }
    }
    
    @IBAction func actionCancel(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - firebaseCall Delegate
    func firebaseSucceedResponseClass(responseobj: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func firebaseFailurewithError(errror: String) {
        print(errror)
    }

}
