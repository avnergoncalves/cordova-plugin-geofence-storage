
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
        log("GeofencePlugin: pluginInitialize")

        self.notificationManager = CPGSManagerNotification()
        self.geofenceManager = CPGSManagerGeofence()
    }

    func onReady(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: onReady")

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
    
    func clearBadge(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: clearBadge")
        
        CPGSManagerNotification.clearBadge()
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func initialize(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: initialization")

        let (ok, warnings, errors) = self.geofenceManager.checkRequirements()

        log(warnings)
        log(errors)

        let pluginResult: CDVPluginResult
        if ok {
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: warnings.joined(separator: "\n")
            )
        } else {
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ILLEGAL_ACCESS_EXCEPTION,
                messageAs: (errors + warnings).joined(separator: "\n")
            )
        }

        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func checkRequirements(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: checkRequirements")
        let (isOk, _, _) = self.geofenceManager.checkRequirements()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: isOk)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func requestAlwaysAuthorization(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: requestAlwaysAuthorization")

        DispatchQueue.global(qos: self.priority).async {
            // do some task
            self.geofenceManager.callbackDidChangeAuthorization = { () in
                DispatchQueue.main.async {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                }
            }
            
            self.geofenceManager.requestAlwaysAuthorization()
        }
    }

    func registerUserNotificationSettings(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: registerUserNotificationSettings")
        
        CPGSManagerNotification.registerUserNotificationSettings() { () in
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    func getCurrentLocation(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: getCurrentLocation")
        let currentlocation = self.geofenceManager.getCurrentLocation()!
        let currentlocationJsonString = currentlocation.description

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: currentlocationJsonString)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func addOrUpdateRegisters(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: addOrUpdateRegisters")

        for res in command.arguments {
            self.geofenceManager.addOrUpdateRegisters(JSON(res))
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func addOrUpdateGeofences(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: addOrUpdateGeofences")
        for geo in command.arguments {
            self.geofenceManager.addOrUpdateGeofence(JSON(geo))
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func getRegistersByGeofence(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: getRegistersByGeofence")
        let geofences:[JSON]? = self.geofenceManager.getRegistersByGeofence(command.arguments[0] as! String)

        var geofencesJsonString: String = "[]"
        if(geofences != nil){
            geofencesJsonString = (geofences?.description)!
        }

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: geofencesJsonString)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func getRegisters(_ command: CDVInvokedUrlCommand) {
        log("GeofencePlugin: getRegisters")
        let registers = self.geofenceManager.getRegisters()!
        let registersJsonString = registers.description
            
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: registersJsonString)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func getWatched(_ command: CDVInvokedUrlCommand) {
        let watched:[JSON]? = self.geofenceManager.getWatchedGeoNotifications()
        var watchedJsonString: String = "[]"
        if(watched != nil){
            watchedJsonString = (watched?.description)!
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: watchedJsonString)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func getGeofenceById(_ command: CDVInvokedUrlCommand) {
        let geofence:JSON? = self.geofenceManager.getGeofenceById(command.arguments[0] as! String)
        var geofenceJsonString: String = "null"
        if(geofence != nil){
            geofenceJsonString = (geofence?.description)!
        }

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: geofenceJsonString)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func removeRegister(_ command: CDVInvokedUrlCommand) {
        for id in command.arguments {
            self.geofenceManager.removeRegister(id as! String)
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func remove(_ command: CDVInvokedUrlCommand) {
        for id in command.arguments {
            self.geofenceManager.removeGeofence(id as! String)
        }
            
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func removeAll(_ command: CDVInvokedUrlCommand) {
        self.geofenceManager.removeAllGeofences()
        
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
