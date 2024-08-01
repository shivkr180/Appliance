//
//  SharedInstance.swift
//  HomeAuto
//
//  Created by shiv on 10/31/20.
//  Copyright © 2020 shiv. All rights reserved.
//

import UIKit

class SharedInstance: NSObject {
  static let  ObjOfSharedInstance = SharedInstance ()
  var rooms:Rooms?
  var appliance:[Appliance] = []
}
