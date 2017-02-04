//
//  TTGaoDeMapViewController.m
//  TestMap
//
//  Created by tanson on 2017/2/4.
//  Copyright © 2017年 chatchat. All rights reserved.
//

#import "TTGaoDeMapViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "LLLocationManager.h"

@interface TTGaoDeMapViewController () <MAMapViewDelegate,UIGestureRecognizerDelegate,CLLocationManagerDelegate>

@property (strong,nonatomic) CLLocationManager * locationMgr;
@property (weak, nonatomic) IBOutlet MAMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UILabel *fullNameLab;

@end

@implementation TTGaoDeMapViewController{
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupMap];
    [self checkAuthorization];

    NSArray<UIGestureRecognizer *> *gestureRecognizers = self.mapView.subviews[0].gestureRecognizers;
    for (UIGestureRecognizer *gestureRecognizer in gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:NSClassFromString(@"UIScrollViewPanGestureRecognizer")]) {
            [gestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
            break;
        }
    }
    
    // set model
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.model.lat, self.model.log);
    [self.mapView setZoomLevel:17 animated:NO];
    [self.mapView setCenterCoordinate:coordinate animated:NO];
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate = coordinate;
    [self.mapView addAnnotation:pointAnnotation];
    self.nameLab.text = self.model.firstName;
    self.fullNameLab.text = self.model.fullName;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self endUpdatingLocation];
}

#pragma mark- action

- (IBAction)onBack:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onMore:(id)sender{
}

- (IBAction)onSharedButton:(id)sender {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.model.lat, self.model.log);
    [[LLLocationManager sharedManager] navigationFromCurrentLocationToLocationUsingAppleMap:coordinate
                                                                            destinationName:self.model.fullName];
}

#pragma mark- private

-(CLLocationManager *)locationMgr{
    if(!_locationMgr){
        _locationMgr = [CLLocationManager new];
        _locationMgr.delegate = self;
    }
    return _locationMgr;
}

-(void) setupMap{
    self.mapView.delegate = self;
    self.mapView.mapType = MAMapTypeStandard;
    self.mapView.language = MAMapLanguageZhCN;
    self.mapView.zoomEnabled = YES;
    self.mapView.minZoomLevel = 4;
    self.mapView.maxZoomLevel = 19;
    self.mapView.scrollEnabled = YES;
    self.mapView.showsCompass = NO;
    self.mapView.showsScale = YES;
    self.mapView.distanceFilter = 10;
    self.mapView.desiredAccuracy = kCLLocationAccuracyBest;
    
    self.mapView.logoCenter = CGPointMake([UIScreen mainScreen].bounds.size.width - 3 - _mapView.logoSize.width/2, CGRectGetHeight(self.mapView.frame) - 3 - _mapView.logoSize.height/2);
    self.mapView.scaleOrigin = CGPointMake(12, CGRectGetHeight(_mapView.frame) - 25);
}

-(void) startUpdatingLocation{
    self.mapView.distanceFilter = 10;
    self.mapView.desiredAccuracy = kCLLocationAccuracyBest;
    self.mapView.userTrackingMode = MAUserTrackingModeFollow;
    self.mapView.showsUserLocation = YES;
}

-(void) endUpdatingLocation{
    self.mapView.userTrackingMode = MAUserTrackingModeNone;
    self.mapView.showsUserLocation = NO;
    self.mapView.delegate = nil;
}

#pragma mark- 权限

- (void)checkAuthorization {
    if (![CLLocationManager locationServicesEnabled]) {
        [self promptNoAuthorizationAlert];
    }else {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        switch (status) {
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusRestricted:
                [self promptNoAuthorizationAlert];
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                [self startUpdatingLocation];
                break;
            case kCLAuthorizationStatusNotDetermined:
                [self.locationMgr requestWhenInUseAuthorization];
                break;
        }
    }
    
}

- (void)locationManager:(CLLocationManager *)locationManager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            [self promptNoAuthorizationAlert];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startUpdatingLocation];
            break;
        case kCLAuthorizationStatusNotDetermined:
            [self.locationMgr requestWhenInUseAuthorization];
            break;
    }
}
- (void)promptNoAuthorizationAlert {
    NSLog(@"有没权限");
}

#pragma mark- mapView delegate

- (MAAnnotationView*)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {
    
    MAAnnotationView *annotationView;
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        annotationView = [[MAAnnotationView alloc] init];
        annotationView.annotation = annotation;
        annotationView.image = [UIImage imageNamed:@"located_pin"];
        annotationView.enabled = NO;
        annotationView.draggable = NO;
        annotationView.bounds = CGRectMake(0, 0, 18, 38);
        annotationView.layer.anchorPoint = CGPointMake(0.5, 0.96);
        
    }
    return annotationView;
}

#pragma mark- UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:NSClassFromString(@"UIScreenEdgePanGestureRecognizer")]) {
        return YES;
    }
    return NO;
}


@end
