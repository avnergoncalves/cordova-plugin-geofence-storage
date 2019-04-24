
import Foundation

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
         FirebaseApp.configure()
         Database.database().isPersistenceEnabled = true

         self.notificationManager = CPGSManagerNotification()
         self.geofenceManager = CPGSManagerGeofence()

        log("Plugin Initialized and Firebase.configure has success")
    }

    @objc(onReady:)
    func onReady(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: onReady")

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(createUserFirebase:)
    func createUserFirebase(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: createUserFirebase")
        let email = (command.arguments[0] as! String)
        let password = (command.arguments[1] as! String)

        CPGSFirebaseAuth.sharedInstance.createUser(email: email, password: password) { (user, error) in
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(signInFirebase:)
    func signInFirebase(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: signInFirebase")
        let email = (command.arguments[0] as! String)
        let password = (command.arguments[1] as! String)

        CPGSFirebaseAuth.sharedInstance.signIn(email: email, password: password) { (user, error) in
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
    }

    @objc(signOutFirebase:)
    func signOutFirebase(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: signOutFirebase")

        var status = CDVCommandStatus_OK

        do {
            try CPGSFirebaseAuth.sharedInstance.signOut()
        }catch{
            log("Error on logout")
            status = CDVCommandStatus_ERROR
        }

        let pluginResult = CDVPluginResult(status: status)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(isAuthFirebase:)
    func isAuthFirebase(_ command: CDVInvokedUrlCommand) {
        let user = CPGSFirebaseAuth.sharedInstance.getCurrentUser()

        var status = CDVCommandStatus_OK
        if(user == nil){
            status = CDVCommandStatus_ERROR
        }

        let pluginResult = CDVPluginResult(status: status)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(requestAlwaysAuthorization:)
    func requestAlwaysAuthorization(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: requestAlwaysAuthorization")
        let complete = { () in
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        }
        self.geofenceManager.requestAlwaysAuthorization(complete: complete)
    }

    @objc(registerUserNotificationSettings:)
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

    @objc(checkRequirements:)
    func checkRequirements(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: checkRequirements")
        let (isOk, _, _) = self.geofenceManager.checkRequirements()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: isOk)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(clearBadge:)
    func clearBadge(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: clearBadge")

        CPGSManagerNotification.clearBadge()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(getBadge:)
    func getBadge(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getBadge")

        let num = CPGSManagerNotification.getBadge()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: num)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(getCurrentLocation:)
    func getCurrentLocation(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getCurrentLocation")

        DispatchQueue.global(qos: self.priority).async {

            let complete: ((_ locations: CLLocation) -> Void) = { (currentLocation) in
                var data = Dictionary<String, String>()
                data["lat"] = currentLocation.coordinate.latitude.description
                data["lng"] = currentLocation.coordinate.longitude.description
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

    @objc(addOrUpdatePoint:)
    func addOrUpdatePoint(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: addOrUpdatePoints")

        let point = command.arguments[0] as! NSDictionary

        if let uid = command.arguments[1] as? String{
            self.geofenceManager.addOrUpdateGeofence(point, uid: uid)
        }else{
            self.geofenceManager.addOrUpdateGeofence(point)
        }

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(getPoints:)
    func getPoints(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getPoints")
        
        CPGSPointFirebase.sharedInstance.getAll(with: { (snapshot) in
            let points = JSON(snapshot.value as? [String : AnyObject] ?? [:])

            var pointsJsonString: String = "[]"
            if(points.count > 0){
                pointsJsonString = points.description
            }

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: pointsJsonString)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        })
    }

    @objc(getPointByUID:)
    func getPointByUID(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getPointByUID")

        let uid = command.arguments[0] as! String
        CPGSPointFirebase.sharedInstance.getByUID(uid: uid, with: { (snapshot) in
            let point = JSON(snapshot.value as? [String : AnyObject] ?? [:])

            var pointJsonString: String = "[]"
            if(point.count > 0){
                pointJsonString = point.description
            }

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: pointJsonString)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        })
    }

    @objc(removePoints:)
    func removePoints(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: removePoints")

        for key in command.arguments {
            if let pointUID = key as? String {
                self.geofenceManager.removeGeofenceByUID(pointUID)

                CPGSRegisterFirebase.sharedInstance.getByPointUID(pointUID: pointUID, with: { (snapshot) in
                    let registers = snapshot.value as? [String : AnyObject] ?? [:]
                    for i in registers {
                        CPGSRegisterFirebase.sharedInstance.remove(pointUID, uid: i.key)
                    }
                })
            }
        }

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(getRegistersByFilters:)
    func getRegistersByFilters(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getRegistersByFilters")
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)

        CPGSRegisterFirebase.sharedInstance.getByFilters(
            pointUID: command.arguments[0] as! String,
            startAt: command.arguments[1] as! Double,
            endAt: command.arguments[2] as! Double,
            with: { (snapshot) in
                var arr = [AnyObject]()
                for register in snapshot.children.allObjects as! [DataSnapshot] {
                    if let obj = register.value as AnyObject? {
                        obj.setValue(register.key, forKey: "uid")
                        obj.setValue(command.arguments[0], forKey: "pointUID")
                        arr.append(obj)
                    }
                }

                let registers = JSON(arr)

                var registersJsonStr: String = "[]"
                if(registers.count > 0){
                    registersJsonStr = registers.description
                }

                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: registersJsonStr.description)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        })
    }

    @objc(addOrUpdateRegister:)
    func addOrUpdateRegister(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: addOrUpdateRegister")
        let register = command.arguments[0] as! NSDictionary
        let pointUID = command.arguments[1] as! String

        if let uid = command.arguments[2] as? String{
            _ = CPGSRegisterFirebase.sharedInstance.save(value: register, pointUID: pointUID, uid:uid)
        }else{
            _ = CPGSRegisterFirebase.sharedInstance.save(value: register, pointUID: pointUID)
        }

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(getRegisters:)
    func getRegisters(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getRegisters")

        CPGSRegisterFirebase.sharedInstance.getAll(with: { (snapshot) in

            var arrayStapshot = [AnyObject]()
            pointLoop: for point in snapshot.children.allObjects as! [DataSnapshot] {
                for register in point.children.allObjects as! [DataSnapshot] {
                    if(arrayStapshot.count < 20){
                        if let obj = register.value as AnyObject? {
                            obj.setValue(register.key, forKey: "uid")
                            obj.setValue(point.key, forKey: "pointUID")
                            arrayStapshot.append(obj)
                        }
                    }else{
                        break pointLoop
                    }
                }
            }

            let registers = JSON(arrayStapshot)

            var registersJsonStr: String = "[]"
            if(registers.count > 0){
                registersJsonStr = registers.description
            }

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: registersJsonStr.description)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        })
    }

    @objc(getRegistersByPointUUID:)
    func getRegistersByPointUUID(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: getRegistersByPointUUID")

        CPGSRegisterFirebase.sharedInstance.getByPointUID(pointUID: command.arguments[0] as! String, with: { (snapshot) in
            let registers = JSON(snapshot.value as? [String : AnyObject] ?? [:])

            var registersJsonStr: String = "[]"
            if(registers.count > 0){
                registersJsonStr = registers.description
            }

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: registersJsonStr.description)
            self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        })
    }

    @objc(removeRegister:)
    func removeRegister(_ command: CDVInvokedUrlCommand) {
        log("CPGSPlugin: removeRegister")

        let pointUID = command.arguments[0] as! String
        let uid = command.arguments[1] as! String

        CPGSRegisterFirebase.sharedInstance.remove(pointUID, uid: uid)

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }
}
