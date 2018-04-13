class CPGSManager : NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    let store = CPGSGeofenceStore()
    let storeRegister = CPGSRegisterStore()

    override init() {
        super.init()

        log("GeofenceManager: init")

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.allowsBackgroundLocationUpdates = true

        var notificationDetail = Dictionary<String, String>()
        notificationDetail["text"] = "Plguin Geofence Initialized!"

        notifyAbout(JSON(notificationDetail), interval: 0)
    }

    func getCurrentLocation() -> JSON? {
        log("GeofenceManager: getCurrentLocation")

        let currentLocation = self.locationManager.location

        var data = Dictionary<String, String>()
        data["latitude"] = currentLocation?.coordinate.latitude.description
        data["longitude"] = currentLocation?.coordinate.longitude.description

        return JSON(data)
    }

    func requestAlwaysAuthorization() {
        log("GeofenceManager: requestAlwaysAuthorization")

        self.locationManager.requestAlwaysAuthorization()
    }

    func addOrUpdateRegisters(_ registers: JSON) {
        log("GeofenceManager: addOrUpdateRegisters")
        self.storeRegister.save(registers)
    }

    func addOrUpdateGeofence(_ geoNotification: JSON) {
        log("GeofenceManager: addOrUpdate")

        // let (_, warnings, errors) = checkRequirements()

        // log(warnings)
        // log(errors)

        let location = CLLocationCoordinate2DMake(
            geoNotification["latitude"].doubleValue,
            geoNotification["longitude"].doubleValue
        )

        let radius = geoNotification["radius"].doubleValue as CLLocationDistance
        let id = geoNotification["id"].stringValue
        let region = CLCircularRegion(center: location, radius: radius, identifier: id)

        var transitionType = 0
        if let i = geoNotification["transitionType"].int {
            transitionType = i
        }

        region.notifyOnEntry = 0 != transitionType & 1
        region.notifyOnExit = 0 != transitionType & 2

        //store
        self.store.save(geoNotification)
        self.locationManager.startMonitoring(for: region)
    }

    func checkRequirements() -> (Bool, [String], [String]) {
        log("GeofenceManager: checkRequirements")

        var errors = [String]()

        if (!CLLocationManager.isMonitoringAvailable(for: CLRegion.self)) {
            errors.append("Geofencing not available")
        }

        if (!CLLocationManager.locationServicesEnabled()) {
            errors.append("Error: Locationservices not enabled")
        }

        let authStatus = CLLocationManager.authorizationStatus()
        if (authStatus != CLAuthorizationStatus.authorizedAlways) {
            errors.append("Warning: Location always permissions not granted")
        }

        if (iOS8) {
            let isRegisteredForLocalNotifications = UIApplication.shared.currentUserNotificationSettings?.types.contains(UIUserNotificationType.alert) ?? false
            if(!isRegisteredForLocalNotifications){
                errors.append("Error: notification permission missing")
            }
        }

        let ok = (errors.count == 0)

        return (ok, [String](), errors)
    }

    func getRegistersByGeofence(_ geofenceId: String) -> [JSON]? {
        log("GeofenceManager: getRegistersByGeofence")
        return self.storeRegister.getByGeofence(geofenceId)
    }

    func getRegisters() -> [JSON]? {
        log("GeofenceManager: getRegisters")
        return self.storeRegister.getAll()
    }

    func getWatchedGeoNotifications() -> [JSON]? {
        log("GeofenceManager: getWatchedGeoNotifications")
        return self.store.getAll()
    }

    func getGeofenceById(_ id:String) -> JSON? {
        log("GeofenceManager: getGeofenceById")
        return self.store.findById(id)
    }

    func getMonitoredRegion(_ id: String) -> CLRegion? {
        log("GeofenceManager: getMonitoredRegion")
        for object in self.locationManager.monitoredRegions {
            let region = object

            if (region.identifier == id) {
                return region
            }
        }
        return nil
    }

    func removeRegister(_ id: String) {
        log("GeofenceManager: removeRegister")
        self.storeRegister.remove(id)
    }

    func removeGeofence(_ id: String) {
        log("GeofenceManager: removeGeoNotification")
        self.store.remove(id)
        let region = self.getMonitoredRegion(id)
        if (region != nil) {
            log("Stoping monitoring region \(id)")
            self.locationManager.stopMonitoring(for: region!)
        }
    }

    func removeAllGeofences() {
        log("GeofenceManager: removeAllGeoNotifications")
        self.store.clear()
        for object in self.locationManager.monitoredRegions {
            let region = object
            self.locationManager.stopMonitoring(for: region)
            log("GeofenceManager: Stoping monitoring region \(region.identifier)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        log("Update location")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log("Fail with error: \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        log("Deferred fail error: \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        log("Entering region \(region.identifier)")
        self.handleTransition(region, transitionType: 1)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        log("Exiting region \(region.identifier)")
        self.handleTransition(region, transitionType: 2)
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region is CLCircularRegion {
            let lat = (region as! CLCircularRegion).center.latitude
            let lng = (region as! CLCircularRegion).center.longitude
            let radius = (region as! CLCircularRegion).radius

            self.locationManager.requestState(for: region)
            log("Starting monitoring for region \(region) lat \(lat) lng \(lng) of radius \(radius)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        log("State for region \(region.identifier)")

        if let geo = store.findById(region.identifier) {
            var transitionType = 0
            if let i = geo["transitionType"].int {
                transitionType = i
            }
            if state == CLRegionState.inside && transitionType != 2 {
                let counRegisterByGeo = self.storeRegister.countByGeofence(region.identifier)
                if(counRegisterByGeo == 0){
                    self.handleTransition(region, transitionType: 1, ignoreInterval: true)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        log("Monitoring region " + region!.identifier + " failed \(error)" )
    }

    func handleTransition(_ region: CLRegion!, transitionType: Int, ignoreInterval:Bool = false) {
        if var geoNotification = self.store.findById(region.identifier) {
            geoNotification["transitionType"].int = transitionType

            var registerDetail:JSON
            var notificationDetail:JSON
            var interval:Double

            if(transitionType == 1){
                registerDetail = geoNotification["storage"]["onEnter"]
                notificationDetail = geoNotification["notification"]["onEnter"]
                interval = 0.0 * 60

                if(ignoreInterval){
                    interval = 0.0
                }

            }else{
                registerDetail = geoNotification["storage"]["onExit"]
                notificationDetail = geoNotification["notification"]["onExit"]
                interval = 0

                let lastedInserted:JSON? = self.storeRegister.getLastedInserted()
                if(lastedInserted != nil){
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                    let nowDt = Date()
                    let lastedInsertedDt = dateFormatter.date(from: lastedInserted!["created_at"].stringValue)
                    let lastedInsertedDtAdd3m = lastedInsertedDt?.addingTimeInterval(0.0 * 60)

                    if( nowDt < lastedInsertedDtAdd3m!){
                        UIApplication.shared.cancelAllLocalNotifications()
                        self.storeRegister.remove(lastedInserted!["id"].stringValue)
                        return
                    }

                }
            }

            notificationDetail["text"].stringValue = notificationDetail["text"].stringValue.replacingOccurrences(of: "{{description}}", with: geoNotification["description"].stringValue)

            notifyAbout(notificationDetail, interval: interval)

            registerDetail["geofence_id"].stringValue = geoNotification["id"].stringValue
            registerDetail["owner"].stringValue = "CGP"
            registerDetail["extra"].stringValue = "{\"is_save\":false}"

            addOrUpdateRegisters(registerDetail)

            //NotificationCenter.default.post(name: Notification.Name(rawValue: "handleTransition"), object: geoNotification.rawString(String.Encoding.utf8.rawValue, options: []))

            return
        }
    }

    func notifyAbout(_ notification: JSON, interval: Double) {
        log("CGPGeofenceManager: Creating notification")

        let uiNotification = UILocalNotification()
        uiNotification.timeZone = TimeZone.current
        uiNotification.fireDate = Date().addingTimeInterval(interval)
        uiNotification.soundName = UILocalNotificationDefaultSoundName
        uiNotification.alertBody = notification["text"].stringValue

        if let json = notification["data"] as JSON? {
            uiNotification.userInfo = ["geofence.notification.data": json.rawString(String.Encoding.utf8)!]
        }
        //UIApplication.shared.cancelAllLocalNotifications()
        UIApplication.shared.scheduleLocalNotification(uiNotification)
    }

    func registerUserNotificationSettings() {
        log("CGPGeofenceManager: registerUserNotificationSettings")
        DispatchQueue.main.async { // Correct
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(
                types: [UIUserNotificationType.sound, UIUserNotificationType.alert, UIUserNotificationType.badge],
                categories: nil
            ))
        }
    }
}
