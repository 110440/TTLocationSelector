//
//  TTLocationSelectController.m
//  TestMap
//
//  Created by tanson on 2017/2/2.
//  Copyright © 2017年 chatchat. All rights reserved.
//

#import "TTLocationSelectController.h"
#import "TTNearyPOIView.h"
#import <CoreLocation/CoreLocation.h>

#define maxMapH 300
#define minMapH 120

@interface TTLocationSelectController () <MAMapViewDelegate,CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MAMapView *mapView;
@property (weak, nonatomic) IBOutlet TTNearyPOIView *poiTableView;
@property (weak, nonatomic) IBOutlet UIImageView *pinImageView;
@property (strong,nonatomic) CLLocationManager * locationMgr;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapHeightConstraint;

@end

@implementation TTLocationSelectController{
    CLLocation *_lastSelectedLocation;
    BOOL _hasInitRegion;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _locationMgr = [CLLocationManager new];
    _locationMgr.delegate = self;
    _pinImageView.layer.anchorPoint = CGPointMake(0.5, 1);
    
    _poiTableView.mapView = self.mapView;
    _poiTableView.itemSelectBlock = ^(CLLocationCoordinate2D coordinate2D,NSInteger row){
        if(row==0){
            [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate  animated:YES];
            [self.poiTableView reloadDataWithCoordinate:self.mapView.userLocation.location.coordinate];
        }else{
            [self.mapView setCenterCoordinate:coordinate2D  animated:YES];
        }
    };
    _poiTableView.viewScrollBlock = ^(BOOL moveup){
        CGFloat h = 0;
        if(moveup){
            h = minMapH;
        }else{
            h = maxMapH;
        }
        [UIView animateWithDuration:0.3 animations:^{
            self.mapHeightConstraint.constant = h;
            [self.view layoutIfNeeded];
        }];
    };
    
    UIBarButtonItem * rightItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStylePlain target:self action:@selector(onSend)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    [self setupMap];
    [self checkAuthorization];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self endUpdatingLocation];
}

-(void) onSend{
    [self endUpdatingLocation];
    
    //TODO: // 位置截图
    TTLocationModel * m = [self.poiTableView getSelectedLocation];
    self.sendBlock? self.sendBlock(m):nil;
    [self.navigationController popViewControllerAnimated:YES];
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
    
    self.mapHeightConstraint.constant = maxMapH;
    self.mapView.logoCenter = CGPointMake([UIScreen mainScreen].bounds.size.width - 3 - _mapView.logoSize.width/2, CGRectGetHeight(self.mapView.frame) - 3 - _mapView.logoSize.height/2);
    self.mapView.scaleOrigin = CGPointMake(12, CGRectGetHeight(_mapView.frame) - 25);
}

- (IBAction)onMylocationButton:(id)sender {
    [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate  animated:YES];
    [self.poiTableView reloadDataWithCoordinate:self.mapView.userLocation.location.coordinate];
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

#pragma mark- MAMapView delegate


- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    NSLog(@"regionDidChange animated:%@", animated? @"YES":@"NO");
    
    CLLocationCoordinate2D coordinate2D = [self.mapView convertPoint:self.mapView.center toCoordinateFromView:self.mapView];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate2D.latitude longitude:coordinate2D.longitude];
    if (!_lastSelectedLocation) {
        _lastSelectedLocation = self.mapView.userLocation.location;
    }
    CLLocationDistance distance = [_lastSelectedLocation distanceFromLocation:location];
    
    if (distance >= 100) {
        _lastSelectedLocation = location;
        if (!animated) {
            [self.poiTableView reloadDataWithCoordinate:self.mapView.centerCoordinate];
        }
    }
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    if (!updatingLocation)return;
    
    if (!_hasInitRegion) {
        _hasInitRegion = YES;
        CLLocationDistance span = [UIScreen mainScreen].bounds.size.width * 1.2;
        MACoordinateRegion theRegion = MACoordinateRegionMakeWithDistance(userLocation.location.coordinate, span, span);
        [self.mapView setRegion:theRegion];
        [self.poiTableView reloadDataWithCoordinate:self.mapView.centerCoordinate];
    }
    //水平精度偏差大于500米，则不采取这个数据
    //    if (userLocation.location.horizontalAccuracy < 0 || userLocation.location.horizontalAccuracy > 500)
    //        return;
}

- (void)mapView:(MAMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

#pragma mark - 权限管理

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

@end
