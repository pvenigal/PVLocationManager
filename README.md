# README #

This README gives a brief overview of how to get started and set up PVLocationManager iOS SDK in your iOS application. 

### Getting Started / Prerequisites ###

* Set iOS Deployment target to 8.0 or above
* Import CoreLocation.framework into your project
* Add PVLocationManager-iOS-SDK classes to your project
* In your Info.plist, be sure to give messages for the following keys

```NSLocationAlwaysUsageDescription``` && ```NSLocationWhenInUseUsageDescription```

### How do I get set up? ###

* Import PVLocationManager.h into your desired class 
```
#!objc

#import "PVLocationManager.h"

```
* Add PVLocationManagerDelegate to your @ interface protocol 
```
#!objc

@interface ViewController () <PVLocationManagerDelegate> 

```
* Add Your Current ViewControllers delegate to PVLocationManager so that we can use its features. Generally useful to do this in your viewDidLoad() method or your viewWillAppear: method. Also, call requestAuthorization() to begin process of authentication.
```
#!objc

[[PVLocationManager manager] addDelegate:self];
[[PVLocationManager manager] requestAuthorization];

```

* Implement required delegate method didUpdateToLocation(). This will help you keep track of the device's current location.

```
#!objc
- (void) PVLocationManager:(CLLocationManager  * _Nonnull )manager
        didUpdateToLocation:(CLLocation * _Nullable)newLocation
               fromLocation:(CLLocation * _Nullable)oldLocation {

     //update current device location, setting its current location into 
       _devicePosition variable which will hold the latitude & longitude
    _devicePosition = newLocation.coordinate;

}
```

### Other features ###

* You can call ```[[PVLocationManager manager] isLocationGranted]``` which returns a boolean to let you know if permissions have been granted or not. If they haven't, you can call ```[[PVLocationManager manager] presentUserDisabledGeolocationAlert]``` to show an alert prompting the user to permit the app to access the device's location capabilities.

* If you would like to display an error if location tracking fails for any reason, you may implement ```PVLocationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error```

* If you would like to use geo-fencing capabilities, you must first call 
```[[PVLocationManager manager] registerRegionWithCoordinates:<#(CLLocationCoordinate2D)#> withRadius:<#(CLLocationDistance)#> completitionHandler:<#^(void)completitionHandler#>];``` to register the region you wish to track giving this method its coordinate (latitude & longitude) and the radius in meters of how far out you'd like to fence from the latitude/longitude coordinates. 

* Other methods to implement with geo-fencing are as follows, ```PVLocationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region``` to handle what happens if monitoring fails for any reason.

You can implement ```PVLocationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region``` to handle what happens when a user enters a specific region that's being monitored. 

You can implement ```PVLocationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region``` to handle what happens when a user exits a specific region that's being monitored. For this to be called, he must currently be in the monitored region and attempt to leave. 

### I've got more questions Who do I talk to? ###

* Repo owner, Prasanth Venigalla