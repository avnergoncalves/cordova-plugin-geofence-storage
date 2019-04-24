class CPGSPointFirebase: CPGSFirebaseDatabase {

    static let sharedInstance = CPGSPointFirebase()

    override var key: String {
        return "point"
    }

    func save(value: NSDictionary, uid: String! = nil) -> String {
        var newUid: String! = uid
        if(newUid == nil){
            newUid = self.ref.childByAutoId().key
        }

        self.ref.child(newUid).setValue(value)
        return newUid
    }

    func getAll(with: @escaping (_ snapshot: DataSnapshot) -> Void) -> Void {
        self.ref.observeSingleEvent(of: .value, with: with)
    }

    func getByUID(uid: String, with: @escaping (_ snapshot: DataSnapshot) -> Void) -> Void {
            self.ref.child(uid).observeSingleEvent(of: .value, with: with)
    }

    func remove(_ uid: String) -> Void {
        self.ref.child(uid).removeValue()
    }

}
