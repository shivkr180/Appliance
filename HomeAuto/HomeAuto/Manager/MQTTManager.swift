//
//  MQTTManager.swift
//  Digilux
//
//  Created by Shiv on 5/23/20.
//
//

import UIKit
import Moscapsule


class MQTTManager: NSObject {
    static let  mqttManager = MQTTManager ()
    let sharedInstance =  SharedInstance.ObjOfSharedInstance
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var mqttClient: MQTTClient? = nil
    var mqttConfig:MQTTConfig? = nil
    var mqttOpts:MQTTAuthOpts? = nil
    var userName = "test_iot"
    var password = "test_iot"
    var isAllAppliance = false
    let userDefaults = UserDefaults.standard
    var isUserConnected = false
    //Change Host Address
    //"10.10.1.151"
    
    
    
    
    func connectToMQTT() {
        //        let configureIpAddress = "broker.hivemq.com"
        //       let configureIpAddress = "13.233.215.104"
        let configureIpAddress = getIpAddress()
        print("configureIpAddress \(configureIpAddress)")
        //103.195.203.62
        //        let port = 1883
        let port = 1883
        let random = getRandomVaule()
        let clientId = "cid" + random
        print(clientId)
        mqttConfig = MQTTConfig(clientId: clientId, host: configureIpAddress, port: Int32(port), keepAlive: 60)
        
        self.mqttConfig?.onConnectCallback = { returnCode in
            NSLog("Return Code is \(returnCode.description)")
            self.isUserConnected = true
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MQQTConnectionCallback"), object: nil)
        }
        self.mqttConfig?.onDisconnectCallback = { returnCode in
            NSLog("Disconnect Code is \(returnCode.description)")
            self.isUserConnected = false
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MQQTDisconnectionCallback"), object: nil)
        }
        self.mqttConfig?.onMessageCallback = { mqttMessage in
            NSLog("MQTT Message received: payload=\(String(describing: mqttMessage.payloadString))")
            let responseFromMQTT = self.convertToDictionary(text: mqttMessage.payloadString!)
            if let response = responseFromMQTT {
                self.updateDeviceApplianceList(response)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ApplianceValueUpdated"), object: nil)
            }
            else if let timerStatus = self.convertTimerToDictionary(text: mqttMessage.payloadString!) {
                if let status = timerStatus["status"] as? String {
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TimerStatusChange"), object: nil)
                } 
            }
        }
        
        self.mqttConfig?.onPublishCallback = { messageId in
            NSLog("successful publish=\(String(describing: messageId))")
        }
        
        self.mqttConfig?.onSubscribeCallback = { (messageId, grantedQos) in
            NSLog("subscribed (mid=\(messageId),grantedQos=\(grantedQos))")
            
        }
        
        mqttOpts = MQTTAuthOpts(username: self.userName, password: self.password)
        mqttConfig?.mqttAuthOpts = mqttOpts
        
        // create new MQTT Connection
        self.mqttClient = MQTT.newConnection(self.mqttConfig!)
        mqttConfig?.cleanSession = false
        self.subscriptMQTT()
    }
    func getRandomVaule() -> String{
        let date = Date()
        let calendar = Calendar.current
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let randomInt =  UInt(arc4random_uniform(UInt32(50)))
        let random = String(minutes) + String(seconds) + String(randomInt)
        return random
        
    }
    func getStatus(jsonObject :NSMutableDictionary) {
        let jsonData: NSData
        var jsonString = ""
        do {
            jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions()) as NSData
            jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
            
        } catch _ {
            print ("JSON Failure")
        }
        let topic = getPublishTopic()
        self.mqttClient?.publish(string: jsonString, topic: topic, qos: 2, retain: false)
    }
    
    func convertToDictionary(text: String) -> [[String: Any]]? {
        if let dataTest: Data = text.data(using: String.Encoding.utf8) {
            do {
                let jsonOutput = try? JSONSerialization.jsonObject(with: dataTest, options: []) as? NSDictionary
                if let json = jsonOutput?["DEVICES"] as? [[String : Any]] {
                    return json
                } else if let json = jsonOutput?["AllDevices"] as? [[String : Any]] {
                    return json
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    func convertTimerToDictionary(text: String) -> [String: Any]? {
        if let dataTest: Data = text.data(using: String.Encoding.utf8) {
            do {
                let jsonOutput = try? JSONSerialization.jsonObject(with: dataTest, options: [])
                return jsonOutput as? [String : Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func disconnect() {
        // disconnect
        //  self.mqttClient?.disconnect()
    }
    
    func subscriptMQTT() {
        let subscribe = getSubscriptionTopic()
        self.mqttClient?.subscribe(subscribe, qos: 2)
    }
    func unSubscriptMQTT() {
        //        let subscribe = getSubscriptionTopic()
        //        self.mqttClient?.unsubscribe(subscribe)
    }
    func publishToMQTT(jsonObject :NSMutableDictionary) {
        let jsonData: NSData
        var jsonString = ""
        do {
            
            //            let jA:NSMutableArray = NSMutableArray()
            //            jA.add(jsonObject)
            //            let jO:NSMutableDictionary = NSMutableDictionary()
            //            jO["DEVICES"] = jA
            jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions()) as NSData
            jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
            print("json string = \(jsonString)")
            
        } catch _ {
            print ("JSON Failure")
        }
        let topic = getPublishTopic()
        print(topic)
        self.mqttClient?.publish(string: jsonString, topic: topic, qos: 2, retain: false)
        
    }
    func getSubscriptionTopic() -> String {
        let topic = "room/light"
        
        return topic
    }
    func getPublishTopic() -> String {
        let topic = "room/light"
        
        return topic
    }
    
    
    func updateDeviceApplianceList(_ responseFromMQTT:[[String: Any]]) {
        var tempApplianceValues:[Rooms] = []
        var applianceValueList:[Appliance] = []
        for arrayOfNodes in responseFromMQTT {
            let applianceValue = Rooms(jsonDictionary:arrayOfNodes)
            tempApplianceValues.append(applianceValue)
        }
        for applianceList in tempApplianceValues {
            for applianceValue in applianceList.rooms {
                applianceValueList.append(applianceValue)
            }
        }
        for appliance in applianceValueList {
            if let firstOdd = self.sharedInstance.appliance.firstIndex(where: { $0.applianceId == appliance.applianceId}) {
                self.sharedInstance.appliance[firstOdd] = appliance
            }
            
        }
    }
    
    func getIpAddress()->String {
        var ipAddress = "192.168.31.219"
        if userDefaults.bool(forKey: Constants.ipAddressActiveKey) {
            ipAddress = "13.233.215.104"
        } 
        return ipAddress
    }
}
