class CPGSGeofenceStore: CPGSStore {

    override var createTableStatemant: String {
        return "CREATE TABLE GeofenceStore (ID TEXT PRIMARY KEY, Data TEXT)"
    }

    override var tableName: String {
        return "GeofenceStore"
    }

    func save(_ geoNotification: JSON) {
        if (findById(geoNotification["id"].stringValue) != nil) {
            update(geoNotification)
        }
        else {
            insert(geoNotification)
        }
    }

    func insert(_ geoNotification: JSON) {
        let id = geoNotification["id"].stringValue
        let err = SD.executeChange("INSERT INTO \(self.tableName) (Id, Data) VALUES(?, ?)",
            withArgs: [id as AnyObject, geoNotification.description as AnyObject])

        if err != nil {
            log("Error while adding \(id) \(self.tableName): \(err)")
        }
    }

    func update(_ geoNotification: JSON) {
        let id = geoNotification["id"].stringValue
        let err = SD.executeChange("UPDATE \(self.tableName) SET Data = ? WHERE Id = ?",
            withArgs: [geoNotification.description as AnyObject, id as AnyObject])

        if err != nil {
            log("Error while adding \(id) \(self.tableName): \(err)")
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
                let jsonString = resultSet[0]["Data"]!.asString()!
                return try? JSON(data: jsonString.data(using: String.Encoding.utf8)!)
            }
            else {
                return nil
            }
        }
    }

    func getAll() -> [JSON]? {
        let (resultSet, err) = SD.executeQuery("SELECT * FROM \(self.tableName)")

        if err != nil {
            //there was an error during the query, handle it here
            log("Error while fetching from \(self.tableName) table: \(err)")
            return nil
        } else {
            var results = [JSON]()

            for row in resultSet {
                if let data = row["Data"]?.asString() {
                    results.append(try! JSON(data: data.data(using: String.Encoding.utf8)!))
                }
            }
            return results
        }
    }

}
