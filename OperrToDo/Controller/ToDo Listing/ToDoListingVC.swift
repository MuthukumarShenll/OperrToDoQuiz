//
//  ToDoListingVC.swift
//  OperrToDo
//
//  Created by Shenll_IMac on 26/02/19.
//  Copyright © 2019 STS. All rights reserved.
//

import UIKit
import Firebase

class ToDoListingVC: UIViewController , UITableViewDelegate, UITableViewDataSource , UITextFieldDelegate , firebaseCallDelegate , SQLiteDelegate{
    
    //MARK: - UITableView declarations
    @IBOutlet weak var toDoListTable : UITableView!
    
    //MARK: - UIButton declarations
    @IBOutlet weak var addButton : UIButton!

    //MARK: - UILabel declarations
    @IBOutlet weak var noRecordLabel: UILabel!
    
    //MARK: - NSMutableDictionary declarations
    var selectedObj = NSMutableDictionary()

    //MARK: - String declarations
    var strUserId = String()
    var strSelectedKey = String()
    var strAddorEdit = String()
    var strFrom = String()

    //MARK: - DatabaseReference declarations
    var ref: DatabaseReference!

    //MARK: - Object declarations
    var todoList = [ToDo]()
    var firebaseDelegate = FirebaseDelegates()
    var sqliteManager = SQLiteManager()

    //MARK: - Model declarations
    var util: Util = Util()

    //MARK: - UIView Delegates
    override func viewDidLoad() {
        firebaseDelegate.delegate = self
        sqliteManager.delegate = self

        self.toDoListTable.rowHeight = UITableViewAutomaticDimension
        self.toDoListTable.estimatedRowHeight = 80.0
        self.addButton.layer.masksToBounds = true
        self.addButton.layer.cornerRadius = self.addButton.frame.width / 2
        
        self.ref = Database.database().reference()
        self.strUserId = UserDefaults.standard.value(forKey: USER_ID) as! String
        
        self.ref.child("ToDo").observe(.childChanged, with: { (snapshot) in
            self.retriveData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(util.IsNetworkConnected()){
            self.retriveData()
        }else{
           sqliteManager.FetchAllRecordFromDB(tbl_name: TABLE_TODO)
        }
    }
    
    //MARK: - Fetch data's currently logged user.

    func retriveData(){
        self.firebaseDelegate.getData(UserId: self.strUserId)        
    }
    
    //MARK: - UITableView Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.todoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoListingTVCell", for: indexPath) as! ToDoListingTVCell
        
        //getting the todo of selected position
        let todoObj = self.todoList[indexPath.row]
        
        //adding values to labels
        cell.toDoLabel.text = todoObj.toDoMsg

        //Assigning action to edit Button
        cell.editButton.tag = indexPath.row
        cell.editButton.addTarget(self, action: #selector(ToDoListingVC.actionEdit), for: UIControlEvents.touchUpInside)

        //Assigning action to delete Button
        cell.deleteButton.tag = indexPath.row
        cell.deleteButton.addTarget(self, action: #selector(ToDoListingVC.actionDelete), for: UIControlEvents.touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    //MARK: - UIButton action

    @IBAction func actionAdd(_ sender: UIButton) {
        if(util.IsNetworkConnected()){
            self.strAddorEdit = "add"
            self.performSeague("toDoAddOrEditSegue")
        }else{
            util.showAlert(alert: ERROR, message: NO_INTERNET_ALERT)
        }
    }
    
    @IBAction func actionEdit(_ sender: UIButton) {
        if(util.IsNetworkConnected()){
            self.strAddorEdit = "edit"
            let todoObj = self.todoList[sender.tag]
            self.selectedObj[ID] = todoObj.id
            self.selectedObj[TODO_MSG] = todoObj.toDoMsg
            self.performSeague("toDoAddOrEditSegue")
        }else{
            util.showAlert(alert: ERROR, message: NO_INTERNET_ALERT)
        }
    }
    
    @IBAction func actionDelete(_ sender: UIButton) {
        if(util.IsNetworkConnected()){
            let todoObj = self.todoList[sender.tag]
            self.strSelectedKey = todoObj.id
            self.firebaseDelegate.DeleteData(key: self.strSelectedKey, UserId: self.strUserId)
        }else{
            util.showAlert(alert: ERROR, message: NO_INTERNET_ALERT)
        }
    }
    
    @IBAction func actionLogout() {
        do {
            try Auth.auth().signOut()
            self.performSeague("loginSegue")
        } catch let error {
            assertionFailure("Error signing out: \(error)")
        }
    }

    // MARK: - Navigation
    func performSeague(_ segueIdentifier: String?) {
        DispatchQueue.main.async(execute: {
            self.performSegue(withIdentifier: segueIdentifier ?? "", sender: self)
        })
    }
    
    // MARK: - DataPassing
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toDoAddOrEditSegue"){
            let toDoAddEditVC = segue.destination as! ToDoAddEditVC
            toDoAddEditVC.selectedObj = self.selectedObj
            toDoAddEditVC.strAddorEdit = self.strAddorEdit
        }
    }

    // MARK: - firebaseCall Delegate
    func firebaseSucceedResponseClass(responseobj: Any) {
            self.todoList = responseobj as! [ToDo]
            self.toDoListTable.reloadData()
            if(self.todoList.count > 0){
                self.noRecordLabel.isHidden = true
                self.toDoListTable.isHidden = false
            }else{
                self.noRecordLabel.isHidden = false
                self.toDoListTable.isHidden = true
            }
    }
    

    func firebaseFailurewithError(errror: String) {
        print(errror)
    }

    // MARK: -  SQLite Delegates

    func SQLiteQueryExecutionDidSucced(queryResult: Any) {
        self.todoList = queryResult as! [ToDo]
        self.toDoListTable.reloadData()
        if(self.todoList.count > 0){
            self.noRecordLabel.isHidden = true
            self.toDoListTable.isHidden = false
        }else{
            self.noRecordLabel.isHidden = false
            self.toDoListTable.isHidden = true
        }
    }
    
    func SQLiteQueryExecutionDidFailurewithError(errror: String) {
        print(errror)
        self.toDoListTable.reloadData()
        self.noRecordLabel.isHidden = false
        self.toDoListTable.isHidden = true

    }

}
