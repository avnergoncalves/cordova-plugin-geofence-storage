var exec    = require("cordova/exec");
var channel = require('cordova/channel');

function execPromise(pluginName, method, args) {
    return new Promise(function (resolve, reject) {
        exec(function (result) {
                resolve(result);
            },
            function (reason) {
                reject(reason);
            },
            pluginName,
            method,
            args);
    });
}

var GeofenceStorage = {

  _onReady: function() {
    return execPromise("GeofenceStorage", "onReady", []);
  },

  checkRequirements: function() {
    return execPromise("GeofenceStorage", "checkRequirements", []);
  },

  registerUserNotificationSettings: function() {
    return execPromise("GeofenceStorage", "registerUserNotificationSettings", []);
  },

  requestAlwaysAuthorization: function() {
    return execPromise("GeofenceStorage", "requestAlwaysAuthorization", []);
  },

  getCurrentLocation: function() {
    return execPromise("GeofenceStorage", "getCurrentLocation", []);
  },

  getRegisters: function() {
    return execPromise("GeofenceStorage", "getRegisters", []);
  },

  getRegistersByGeofence: function(geofenceId) {
    geofenceId = geofenceId.toString();
    return execPromise("GeofenceStorage", "getRegistersByGeofence", [geofenceId]);
  },

  getGeofenceById: function(id) {
    id = id.toString();
    return execPromise("GeofenceStorage", "getGeofenceById", [id]);
  },

  addOrUpdateRegisters: function(registers) {
    if (!Array.isArray(registers)) {
      registers = [registers];
    }

    return execPromise("GeofenceStorage", "addOrUpdateRegisters", registers);
  },

  addOrUpdateGeofences: function(geofences) {
    if (!Array.isArray(geofences)) {
      geofences = [geofences];
    }

    return execPromise("GeofenceStorage", "addOrUpdateGeofences", geofences);
  },

  removeRegisters: function(ids) {
    if (!Array.isArray(ids)) {
      ids = [ids];
    }

    return execPromise("GeofenceStorage", "removeRegisters", ids);
  },

  removeGeofences: function(ids) {
    if (!Array.isArray(ids)) {
      ids = [ids];
    }

    return execPromise("GeofenceStorage", "removeGeofences", ids);
  },

  getGeofences: function() {
    return execPromise("GeofenceStorage", "getGeofences", []);
  },

  clearBadge: function() {
    return execPromise("GeofenceStorage", "clearBadge", []);
  }

}

// Bind events
channel.onCordovaReady.subscribe(function () {
  GeofenceStorage._onReady().then(
    function(){
      channel.onCordovaInfoReady.fire();
    },
    function(){
      console.log('[ERROR] Error initializing geofence storage: ' + e);
    }
  );
});

module.exports = GeofenceStorage;
