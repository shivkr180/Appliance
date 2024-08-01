//
//  Rooms.swift
//  HomeAuto
//
//  Created by shiv on 10/29/20.
//  Copyright © 2020 shiv. All rights reserved.
//

import UIKit

class Rooms: NSObject {
 
    var rooms:[Appliance] = []
    
    init(jsonDictionary : [String : Any]) {
        if let result = jsonDictionary["DEVICES"] as? NSArray {
        for dataInfo in result {
            let actValues = Appliance(jsonDictionary: dataInfo as! NSDictionary)
            rooms.append(actValues)
            
        }
        } else {
            let actValues = Appliance(jsonDictionary: jsonDictionary as NSDictionary)
            rooms.append(actValues)
        }
    }
    
    
}
class Appliance:NSObject {
    var applianceId:Int?
    var applinceType:Int?
    var isStatusOn:Bool?
    
     init(jsonDictionary:NSDictionary) {
        if let applianceId_ = jsonDictionary["applianceId"] as? Int {
            self.applianceId = applianceId_
        }
        if let applinceType_ = jsonDictionary["applianceType"] as? Int {
            self.applinceType = applinceType_
        }
        if let isStatusOn_ = jsonDictionary["isStatusOn"] as? Bool {
            self.isStatusOn = isStatusOn_
        }
    }
}
