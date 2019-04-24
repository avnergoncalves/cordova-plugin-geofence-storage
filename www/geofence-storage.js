var exec    = require("cordova/exec");
var channel = require('cordova/channel');

const PLUGIN_NAME = "GeofenceStorage";

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
    return execPromise(PLUGIN_NAME, "onReady", []);
  },

  /*INI AUTH FIREBASE*/
  createUserFirebase: function(email, password) {
    return execPromise(PLUGIN_NAME, "createUserFirebase", [email, password]);
  },
  signInFirebase: function(email, password) {
    return execPromise(PLUGIN_NAME, "signInFirebase", [email, password]);
  },
  signOutFirebase: function() {
    return execPromise(PLUGIN_NAME, "signOutFirebase", []);
  },
  isAuthFirebase: function() {
    return execPromise(PLUGIN_NAME, "isAuthFirebase", []);
  },
  /*INI AUTH FIREBASE*/

  checkRequirements: function() {
    return execPromise(PLUGIN_NAME, "checkRequirements", []);
  },
  registerUserNotificationSettings: function() {
    return execPromise(PLUGIN_NAME, "registerUserNotificationSettings", []);
  },
  requestAlwaysAuthorization: function() {
    return execPromise(PLUGIN_NAME, "requestAlwaysAuthorization", []);
  },
  getCurrentLocation: function() {
    return execPromise(PLUGIN_NAME, "getCurrentLocation", []);
  },
  clearBadge: function() {
    return execPromise(PLUGIN_NAME, "clearBadge", []);
  },
  getBadge: function() {
    return execPromise(PLUGIN_NAME, "getBadge", []);
  },

  /* INI REGISTERS */
  getRegisters: function() {
    return execPromise(PLUGIN_NAME, "getRegisters", []);
  },
  getRegistersByPointUUID: function(uuid) {
    uuid = uuid.toString();
    return execPromise(PLUGIN_NAME, "getRegistersByPointUUID", [uuid]);
  },
  getRegistersByFilters: function(pointUID, dtIni, dtEnd) {
    pointUID = pointUID.toString();
    return execPromise(PLUGIN_NAME, "getRegistersByFilters", [pointUID, dtIni, dtEnd]);
  },
  addOrUpdateRegister: function(register, pointUID, uid) {
    return execPromise(PLUGIN_NAME, "addOrUpdateRegister", [register, pointUID, uid]);
  },
  removeRegister: function(pointUID, uid) {
    return execPromise(PLUGIN_NAME, "removeRegister", [pointUID, uid]);
  },
  /* END REGISTERS */

  /* INI POINTS */
  getPointByUID: function(uid) {
    return execPromise(PLUGIN_NAME, "getPointByUID", [uid]);
  },
  addOrUpdatePoint: function(point, uid) {
    return execPromise(PLUGIN_NAME, "addOrUpdatePoint", [point, uid]);
  },
  removePoints: function(uuids) {
    if (!Array.isArray(uuids)) {
      uuids = [uuids];
    }
    return execPromise(PLUGIN_NAME, "removePoints", uuids);
  },
  getPoints: function() {
    return execPromise(PLUGIN_NAME, "getPoints", []);
  },
  /* END POINTS */

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
