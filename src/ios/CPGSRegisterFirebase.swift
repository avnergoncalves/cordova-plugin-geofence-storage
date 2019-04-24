class CPGSRegisterFirebase: CPGSFirebaseDatabase {

    static let sharedInstance = CPGSRegisterFirebase()

    override var key: String {
        return "register"
    }

    func getLastedInserted(pointUID: String, with: @escaping (_ snapshot: DataSnapshot) -> Void) -> Void {
            self.ref
                .child(pointUID)
                .queryOrdered(byChild: "timestamp")
                .queryLimited(toLast: 1)
                .observeSingleEvent(of: .value, with: with)

    }

    func getByPointUID(pointUID: String, with: @escaping (_ snapshot: DataSnapshot) -> Void) -> Void {
            self.ref
                .child(pointUID)
                .queryOrdered(byChild: "timestamp")
                .observeSingleEvent(of: .value, with: with)
    }

    func getByFilters(pointUID: String, startAt: Double, endAt: Double, with: @escaping (_ snapshot: DataSnapshot) -> Void) -> Void {
            self.ref
                .child(pointUID)
                .queryOrdered(byChild: "timestamp")
                .queryStarting(atValue: startAt)
                .queryEnding(atValue: endAt)
                .observeSingleEvent(of: .value, with: with)
    }

    func save(value: NSDictionary, pointUID: String, uid: String! = nil) -> String {
        let node = self.ref.child(pointUID)

        var newUid: String! = uid
        if(newUid == nil){
            newUid = node.childByAutoId().key
        }

        node.child(newUid).setValue(value)
        return newUid
    }

    func getAll(with: @escaping (_ snapshot: DataSnapshot) -> Void) -> Void {
            self.ref
                .queryOrdered(byChild: "timestamp")
                .observeSingleEvent(of: .value, with: with)
    }

    func getByUID(uid: String, with: @escaping (_ snapshot: DataSnapshot) -> Void) -> Void {
        self.ref.child(uid).observeSingleEvent(of: .value, with: with)
    }

    func remove(_ pointUID: String, uid: String) -> Void {
        self.ref.child(pointUID).child(uid).removeValue()
    }

}
