//
//  FirebaseDelegates.swift
//  OperrToDo
//
//  Created by M K on 27/02/19.
//  Copyright © 2019 STS. All rights reserved.
//

import Foundation
import Firebase

protocol firebaseCallDelegate{
    func firebaseSucceedResponseClass(responseobj:Any)
    func firebaseFailurewithError(errror:String)
}

class FirebaseDelegates: NSObject {

    //MARK: - firebaseCallDelegate declarations
    var delegate : firebaseCallDelegate?

    //MARK: - DatabaseReference declarations
    var ref: DatabaseReference!
    
    //MARK: - Object declarations
    var todoList = [ToDo]()
    
    var sqliteManager = SQLiteManager()

    
    //MARK: - Get all todo for the logged user
    func getData(UserId : String){
        self.ref = Database.database().reference()
        self.ref.child("ToDo").queryOrdered(byChild: USER_ID).queryEqual(toValue : UserId).observe(.value, with:{ (snapshot) in
            //if the reference have some values
            
            //clearing the list
            self.todoList.removeAll()
            self.sqliteManager.DeleteAllRecordFromDB(tbl_name: TABLE_TODO)
            if snapshot.childrenCount > 0 {
                //iterating through all the values
                for todo in snapshot.children.allObjects as! [DataSnapshot] {
                    //getting values
                    let todoObject = todo.value as? [String: AnyObject]
                    let id  = todoObject![ID]
                    let userID  = todoObject![USER_ID]
                    let toDoMsg  = todoObject![TODO]
                    
                    //creating object with model and fetched values
                    //appending it to list
                    self.todoList.append(ToDo(id : (id as! String) , userId: (userID as! String), toDoMsg: (toDoMsg as! String)))
                    let dic = [ID : id ,
                               USER_ID : userID,
                               TODO : toDoMsg]
                    self.sqliteManager.InsertRecordInDB(tbl_name: TABLE_TODO, keyValueDictionary: dic as NSDictionary)
                }
                
                //Last inserted data should be shown first
                self.todoList = self.todoList.reversed()
            }
            //Transferring the success response to the respective viewcontroller called
            self.delegate?.firebaseSucceedResponseClass(responseobj: self.todoList)

        })
    }
    
    //MARK: - Adding new todo for the logged user

    func insertData( todoDict : NSDictionary){
        
        self.ref = Database.database().reference()
        
        // getting the generated key
        let key = ref.childByAutoId().key
        let userId = todoDict.value(forKey: USER_ID)
        let msg = todoDict.value(forKey: TODO)
        
        //creating Todo with the new given values
        let DictToDo = [ID : key , USER_ID : userId ,TODO : msg]
        
        //adding the todo inside the generated unique key
        self.ref.child("ToDo").child(key!).setValue(DictToDo)
        self.delegate?.firebaseSucceedResponseClass(responseobj: "Success")
    }
    
    //MARK: - Update new message into selected todo

    func updateData(todoDict : NSDictionary){
        self.ref = Database.database().reference()
        //updating the todo using the particular generared unique key of the todo
        self.ref.child("ToDo").child((todoDict.object(forKey: ID)) as! String).setValue(todoDict)
        print(todoDict)
        sqliteManager.updateTodoRecordFromDB(tbl_name: TABLE_TODO, newTodoString: (todoDict.object(forKey: TODO) as! String), whereField1: ID, whereFieldValue1: ((todoDict.object(forKey: ID)as! String)), whereField2: USER_ID, whereFieldValue2: ((todoDict.object(forKey: USER_ID)as! String)))
        self.delegate?.firebaseSucceedResponseClass(responseobj: "Success")
    }

    //MARK: - Delete selected todo from logged user

    func DeleteData(key : String , UserId : String){
        self.ref = Database.database().reference()
        //deleting the todo with the particular generared unique key
        self.ref.child("ToDo").child(key).removeValue()
        self.getData(UserId: UserId)
    }
    
}
