//
//  PVLocationManager.h
//  PVLocationManager
//
//  Created by Prasanth Venigalla on 2/23/17.
//  Copyright © 2017 Prasanth Venigalla. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol PVLocationManagerDelegate <NSObject>

@required
- (void) PVLocationManager:(CLLocationManager  * _Nonnull )manager
        didUpdateToLocation:(CLLocation * _Nullable)newLocation
               fromLocation:(CLLocation * _Nullable)oldLocation;

@optional
- (void) PVLocationManager:(CLLocationManager  * _Nonnull )manager
          didFailWithError:(NSError *_Nullable)error;

- (void)PVLocationManager:(CLLocationManager *_Nonnull)manager didEnterRegion:(CLRegion *_Nonnull)region;

- (void)PVLocationManager:(CLLocationManager *_Nonnull)manager didExitRegion:(CLRegion *_Nonnull)region;

- (void)PVLocationManager:(CLLocationManager *_Nonnull)manager monitoringDidFailForRegion:(CLRegion *_Nonnull)region withError:(NSError *_Nullable)error;

@end


@interface PVLocationManager : NSObject

+ (nonnull instancetype) manager;

@property (readonly) CLAuthorizationStatus authorizationStatus;
@property (readonly) CLLocation *_Nullable lastKnownLocation;

#pragma nark - Start/Stop Location Manager
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

#pragma mark - Request Authorization
- (void)requestAuthorization;

#pragma mark - Other Methods
- (void)presentUserDisabledGeolocationAlert;
- (BOOL)isLocationGranted;

#pragma mark - Add/Remove delegates
- (void)addDelegate:(nonnull id <PVLocationManagerDelegate>)delegate;
- (void)removeDelegate:(nonnull id)delegate;

#pragma mark - Register Coordinates for Geo-Fencing
- (void)registerRegionWithCoordinates:(CLLocationCoordinate2D)coordinate withRadius:(CLLocationDistance)regionRadius completitionHandler:(void(^_Nonnull)())completitionHandler;

@end
