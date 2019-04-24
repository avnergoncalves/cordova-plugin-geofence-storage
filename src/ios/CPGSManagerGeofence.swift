@available(iOS 10.0, *)
class CPGSManagerGeofence : NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    let locationManager = CLLocationManager()
    
    var callbackDidChangeAuthorization: (() -> Void)? = nil
    var callbackdidUpdateLocations: ((_ locations: CLLocation) -> Void)? = nil

    override init() {
        super.init()

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.allowsBackgroundLocationUpdates = true
    }

    func getCurrentLocation(complete: @escaping ((_ locations: CLLocation) -> Void)) -> Void {
        log("GeofenceManager: getCurrentLocation")
        self.callbackdidUpdateLocations = complete
        self.locationManager.startUpdatingLocation()
    }

    func requestAlwaysAuthorization(complete: @escaping (() -> Void)) {
        log("GeofenceManager: requestAlwaysAuthorization")
        self.callbackDidChangeAuthorization = complete
        self.locationManager.requestAlwaysAuthorization()
    }

    func addOrUpdateGeofence(_ geo: NSDictionary, uid: String? = nil) {
        log("GeofenceManager: addOrUpdatePoint")

        let identifier = CPGSPointFirebase.sharedInstance.save(value: geo, uid: uid)

        if let geofence = geo["geofence"] as? NSDictionary {

            let location = geofence["location"] as? NSDictionary
            let coordinate = CLLocationCoordinate2DMake(
                location!["lat"] as! Double, location!["lng"] as! Double
            )

            let radius = geofence["radius"] as? CLLocationDistance
            let region = CLCircularRegion(
                center: coordinate, radius: radius!, identifier: identifier
            )

            var transitionType = 0
            if let i = geofence["transitionType"] as? Int {
                transitionType = i
            }

            region.notifyOnEntry = 0 != transitionType & 1
            region.notifyOnExit = 0 != transitionType & 2

            self.locationManager.startMonitoring(for: region)
        }

    }

    func getMonitoredRegion(_ uid: String) -> CLRegion? {
        log("GeofenceManager: getMonitoredRegion")
        for object in self.locationManager.monitoredRegions {
            let region = object
            if (region.identifier == uid) {
                return region
            }
        }
        return nil
    }

    func removeGeofenceByUID(_ uid: String) {
        log("GeofenceManager: removeGeofence")
        let region = self.getMonitoredRegion(uid)
        if (region != nil) {
            log("Stoping monitoring region \(uid)")
            self.locationManager.stopMonitoring(for: region!)
        }

        CPGSPointFirebase.sharedInstance.remove(uid)
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
        
        let ok = (errors.count == 0)
        
        return (ok, [String](), errors)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log("Fail with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        log("Deferred fail error: \(String(describing: error))")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        log("Monitoring region " + region!.identifier + " failed \(error)" )
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        log("Update didChangeAuthorizationStatus")
        if(self.callbackDidChangeAuthorization != nil){
            self.callbackDidChangeAuthorization!()
            self.callbackDidChangeAuthorization = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        log("Update didUpdateLocations")
        if(self.callbackdidUpdateLocations != nil){
            self.callbackdidUpdateLocations!(locations.last!)
            self.callbackdidUpdateLocations = nil
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        log("Entering region \(region.identifier)")
        self.handleTransition(region, transitionType: 1)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        log("Exiting region \(region.identifier)")
        self.handleTransition(region, transitionType: 2)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        log("State for region \(region.identifier)")
        
        CPGSPointFirebase.sharedInstance.getByUID(uid: region.identifier, with: { (snapshot) in
            let point = snapshot.value as? [String : AnyObject] ?? [:]
            
            var transitionType = 0
            if let i: Int = point["geofence"]!["transitionType"] as? Int {
                transitionType = i
            }
            
            if state == CLRegionState.inside && transitionType != 2 {
                CPGSRegisterFirebase.sharedInstance.getByPointUID(pointUID: region.identifier, with: {(snapshot) in
                    let countRegisterByPoint = snapshot.childrenCount
                    if(countRegisterByPoint == 0){
                        self.handleTransition(region, transitionType: 1, ignoreInterval: true)
                    }
                })
            }
        })

    }
    
    private func saveAndNotify(
        register: NSDictionary,
        pointUID: String,
        pointDesc: String,
        notify:JSON?,
        interval: Double
    ) -> Void {
        _ = CPGSRegisterFirebase.sharedInstance.save(value: register, pointUID: pointUID)
        if var notify = notify {
            notify["text"].stringValue = notify["text"].stringValue.replacingOccurrences(of: "{{description}}", with: pointDesc)
            CPGSManagerNotification.notify(notify, interval: interval)
        }
    }
    
    private func optimizeGeofence(pointUID: String, interval: Double, onExecute: @escaping () -> ()){
        CPGSRegisterFirebase.sharedInstance.getLastedInserted(pointUID: pointUID, with: {(snapshot) in
            let lastedInserted = snapshot.value as? [String : AnyObject] ?? [:]
            
            if(lastedInserted.count > 0){
                let key = lastedInserted.keys.first!
                
                if let t = lastedInserted[key]!["timestamp"] as? Double {
                    let nowDt = Date()
                    let lastedInsertedDt = Date(timeIntervalSince1970: (t/1000))
                    let lastedInsertedDtAddMinutes = lastedInsertedDt.addingTimeInterval(interval)
                    
                    if(nowDt < lastedInsertedDtAddMinutes){
                        CPGSManagerNotification.removeAll()
                        CPGSRegisterFirebase.sharedInstance.remove(pointUID, uid: key)
                        return
                    }
                }
            }
            
            onExecute()
        })
    }
    
    func handleTransition(_ region: CLRegion!, transitionType: Int, ignoreInterval:Bool = false) {
        CPGSPointFirebase.sharedInstance.getByUID(uid: region.identifier, with: { (snapshot) in
            let point = snapshot.value as? [String : AnyObject] ?? [:]
            
            let delay:Double = (point["geofence"]!["delay"] as! Double) * 60
            
            var notificationDetail:JSON? = nil
            var interval = 0.0
            
            var register = [
                "transition_type": transitionType.description,
                "timestamp": ServerValue.timestamp()
                ] as [String : Any]
            
            if(transitionType == 1){
                register["description"] = point["geofence"]!["descOnEntry"] as? String
                
                if let notify = point["notification"]!["onEnter"] {
                    notificationDetail = JSON(notify!)
                }
                
                if(!ignoreInterval){
                    interval = delay
                }
                
                self.saveAndNotify(
                    register: register as NSDictionary,
                    pointUID: region.identifier,
                    pointDesc: point["description"] as! String,
                    notify: notificationDetail,
                    interval: interval
                )
            }else{
                register["description"] = point["geofence"]!["descOnExit"] as? String
                
                if let notify = point["notification"]!["onExit"] {
                    notificationDetail = JSON(notify!)
                }
                
                if(!ignoreInterval){
                    self.optimizeGeofence(pointUID: region.identifier, interval: delay) { () in
                        self.saveAndNotify(
                            register: register as NSDictionary,
                            pointUID: region.identifier,
                            pointDesc: point["description"] as! String,
                            notify: notificationDetail,
                            interval: interval
                        )
                    }
                }
            }
        })
    }
    
}
