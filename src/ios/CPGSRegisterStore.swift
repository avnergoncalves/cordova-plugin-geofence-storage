class CPGSRegisterStore: CPGSStore {

    override var createTableStatemant: String {
        return "CREATE TABLE RegisterStore (id INTEGER PRIMARY KEY AUTOINCREMENT, geofence_id INTEGER, description TEXT, owner TEXT, type TEXT, extra TEXT, created_at DATETIME, updated_at DATETIME)"
    }

    override var tableName: String {
        return "RegisterStore"
    }

    func parseRow(resultSet: SD.SDRow) -> JSON {
        var data = Dictionary<String, String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        data["description"] = resultSet["description"]?.asString()
        data["owner"] = resultSet["owner"]?.asString()
        data["extra"] = resultSet["extra"]?.asString()
        data["type"] = resultSet["type"]?.asString()

        if let geofenceId = resultSet["geofence_id"]?.asInt() {
            data["geofence_id"] = geofenceId.description
        }

        if let id = resultSet["id"]?.asInt() {
            data["id"] = id.description
        }

        if let date1 = resultSet["updated_at"]?.asDate() {
            data["updated_at"] = formatter.string(from: date1)
        }

        if let date2 = resultSet["created_at"]?.asDate(){
            data["created_at"] = formatter.string(from: date2)
        }

        return JSON(data)
    }

    func insert(_ register: JSON) {

        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let err = SD.executeChange("INSERT INTO \(self.tableName) (description, owner, geofence_id, type, extra, updated_at, created_at) VALUES(?, ?, ?, ?, ?, ? ,?)",
            withArgs: [
                register["description"].stringValue as AnyObject,
                register["owner"].stringValue as AnyObject,
                register["geofence_id"].stringValue as AnyObject,
                register["type"].stringValue as AnyObject,
                register["extra"].stringValue as AnyObject,
                formatter.string(from: date) as AnyObject,
                formatter.string(from: date) as AnyObject,
                ])

        if err != nil {
            log("Error while adding \(self.tableName): \(err)")
        }
    }

    func update(_ register: JSON) {

        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let id = register["id"].stringValue
        let err = SD.executeChange("UPDATE \(self.tableName) SET description = ?, owner = ?, geofence_id = ?, type = ?, extra = ?, updated_at = ? WHERE Id = ?",
            withArgs: [
                register["description"].stringValue as AnyObject,
                register["owner"].stringValue as AnyObject,
                register["geofence_id"].stringValue as AnyObject,
                register["type"].stringValue as AnyObject,
                register["extra"].stringValue as AnyObject,
                formatter.string(from: date) as AnyObject,
                id as AnyObject
            ])

        if err != nil {
            log("Error while adding \(id) \(self.tableName): \(err)")
        }
    }

    func save(_ register: JSON) {
        if (self.findById(register["id"].stringValue) != nil) {
            update(register)
        }
        else {
            insert(register)
        }
    }

    func getLastedInserted() -> JSON? {
        let (resultSet, err) = SD.executeQuery("SELECT * FROM \(self.tableName) ORDER BY created_at desc")

        if err != nil {
            //there was an error during the query, handle it here
            log("getLastedInserted: Error while fetching \(self.tableName) table: \(err)")
            return nil
        } else {
            if (resultSet.count > 0) {
                return self.parseRow(resultSet: resultSet[0])
            }
            else {
                return nil
            }
        }
    }

    func findById(_ id: String) -> JSON? {
        let (resultSet, err) = SD.executeQuery("SELECT * FROM \(self.tableName) WHERE Id = ?", withArgs: [id as AnyObject])

        if err != nil {
            //there was an error during the query, handle it here
            log("Error while fetching \(id) \(self.tableName) table: \(err)")
            return nil
        } else {
            if (resultSet.count > 0) {
                return self.parseRow(resultSet: resultSet[0])
            }
            else {
                return nil
            }
        }
    }

    func countByGeofence(_ geofenceId: String) -> Int {
        let (resultSet, err) = SD.executeQuery("SELECT * FROM \(self.tableName) WHERE geofence_id = ?", withArgs: [geofenceId as AnyObject])

        if err != nil {
            //there was an error during the query, handle it here
            log("Error while fetching \(geofenceId) \(self.tableName) table: \(err)")
            return 0
        }

        return resultSet.count
    }

    func getByGeofence(_ geofenceId: String) -> [JSON]? {
        let (resultSet, err) = SD.executeQuery("SELECT * FROM \(self.tableName) WHERE geofence_id = ?", withArgs: [geofenceId as AnyObject])

        if err != nil {
            //there was an error during the query, handle it here
            log("Error while fetching \(geofenceId) \(self.tableName) table: \(err)")
        } else {
            if (resultSet.count > 0) {
                var results = [JSON]()
                for row in resultSet {
                    results.append(self.parseRow(resultSet: row))
                }
                return results
            }
        }

        return nil
    }

    func getAll() -> [JSON]? {
        let (resultSet, err) = SD.executeQuery("SELECT * FROM \(self.tableName)")

        if err != nil {
            //there was an error during the query, handle it here
            log("Error while fetching from \(self.tableName) table: \(err)")
        } else {
            if (resultSet.count > 0) {
                var results = [JSON]()
                for row in resultSet {
                    results.append(self.parseRow(resultSet: row))
                }
                return results
            }
        }

        return nil
    }
}
