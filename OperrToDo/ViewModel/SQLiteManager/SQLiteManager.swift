//
//  SQLiteManager.swift
//  OperrToDo
//
//  Created by STS_MACLAP on 27/02/19.
//  Copyright © 2019 STS. All rights reserved.
//

import UIKit
import SQLite3

protocol SQLiteDelegate{
    func SQLiteQueryExecutionDidSucced(queryResult:Any)
    func SQLiteQueryExecutionDidFailurewithError(errror:String)
}

class SQLiteManager: NSObject {
    
    var dbSQLite: OpaquePointer?
    var delegate : SQLiteDelegate?
    
    //MARK: - Object declarations
    var todoList = [ToDo]()

    override init() {
        
    }
    
    //MARK:- Open DB Connection
    
    func copyFile(file : NSString)  {
        //Storing local .sqlite file to app directory.
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = URL(fileURLWithPath: path)
        let urlPath: URL? = self.applicationHiddenDocumentsDirectory(str_folder: DB_FOLDER as NSString) as URL
        let strWritablePath: String = URL(fileURLWithPath: (urlPath?.path)!).appendingPathComponent(FULL_DB_NAME).path
        let filePath = url.appendingPathComponent(file as String).path
        let fileManager = FileManager.default
        
        if (!fileManager.fileExists(atPath: filePath)) {
            let bundlePath = Bundle.main.path(forResource: file as String, ofType: ".sqlite")
            print("bundlePath", bundlePath as Any)
            do
            {
                try fileManager.copyItem(atPath: bundlePath!, toPath: strWritablePath)
            }
            catch
            {
                print(error)
            }
        }
    }
    
    func openDatabase(){
        // Gets path of my DB folder
        let urlPath: URL? = self.applicationHiddenDocumentsDirectory(str_folder: DB_FOLDER as NSString) as URL
        // Appends DB file to DB folder
        let dbFilePath: String = URL(fileURLWithPath: (urlPath?.path)!).appendingPathComponent(FULL_DB_NAME).path
        
        var db: OpaquePointer? = nil
        if sqlite3_open(dbFilePath, &db) == SQLITE_OK {
            print("Successfully opened connection to database at",dbFilePath )
            dbSQLite = db
        } else {
            print("Unable to open database. Verify that you created the directory described in the Getting Started section.")
            dbSQLite = db
        }
    }
    
    func applicationHiddenDocumentsDirectory(str_folder : NSString) -> NSURL{
        //To read Application Hidden Documents Directory
        let libraryPath:String = NSSearchPathForDirectoriesInDomains(.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        let path = libraryPath.appending(str_folder as String)
        let pathURl:NSURL =  NSURL.fileURL(withPath: path) as NSURL
        var isDirectory:ObjCBool = false
        
        if(FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)){
            print("ApplicationHiddenDocumentsDirectory",isDirectory )
            if(isDirectory).boolValue{
                return pathURl
            }else{
                NSException.raise(NSExceptionName(rawValue: "Private Documents exists, and is a file"), format: "Path: %@", arguments:getVaList([path]))
            }
        }
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
        return pathURl
    }
    
    func InsertRecordInDB(tbl_name:String, keyValueDictionary:NSDictionary)  {
        openDatabase()
        //Separating all keys and values from NSDictionary
        let keys = keyValueDictionary.allKeys as NSArray
        let values = keyValueDictionary.allValues as NSArray
        
        // Appending comma to from AllKeys string for query
        let KeysString = keys.componentsJoined(by: ",") as String
        let insertStatementStirng = "INSERT OR REPLACE INTO " + tbl_name + " (" + KeysString + ")" + " VALUES (?, ?, ?)"
        
        print("Insert Query", insertStatementStirng)
        var insertStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(dbSQLite, insertStatementStirng, -1, &insertStatement, nil) == SQLITE_OK {
            
            let value1: NSString = values.object(at: 0) as! String as NSString
            let value2: NSString = values.object(at: 1) as! String as NSString
            let value3: NSString = values.object(at: 2) as! String as NSString
            
            sqlite3_bind_text(insertStatement, 1, value1.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, value2.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, value3.utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
                FetchAllRecordFromDB(tbl_name: tbl_name)
            } else {
                print("Could not insert row.")
            }
        }
    }
    
    //MARK:- Fetch All Data from my Table
    func FetchAllRecordFromDB(tbl_name:String) {
        openDatabase()
        let queryStatementString = "SELECT * FROM " + tbl_name
        var stmt:OpaquePointer?
        
        //preparing the query
        if sqlite3_prepare(dbSQLite, queryStatementString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(dbSQLite)!)
            print("error preparing insert: \(errmsg)")
            delegate?.SQLiteQueryExecutionDidFailurewithError(errror: errmsg)
            return
        }
        
        //traversing through all the records
        while(sqlite3_step(stmt) == SQLITE_ROW){
            let id = String(cString: sqlite3_column_text(stmt, 2))
            let user_id = String(cString: sqlite3_column_text(stmt, 1))
            let todoMsg = String(cString: sqlite3_column_text(stmt, 0))
            
            //adding values to list
            
            self.todoList.append(ToDo(id : id , userId: user_id, toDoMsg: todoMsg))
        }
        delegate?.SQLiteQueryExecutionDidSucced(queryResult: self.todoList)
    }
    
    //MARK:- Fetch User from Table
    func FetchUserFromDB(tbl_name:String,whereField1:String,whereFieldValue1:String,whereField2:String,whereFieldValue2:String) {
        openDatabase()
        let FetchUserStatementStirng = "SELECT * FROM " + tbl_name + " WHERE " + whereField1 + " = " + SINGLR_QUOTES + whereFieldValue1 + SINGLR_QUOTES + " AND " + whereField2 + " = " + String(format: "'%@'", whereFieldValue2)
        print(FetchUserStatementStirng)
        var FetchUserStatement:OpaquePointer?
        
        if sqlite3_prepare(dbSQLite, FetchUserStatementStirng, -1, &FetchUserStatement, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(dbSQLite)!)
            print("error preparing insert: \(errmsg)")
            delegate?.SQLiteQueryExecutionDidFailurewithError(errror: errmsg)
            return
        }
         var id = String()
        
        //traversing through all the records
        while(sqlite3_step(FetchUserStatement) == SQLITE_ROW){
            id = String(cString: sqlite3_column_text(FetchUserStatement, 0))
        }
        delegate?.SQLiteQueryExecutionDidSucced(queryResult: id)
    }

    
    //MARK:- Delete Record from Table where condition true
    func DeleteRecordFromDB(tbl_name:String,whereField:String,whereFieldValue:String) {
        openDatabase()
        let deleteStatementStirng = "DELETE FROM " + tbl_name + " WHERE " + whereField + "=" + whereFieldValue
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(dbSQLite, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
                delegate?.SQLiteQueryExecutionDidFailurewithError(errror: "Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
            delegate?.SQLiteQueryExecutionDidFailurewithError(errror: "DELETE statement could not be prepared")
        }
    }
    
    func DeleteAllRecordFromDB(tbl_name:String) {
        openDatabase()
        let deleteStatementStirng = "DELETE FROM " + tbl_name
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(dbSQLite, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
            } else {
                print("Could not delete row.")
                delegate?.SQLiteQueryExecutionDidFailurewithError(errror: "Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
            delegate?.SQLiteQueryExecutionDidFailurewithError(errror: "DELETE statement could not be prepared")
        }
    }

    func updateTodoRecordFromDB(tbl_name:String,newTodoString: String,whereField1:String,whereFieldValue1:String, whereField2:String,whereFieldValue2:String){
        
        let updateStatementStirng = "UPDATE " + tbl_name + "SET todo = " + newTodoString + " WHERE " + whereField1 + "=" + whereFieldValue1 + " AND " + whereField2 + "=" + whereFieldValue2
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(dbSQLite, updateStatementStirng, -1, &updateStatement, nil) == SQLITE_OK {
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated row.")
            } else {
                print("Could not update row.")
                delegate?.SQLiteQueryExecutionDidFailurewithError(errror: "Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
            delegate?.SQLiteQueryExecutionDidFailurewithError(errror: "DELETE statement could not be prepared")
        }
    }
    
}
