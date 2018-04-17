var exec = require("cordova/exec");
var channel = require('cordova/channel');

var TransitionType = {
    ENTER: 1,
    EXIT: 2,
    BOTH: 3,
};

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

  initialize: function() {
    return execPromise("GeofenceStorage", "initialize", []);
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

    return execPromise("GeofenceStorage", "removeRegister", ids);
  },

  getWatched: function() {
    return execPromise("GeofenceStorage", "getWatched", []);
  },

  clearBadge: function() {
    return execPromise("GeofenceStorage", "clearBadge", []);
  }

}

channel.onCordovaReady.subscribe(function () {

  exec(
    function(){channel.onCordovaInfoReady.fire();},
    function(){console.log('[ERROR] Error initializing geofence storage: ' + e);},
    'GeofenceStorage', 'onReady', []
  );

  GeofenceStorage.clearBadge();

});

// Clear badge on app resume if autoClear is set to true
channel.onResume.subscribe(function () {
    GeofenceStorage.clearBadge();
});

// Clear badge on app resume if autoClear is set to true
channel.onActivated.subscribe(function () {
    GeofenceStorage.clearBadge();
});

module.exports = GeofenceStorage;
