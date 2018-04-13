# Cordova Plugin Geofence Storage

Plugin to monitor circular geofences using mobile devices. The purpose is to notify user if crossing the boundary of the monitored geofence.

*Geofences persist after device reboot. You do not have to open your app first to monitor added geofences*

## Supported Platforms
- iOS >=7.0

## Known Limitations

**This plugin is a wrapper on devices' native APIs** which mean it comes with **limitations of those APIs**.

### Geofence Limit

There are certain limits of geofences that you can set in your application depends on the platform of use.

- iOS - 20 geofences

## iOS

Plugin is written in Swift. All xcode project options to enable swift support are set up automatically after plugin is installed thanks to
[cordova-plugin-add-swift-support](https://github.com/akofman/cordova-plugin-add-swift-support).

:warning: Swift 4 is not supported at the moment, the following preference has to be added in your project :

For Cordova projects

`<preference name="UseLegacySwiftLanguageVersion" value="true" />`

For PhoneGap projects

`<preference name="swift-version" value="2.3" />`

# Using the plugin

Cordova initialize plugin to `window.GeofenceStorage` object.