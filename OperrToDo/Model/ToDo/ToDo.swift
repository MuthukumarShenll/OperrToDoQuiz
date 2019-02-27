//
//  ToDo.swift
//  OperrToDo
//
//  Created by Shenll_IMac on 26/02/19.
//  Copyright © 2019 STS. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ToDo{
    
    var ref: DatabaseReference?
    var id = String()
    var userId = String()
    var toDoMsg = String()

    init(id : String , userId: String, toDoMsg: String){
        self.id = id
        self.userId = userId
        self.toDoMsg = toDoMsg
    }    
    
}
