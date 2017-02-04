//
//  TTNearyPOIView.h
//  TestMap
//
//  Created by tanson on 2017/2/2.
//  Copyright © 2017年 chatchat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import <MAMapKit/MAMapKit.h>

typedef void (^TTNearyPOIViewSelectItemHandel)(CLLocationCoordinate2D coordinate2D,NSInteger row);
typedef void (^TTNearyPOIViewScrollHandel)(BOOL moveUp);


@interface TTLocationModel : NSObject

@property (nonatomic,copy) NSString * firstName;
@property (nonatomic,copy) NSString * fullName;
@property (nonatomic,assign) CGFloat lat;
@property (nonatomic,assign) CGFloat log;
@property (nonatomic,strong) UIImage * snapshot;

@end


#pragma mark- TTNearyPOIView

@interface TTNearyPOIView : UITableView

@property (nonatomic,copy) TTNearyPOIViewSelectItemHandel itemSelectBlock;
@property (nonatomic,copy) TTNearyPOIViewScrollHandel viewScrollBlock;
@property (nonatomic,weak) MAMapView * mapView;

-(void) reloadDataWithCoordinate:(CLLocationCoordinate2D)coordinate;
-(TTLocationModel*) getSelectedLocation;

@end
