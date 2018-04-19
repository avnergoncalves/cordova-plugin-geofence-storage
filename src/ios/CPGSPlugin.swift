
import Foundation
import AudioToolbox
import WebKit

let TAG = "CPGS"
let iOS8 = floor(NSFoundationVersionNumber) > floor(NSFoundationVersionNumber_iOS_7_1)
let iOS7 = floor(NSFoundationVersionNumber) <= floor(NSFoundationVersionNumber_iOS_7_1)

func log(_ message: String){
    NSLog("%@ - %@", TAG, message)
}

func log(_ messages: [String]) {
    for message in messages {
        log(message);
    }
}

@available(iOS 10.0, *)
@objc(CPGSPlugin) class CPGSPlugin : CDVPlugin {

    lazy var notificationManager = CPGSManagerNotification()
    lazy var geofenceManager = CPGSManagerGeofence()
    let priority = DispatchQoS.QoSClass.default

    override func pluginInitialize () {
        log("CPGSPlugin: pluginInitialize")

        self.notificationManager = CPGSManagerNotification()
        self.geofenceManager = CPGSManagerGeofence()
    }

    func onReady(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: onReady")

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    func requestAlwaysAuthorization(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: requestAlwaysAuthorization")
        
        DispatchQueue.global(qos: self.priority).async {
            let complete = { () in
                DispatchQueue.main.async {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                }
            }
            
            self.geofenceManager.requestAlwaysAuthorization(complete: complete)
        }
    }
    
    func registerUserNotificationSettings(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: registerUserNotificationSettings")
        
        CPGSManagerNotification.registerUserNotificationSettings() { (granted) in
            var status = CDVCommandStatus_OK
            if(!granted){
                status = CDVCommandStatus_ERROR
            }
            
            let pluginResult = CDVPluginResult(status: status)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    func checkRequirements(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: checkRequirements")
        let (isOk, _, _) = self.geofenceManager.checkRequirements()
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: isOk)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    func clearBadge(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: clearBadge")
        
        CPGSManagerNotification.clearBadge()
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func getCurrentLocation(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getCurrentLocation")
        
        DispatchQueue.global(qos: self.priority).async {
            
            let complete: ((_ locations: CLLocation) -> Void) = { (currentLocation) in
                var data = Dictionary<String, String>()
                data["latitude"] = currentLocation.coordinate.latitude.description
                data["longitude"] = currentLocation.coordinate.longitude.description
                let currentLocationJsonString = JSON(data).description
                
                DispatchQueue.main.async {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: currentLocationJsonString)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                }
            }
            
            // do some task
            self.geofenceManager.getCurrentLocation(complete: complete)
        }
    }
    
    func addOrUpdateGeofences(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: addOrUpdateGeofences")
        for geo in command.arguments {
            self.geofenceManager.addOrUpdateGeofence(JSON(geo))
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    func getGeofences(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getGeofences")
        let watched:[JSON]? = self.geofenceManager.getGeofences()
        var watchedJsonString: String = "[]"
        if(watched != nil){
            watchedJsonString = (watched?.description)!
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: watchedJsonString)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    func getGeofenceById(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getGeofenceById")
        let geofence:JSON? = self.geofenceManager.getGeofenceById(command.arguments[0] as! String)
        var geofenceJsonString: String = "null"
        if(geofence != nil){
            geofenceJsonString = (geofence?.description)!
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: geofenceJsonString)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    func removeGeofences(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: removeGeofences")
        
        var registers: [JSON]? = nil
        for id in command.arguments {
            registers = self.geofenceManager.getRegistersByGeofence(id as! String)
            if(registers != nil){
                for reg in registers! {
                    self.geofenceManager.removeRegisters(reg["id"].stringValue)
                }
            }
            
            self.geofenceManager.removeGeofence(id as! String)
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    func addOrUpdateRegisters(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: addOrUpdateRegisters")
        
        for res in command.arguments {
            self.geofenceManager.addOrUpdateRegisters(JSON(res))
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    func getRegisters(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getRegisters")
        let registers = self.geofenceManager.getRegisters()!
        let registersJsonString = registers.description
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: registersJsonString)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    func getRegistersByGeofence(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getRegistersByGeofence")
        let geofences:[JSON]? = self.geofenceManager.getRegistersByGeofence(command.arguments[0] as! String)
        
        var geofencesJsonString: String = "[]"
        if(geofences != nil){
            geofencesJsonString = (geofences?.description)!
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: geofencesJsonString)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func removeRegisters(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: removeRegisters")
        for id in command.arguments {
            self.geofenceManager.removeRegisters(id as! String)
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func didReceiveTransition (_ notification: Notification) {
        log("didReceiveTransition")
        // if let geoNotificationString = notification.object as? String {

            // let js = "setTimeout('geofence.onTransitionReceived([" + geoNotificationString + "])',0)"
            // evaluateJs(js)
        // }
    }

    func didReceiveLocalNotification (_ notification: Notification) {
        log("didReceiveLocalNotification")

        // if UIApplication.shared.applicationState != UIApplicationState.active {
            // var data = "undefined"
            // if let uiNotification = notification.object as? UILocalNotification {
                // if let notificationData = uiNotification.userInfo?["geofence.notification.data"] as? String {
                    // data = notificationData
                // }
                // let js = "setTimeout('geofence.onNotificationClicked(" + data + ")',0)"

                // evaluateJs(js)
            // }
        // }
    }

    /*func evaluateJs (_ script: String) {
        if let webView = webView {
            if let uiWebView = webView as? UIWebView {
                uiWebView.stringByEvaluatingJavaScript(from: script)
            } else if let wkWebView = webView as? WKWebView {
                wkWebView.evaluateJavaScript(script, completionHandler: nil)
            }
        } else {
            log("webView is nil")
        }
    }*/
}
