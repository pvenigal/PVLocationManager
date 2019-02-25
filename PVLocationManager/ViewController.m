//
//  ViewController.m
//  PVLocationManager
//
//  Created by Prasanth Venigalla on 2/23/17.
//  Copyright © 2017 Prasanth Venigalla. All rights reserved.
//

#import "ViewController.h"
#import "PVLocationManager.h"

@import GoogleMaps;

@interface ViewController () <GMSMapViewDelegate, PVLocationManagerDelegate> {
    CLLocationCoordinate2D _currentMapPosition;
    CLLocationCoordinate2D _devicePosition;
    CLLocationCoordinate2D _regionCoordinates;
    
    CGFloat preferredMapZoomLevel;
}

@property (nonatomic, weak) IBOutlet GMSMapView *mapView;
@property (nonatomic, weak) IBOutlet UIButton *registerButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[PVLocationManager manager] addDelegate:self];
    [[PVLocationManager manager] requestAuthorization];
    
    _mapView.myLocationEnabled = YES;
    
    [self performSelector:@selector(startLocation) withObject:nil afterDelay:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //zoom to Adelphi to start
    _currentMapPosition = CLLocationCoordinate2DMake(40.7197f, -73.6517);
    

    preferredMapZoomLevel = 15.0f;
    
    [self setupMapPosition];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void) setupMapPosition {
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_currentMapPosition.latitude
                                                            longitude:_currentMapPosition.longitude
                                                                 zoom:preferredMapZoomLevel];
    [self.mapView animateToCameraPosition:camera];
}

- (IBAction)registerGeofence:(id)sender {
    //set a geo-fence around Johannesburg, South Africa
    _regionCoordinates = CLLocationCoordinate2DMake(-26.195246, 28.034088);
    
    CLLocationDistance regionRadius = 500000;
    
    [[PVLocationManager manager] registerRegionWithCoordinates:_regionCoordinates withRadius:regionRadius  completitionHandler:^{
        _registerButton.hidden = YES;
    }];
    
}

- (IBAction)locateMe:(id)sender {
    //zoom to current location
    
    if([[PVLocationManager manager] isLocationGranted]) {
        
        
        GMSCameraPosition *currentLocCamera = [GMSCameraPosition cameraWithLatitude:_devicePosition.latitude longitude:_devicePosition.longitude zoom:preferredMapZoomLevel];
        [self.mapView animateToCameraPosition:currentLocCamera];
        
    }
    
    else {
        [[PVLocationManager manager] presentUserDisabledGeolocationAlert];
    }
    
}

- (void) startLocation
{
    [[PVLocationManager manager] startUpdatingLocation];
}

#pragma mark - PVLocationManager delegate methods
- (void) PVLocationManager:(CLLocationManager  * _Nonnull )manager
        didUpdateToLocation:(CLLocation * _Nullable)newLocation
               fromLocation:(CLLocation * _Nullable)oldLocation{

    _devicePosition = newLocation.coordinate;

}

- (void) PVLocationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    _devicePosition = _currentMapPosition;

}

- (void)PVLocationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    NSLog(@"Did Enter Region: %@", region);

    UIAlertController *alert =   [UIAlertController alertControllerWithTitle:@"Did Enter Region"
                                                                     message:[NSString stringWithFormat:@"Did Enter Region: %@", region]
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action){
                                                          }];
    
    [alert addAction:dismissAction];
    

    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)PVLocationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Did Exit Region: %@", region);
    
    UIAlertController *alert =   [UIAlertController alertControllerWithTitle:@"Did Exit Region"
                                                                     message:[NSString stringWithFormat:@"Did Exit Region: %@", region]
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action){
                                                          }];
    
    [alert addAction:dismissAction];
    [self presentViewController:alert animated:YES completion:nil];

}

- (void)PVLocationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Monitoring Did Fail For Region: %@ with error: %@", region, error);
    
    UIAlertController *alert =   [UIAlertController alertControllerWithTitle:@"Error"
                                                                     message:[NSString stringWithFormat:@"Monitoring Did Fail For Region: %@ with error: %@", region, error]
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action){
                                                          }];
    
    [alert addAction:dismissAction];
    [self presentViewController:alert animated:YES completion:nil];


    
}



@end
