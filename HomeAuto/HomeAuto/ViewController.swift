//
//  ViewController.swift
//  HomeAuto
//
//  Created by shiv on 10/27/20.
//  Copyright © 2020 shiv. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var localLabel: UILabel!
    @IBOutlet weak var RemoteLabel: UILabel!
//    var appliance:[Appliance] = []
    let sharedInstance =  SharedInstance.ObjOfSharedInstance
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(connectionCallback), name: NSNotification.Name(rawValue: "MQQTConnectionCallback"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(disConnectionCallback), name: NSNotification.Name(rawValue: "MQQTDisconnectionCallback"), object: nil)
        
        let shareInstanceOfMQTTManager = MQTTManager.mqttManager
        shareInstanceOfMQTTManager.connectToMQTT()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollectionView), name: NSNotification.Name(rawValue: "ApplianceValueUpdated"), object: nil)
        
        API.getDeviceList(success: {
            (roomModel) -> Void in
            DispatchQueue.main.async {
                self.sharedInstance.appliance = roomModel.rooms
//                self.appliance = roomModel.rooms
                self.collectionView.reloadData()
                
            }
        }){( error ) -> Void in }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "MQQTConnectionCallback"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "MQQTDisconnectionCallback"), object: nil)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.view.setNeedsLayout()
        collectionView.collectionViewLayout.invalidateLayout()
        getAllDeviceStatus()
        
        
    }
    @objc func reloadCollectionView() {
        DispatchQueue.main.async {
            self.reloadWIthData()
        }
    }
    @objc func reloadWIthData()  {
        self.collectionView.reloadData()
    }
    func sendCommandToDevice(index:Int) {
            let applianceModel = self.sharedInstance.appliance[index]
            sendToggleComandToDevice(applianceModel: applianceModel)
           
            
        }
    func sendToggleComandToDevice(applianceModel:Appliance,_ command:Int = 3) {
        let jsonObject: NSMutableDictionary = NSMutableDictionary()
        jsonObject.setValue(1, forKey: "applianceType")
        jsonObject.setValue(applianceModel.applianceId, forKey: "applianceId")
        jsonObject.setValue(applianceModel.applinceType, forKey: "type")
        if let status = applianceModel.isStatusOn {
        jsonObject.setValue(!status, forKey: "isStatusOn")
        }
        //isStatusOn
        let shareInstanceOfMQTTManager = MQTTManager.mqttManager
        MQTTManager.mqttManager.isAllAppliance = false
        shareInstanceOfMQTTManager.publishToMQTT(jsonObject: jsonObject)
    }
    
    func getAllDeviceStatus() {
        let jsonObject: NSMutableDictionary = NSMutableDictionary()
        jsonObject.setValue(1, forKey: "applianceType")
        jsonObject.setValue(1, forKey: "command")
        jsonObject.setValue([1], forKey: "responseNodeList")
        let shareInstanceOfMQTTManager = MQTTManager.mqttManager
        shareInstanceOfMQTTManager.publishToMQTT(jsonObject: jsonObject)
    }
    
    @IBAction func localBtnAction(_ sender: Any) {
        userDefaults.set(false, forKey: Constants.ipAddressActiveKey)
    }
    @IBAction func remoteBtnAction(_ sender: Any) {
        userDefaults.set(true, forKey: Constants.ipAddressActiveKey)
    }

    @objc func connectionCallback() {
        DispatchQueue.main.async {
            if self.userDefaults.bool(forKey: Constants.ipAddressActiveKey) {
                self.localLabel.text = ""
                self.RemoteLabel.textColor = .green
                self.RemoteLabel.text = "Connected"
            } else {
                self.localLabel.text = "Connected"
                self.localLabel.textColor = .green
                self.RemoteLabel.text = ""
            }
            
        }
    }
    
    @objc func disConnectionCallback() {
        DispatchQueue.main.async {
            self.localLabel.text = "Disconnected"
            self.localLabel.textColor = .black
            self.RemoteLabel.textColor = .black
            self.RemoteLabel.text = "Disconnected"
        }
    }

}

extension ViewController:
UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.sharedInstance.appliance.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "applianceCell", for: indexPath) as? ApplianceLightCell
        let appliance = self.sharedInstance.appliance[indexPath.row]
        cell?.applianceName.text = "Light \(indexPath.row)"
        if let statis = appliance.isStatusOn {
        if statis {
            cell?.applianceImageView.image = UIImage(named: "lightOn")
            print("lightOn")
        } else {
            cell?.applianceImageView.image = UIImage(named: "lightOff")
            print("lightOff")
            }
        }
        return cell!
        
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        sendCommandToDevice(index: indexPath.row)
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
      return CGSize(width: 100, height: 100)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }

    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
}
    
