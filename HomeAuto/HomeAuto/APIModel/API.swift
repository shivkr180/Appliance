//
//  API.swift
//  HomeAuto
//
//  Created by shiv on 10/30/20.
//  Copyright © 2020 shiv. All rights reserved.
//

import UIKit

class API: NSObject {

    //Common method
    private class func loadJsonFromLocalFile(fileName : String,
                               callback :(_ result : AnyObject) ->Void) {
        var error : NSError?
        // Load Local Json File
        do {
            let filePath = Bundle.main.path(forResource: fileName, ofType: "json")
            let text = try String(contentsOfFile: filePath!, encoding: String.Encoding.utf8)
            
            // String to NSData
            let data = text.data(using: String.Encoding.utf8)
            
            let json : NSDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            callback(json)
            
        } catch let catchError as NSError {
            error = NSError(domain: "JSONNeverDie.JSONParseError", code: catchError.code, userInfo: catchError.userInfo)
            callback(error!)
        }
        
    }
    class func getDeviceList (success :(_ transactionModel: Rooms) -> Void, failure : (_ error : NSError ) -> Void) {
        
        let jsonFile = "ItemList"
        loadJsonFromLocalFile(fileName: jsonFile) { (result) -> Void in
            if let json = result as? NSDictionary {
                
                let responseObject = Rooms(jsonDictionary: json as! [String : Any])
                success(responseObject)
                return
            }else {
                failure(result as! NSError)
            }
        }
    }

}
