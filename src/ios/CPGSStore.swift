class CPGSStore {

    var tableName: String {
        return ""
    }
    var createTableStatemant: String {
        return ""
    }

    init() {
        self.createDBStructure()
    }

    func createDBStructure() {
        let (tables, err) = SD.existingTables()

        if (err != nil) {
            log("Cannot fetch sqlite tables: \(err)")
            return
        }

        if (tables.filter { $0 == self.tableName }.count == 0) {
            if let err = SD.executeChange(createTableStatemant) {
                //there was an error during this function, handle it here
                log("Error while creating \(self.tableName) table: \(err)")
            } else {
                //the table was created successfully
                log("\(self.tableName) table was created successfully")
            }
        }
    }

    func remove(_ id: String) {
        let err = SD.executeChange("DELETE FROM \(self.tableName) WHERE Id = ?", withArgs: [id as AnyObject])

        if err != nil {
            log("Error while removing \(id) \(self.tableName): \(err)")
        }
    }

    func clear() {
        let err = SD.executeChange("DELETE FROM \(self.tableName)")

        if err != nil {
            log("Error while deleting all from \(self.tableName): \(err)")
        }
    }
}
