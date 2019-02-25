//
//  PVLocationManager.m
//  PVLocationManager
//
//  Created by Prasanth Venigalla on 2/23/17.
//  Copyright © 2017 Prasanth Venigalla. All rights reserved.
//

#import "PVLocationManager.h"

NSString * const ErrorDomain = @"";
NSString * const geoFenceTag = @"geoFencedRegion";

@interface PVLocationManager()  <CLLocationManagerDelegate> {
    CLAuthorizationStatus _lastStatus;
}

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSHashTable *delegates;
@property (nonatomic, strong) CLRegion *currentRegion;
@property (nonatomic, copy) void(^completitionHandler)();

@end


@implementation PVLocationManager


+ (nonnull instancetype)manager {
    static PVLocationManager *_manager = nil;
    static dispatch_once_t oncetoken;
    
    dispatch_once(&oncetoken, ^{
        _manager = [[PVLocationManager alloc] init];
    });
    
    return _manager;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        
        _delegates = [NSHashTable weakObjectsHashTable];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.delegate = self;
            _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        });
        
        _lastStatus = kCLAuthorizationStatusNotDetermined;
        
        [self setupNotifications];
    }
    return self;
}


- (void)dealloc {
    [self stopUpdatingLocation];
    
    if (_locationManager) {
        _locationManager = nil;
    }
    
    // do a try-catch incase observers might have been removed or never added.
    
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    @catch (NSException *exception) {
        
    }
}

#pragma mark - Notifications

/*!
 * @discussion A method to set up observers to perform other methods didEnterForeground() &
 * didEnterBackground() upon recieving the posting of the proper notification relating to the state of the
 * user and his interaction with the application (whether it is the background or foreground of his 
 * device.
 */

- (void)setupNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)didEnterBackground {
    [self stopUpdatingLocation];
}

- (void)didEnterForeground {
    [self startUpdatingLocation];
}


#pragma mark - Start/Stop Location Manager

/*!
 * @discussion A set of methods to handle starting & stopping CCLocationManager. These methods
 * should be called sometime after initilization of the PVLocationManager classes depending when you
 * want to begin capturing the user's location and when you want to stop.
 */

- (void)startUpdatingLocation {
    if([CLLocationManager locationServicesEnabled] &&
       ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)){
           
           [_locationManager stopUpdatingLocation];
           [_locationManager startUpdatingLocation];
       }
    
    else {
        [self updateAuthorizationStatus];
    }
}

- (void)stopUpdatingLocation {
    [_locationManager stopUpdatingLocation];
}

#pragma mark - Request Authorization

/*!
 * @discussion A method to simply call on the instance of CCLocationManager to request for authorization
 * permissions on the user's device to access location capabilities. This should be called after 
 * initilization but prior to the user starting/stopping CCLocationManager.
 */

- (void)requestAuthorization {
    [_locationManager requestAlwaysAuthorization];
}

#pragma mark - Other Methods

/*!
 * @discussion A method that checks and returns the authorization status for location services.
 * @return YES/NO depending on whether location services have been enabled/authorization has been granted.
 */

- (BOOL)isLocationGranted {
    if([CLLocationManager locationServicesEnabled] &&
       ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)){
           return YES;
       }
    return NO;
}

/*!
 * @discussion A method that will present an alert prompting the user to Enable Geolocation services 
 * on his device for the application he is using. The pre-condition for this method to be called would be
 * only if he has explicitly denied location services access in the past or if for some reason the status
 * is not clear one way or another.
 */

- (void)presentUserDisabledGeolocationAlert {
    
    UIAlertController *alert =   [UIAlertController alertControllerWithTitle:@"Enable Geolocation"
                                                                     message:@"You have disabled Geolocation permissions for this application. Please enable Geolocation permissions in the Settings app for this app to be fully functional."
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action){
                                                          }];
    
    [alert addAction:dismissAction];
    
    UIWindow *myWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    myWindow.rootViewController = [[UIViewController alloc] init];
    myWindow.windowLevel = UIWindowLevelAlert;
    [myWindow makeKeyAndVisible];
    [myWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    
    
    [self updateAuthorizationStatus];
    
}

/*!
 * @discussion A method that will determine an appropriate message to be presented in the case that the 
 * didFailWithError: method is called by the CCLocationManager delegate on any view controller it is 
 * implemented on. If the PVLocationManager delegate is implemented, it will call the method with the 
 * appropriate message
 */

- (void)updateAuthorizationStatus {
    NSString *description = @"";
    
    switch ([CLLocationManager authorizationStatus] ) {
        case kCLAuthorizationStatusNotDetermined:
            description = @"The User hasn't determined it with regards to this application";
            break;
        case  kCLAuthorizationStatusRestricted:
            description = @"This application is NOT authorized to use location services. Due\
            to active restrictions on location services, the user cannot change\
            this status.";
            break;
        case kCLAuthorizationStatusDenied:
            description = @"The User has denied authorization for this application, or\
            // location services have been disabled.";
            break;
        default:
            break;
    }
    
    NSError *error =  [NSError errorWithDomain:ErrorDomain
                                          code:[CLLocationManager authorizationStatus]
                                      userInfo:@{NSLocalizedDescriptionKey : description}];
    
    
    for (id delegate in self.delegates){
        if ([delegate respondsToSelector:@selector(PVLocationManager:didFailWithError:)]){
            [delegate PVLocationManager:_locationManager didFailWithError:error];
        }
    }
}


#pragma mark - Add/Remove delegates

/*!
 * @discussion Set of methods to add or remove PVLocationManager delegate on a specific view
 * controller the developer would like to utilize this SDK to implement various location services.
 * These methods will either add or remove the individual delegates to an hashtable to keep track of each
 * individual one so that we can call methods on a particular delegate where required.
 */

- (void)addDelegate:(id <PVLocationManagerDelegate>)delegate {
    if (delegate && ![self.delegates containsObject:delegate]) {
        [self.delegates addObject:delegate];
    }
}

- (void)removeDelegate:(id)delegate {
    if (delegate  && [self.delegates containsObject:delegate]) {
        [self.delegates removeObject:delegate];
    }
}

#pragma mark - CLLocationManagerDelegate Methods

/*!
 * @discussion Set of methods to handle interactions with the CCLocationManagerDelegate methods.
 * didChangeAuthorizationStatus: is called whenever the application’s ability to use location services changes. This can occur if the user allowed or denied the use of location services for your application or for the device altogther. So when an authorization status changes, we want to know what it is to determine what to do next (start the manager, present an error, or save the previous status state)

 * didUpdateLocations: gives us an array of CCLocation objects that contain location data, with at least one object that represents the current location of the user. If updates were deferred or if multiple locations arrived before they could be delivered, the array may contain additional entries, organized in the order in which they occurred. We use this method to set location at the end of the array to our currentLocation because it is our last known location.
 
 * didFailWithError: is called if and when the location manager encounters an error trying to get the location or heading data. If indeed this method is called, we redirect the call to the view controller in which PVLocationManager delegate methods have been implemented where a proper response to the error presented can be constructed based on each developer's want/or need. As long as it is not an error regarding authorization or location services as a broader category, we don't care and give discreation to the developer on how to handle this.
 */

- (void)locationManager:(CLLocationManager *)locationManager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self startUpdatingLocation];
    }
    
    else if (status != kCLAuthorizationStatusNotDetermined && _lastStatus != status) {
        [self presentUserDisabledGeolocationAlert];
    }
    
    if (_lastStatus != status) {
        _lastStatus = status;
    }
}

- (void)locationManager:(CLLocationManager *)locationManager didUpdateLocations:(NSArray<CLLocation *> *)locArr {
    
    [self requestAuthorization];
    
    CLLocation *currentLocation = [locArr lastObject];
    CLLocation *oldLocation = _lastKnownLocation;
    _lastKnownLocation = currentLocation;
    
    for (id delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(PVLocationManager:
                                                   didUpdateToLocation:
                                                   fromLocation:)]) {
            
            [delegate PVLocationManager:locationManager
                     didUpdateToLocation:currentLocation
                            fromLocation:oldLocation];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)err {
    for (id delegate in self.delegates){
        if ([delegate respondsToSelector:@selector(PVLocationManager:didFailWithError:)]) {
            [delegate PVLocationManager:manager didFailWithError:err];
        }
    }
}

#pragma mark - Methods to handle Geo-Fencing

/*!
 * @discussion registerRegionWithCoordinates handles setting a region to be monitored for geo-fencing
 * purposes. Here we specify not only the region to be monitored but we specify what notifications we want
 * (on entry and exit of user into the region).
 */

- (void)registerRegionWithCoordinates:(CLLocationCoordinate2D)coordinate withRadius:(CLLocationDistance)regionRadius completitionHandler:(void(^)())completitionHandler {
    
    //stop monitoring region if any
    
    if (self.currentRegion) {
        [self stopMonitoringCurrentRegionWithSucces:NO];
    }
    
    self.currentRegion = [[CLCircularRegion alloc]
                          initWithCenter:coordinate
                          radius:regionRadius
                          identifier:geoFenceTag];
    
    self.currentRegion.notifyOnExit = YES;
    self.currentRegion.notifyOnEntry = YES;
    
    [self.locationManager startMonitoringForRegion:self.currentRegion];

    self.completitionHandler = completitionHandler;
    
    [self stopUpdatingLocation];
}

/*!
 * @discussion didStartMonitoringForRegion handles what takes place when moniotring starts for a given
 * region. We just print to the log in the case monitoring starts for a region with data of the actual
 * region being monitored.
 */

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"Monitoring did start for region: %@", region);
}

/*!
 * @discussion didEnterRegion handles calling the appropriate delegate method in the ViewController 
 * implemented when a user enters a geo-fenced region we're monitoring. It checks all the delegates and
 * only calls the method on the appropriate one which has implemented geo-fencing.
 */

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region {
    
    for (id delegate in self.delegates){
        if ([delegate respondsToSelector:@selector(PVLocationManager:didEnterRegion:)]){
            // call the method on delegate
            [delegate PVLocationManager:_locationManager didEnterRegion:region];
        }
    }
}

/*!
 * @discussion didExitRegion handles calling the appropriate delegate method in the ViewController
 * implemented when a user exits a geo-fenced region we're monitoring. It checks all the delegates and
 * only calls the method on the appropriate one which has implemented geo-fencing. It also calls
 * stopMonitoringCurrentRegionWithSucces for the region that we're currently monitoring to reset our
 * system.
 */

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region {

    if ([region isEqual:self.currentRegion]) {
        [self stopMonitoringCurrentRegionWithSucces:YES];
    }
    
    for (id delegate in self.delegates){
        if ([delegate respondsToSelector:@selector(PVLocationManager:didExitRegion:)]){
            // call the method on delegate
            [delegate PVLocationManager:_locationManager didExitRegion:region];
        }
    }
}


/*!
 * @discussion monitoringDidFailForRegion handles what takes place when moniotring may have failed for
 * whatever reason. Here we throw a UIAlert with the given error message in such a case this method is
 * called. We also stop monitoring of the current region in the case we run into an error.
 */

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(nullable CLRegion *)region withError:(NSError *)error {
    
        UIAlertController *alert =   [UIAlertController alertControllerWithTitle:@"GeoFencing Error"
                                                                         message:[error localizedDescription]
                                                                  preferredStyle:UIAlertControllerStyleAlert];
    
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action){
                                                   }];
    
        [alert addAction:dismissAction];
    
        UIWindow *myWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        myWindow.rootViewController = [[UIViewController alloc] init];
        myWindow.windowLevel = UIWindowLevelAlert;
        [myWindow makeKeyAndVisible];
        [myWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        
        
    
    if ([region isEqual:self.currentRegion]) {
        [self stopMonitoringCurrentRegionWithSucces:NO];
    }
}

/*!
 * @discussion stopMonitoringCurrentRegionWithSucces stops monitoring the reigion when called and resets 
 * the variable currentRegion and the completionHandler block
 */

- (void)stopMonitoringCurrentRegionWithSucces:(BOOL)success {
    if (success) {
        self.completitionHandler();
    }
    
    [self.locationManager stopMonitoringForRegion:self.currentRegion];
    
    self.currentRegion = nil;
    self.completitionHandler = nil;
}




@end
