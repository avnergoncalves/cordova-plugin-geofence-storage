
enum CPGSErrorsFirebase: Error {
    case noAuth
}

class CPGSFirebaseDatabase {

    var ref: DatabaseReference!

    var key: String {
        return ""
    }

    init() {
        do{
            let user = try self.getUser()
            self.ref = Database.database().reference(withPath: self.key).child(user.uid)
            self.ref.keepSynced(true)
        }catch{
            log("Error on CPGSFirebaseDatabase:getAll")
        }
    }


    func getUser() throws -> User {
        let user = CPGSFirebaseAuth.sharedInstance.getCurrentUser()
        if(user == nil){
            throw CPGSErrorsFirebase.noAuth
        }
        return user!
    }

    func clear() throws -> Void {
        do{
            let user = try self.getUser()
            self.ref.child(self.key).child(user.uid).removeValue()
        }catch{
            log("Error on CPGSFirebaseDatabase:clear")
        }
    }

}

class CPGSFirebaseAuth {

    static let sharedInstance = CPGSFirebaseAuth()

    func getCurrentUser() -> User? {
        let user = Auth.auth().currentUser
        if(user == nil){
            log("User not authenticate!")
        }

        return user
    }

    func createUser(email: String, password: String, completion: @escaping ((_ user: Any, _ error: Any) -> Void)) {
        Auth.auth().createUser(withEmail: email, password: password, completion: completion)
    }

    func signIn(email: String, password: String, completion: @escaping ((_ user: Any, _ error: Any) -> Void)) {
        return Auth.auth().signIn(withEmail: email, password: password, completion: completion)
    }

    func signOut() throws {
        return try Auth.auth().signOut()
    }

}
