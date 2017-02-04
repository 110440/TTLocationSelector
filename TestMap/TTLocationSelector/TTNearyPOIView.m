//
//  TTNearyPOIView.m
//  TestMap
//
//  Created by tanson on 2017/2/2.
//  Copyright © 2017年 chatchat. All rights reserved.
//

#import "TTNearyPOIView.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import "LLLocationManager.h"

const static NSString *allPOISearchTypes = @"汽车服务|汽车销售|汽车维修|摩托车服务|餐饮服务|购物服务|生活服务|体育休闲服务|医疗保健服务|住宿服务|风景名胜|商务住宅|政府机构及社会团体|科教文化服务|交通设施服务|金融保险服务|公司企业|道路附属设施|地名地址信息|公共设施";

@interface TTNearyPOIView ()<UITableViewDataSource,UITableViewDelegate,AMapSearchDelegate>

@property (nonatomic,strong) NSMutableArray<AMapPOI *> * poiData;

@property (nonatomic) AMapReGeocode *curReGeocode;
@property (nonatomic) AMapSearchAPI *mapSearch;
@property (nonatomic) AMapPOIAroundSearchRequest *poiRequest;
@property (nonatomic) AMapReGeocodeSearchRequest *regeoRequest;
@property (nonatomic) UIView * footView;

@end

@implementation TTNearyPOIView{
    NSInteger _curPage;
    BOOL _isMorePOIData;
    NSIndexPath * _curSelectPath;
    BOOL _isLoading;
    CGFloat _beginY;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if([super initWithFrame:frame style:UITableViewStylePlain]){
        self.dataSource = self;
        self.delegate = self;
        self.rowHeight = 50;
        _curPage = 1;
        _isMorePOIData = YES;
    }
    return self;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if([super initWithCoder:aDecoder]){
        self.dataSource = self;
        self.delegate = self;
        self.rowHeight = 50;
        _curPage = 1;
        _isMorePOIData = YES;
    }
    return self;
}

-(AMapSearchAPI *)mapSearch{
    if(!_mapSearch){
        _mapSearch = [[AMapSearchAPI alloc] init];
        _mapSearch.delegate = self;
    }
    return _mapSearch;
}

-(AMapPOIAroundSearchRequest *)poiRequest{
    if(!_poiRequest){
        _poiRequest = [[AMapPOIAroundSearchRequest alloc] init];
        _poiRequest.types = (NSString *)allPOISearchTypes;
        _poiRequest.sortrule = 1;
        _poiRequest.requireExtension = YES;
        _poiRequest.requireSubPOIs = NO;
        _poiRequest.radius = 5000;
        _poiRequest.page = 1;
        _poiRequest.offset = 20;
    }
    return _poiRequest;
}

-(AMapReGeocodeSearchRequest *)regeoRequest{
    if(!_regeoRequest){
        _regeoRequest = [[AMapReGeocodeSearchRequest alloc] init];
        _regeoRequest.radius = 3000;
        _regeoRequest.requireExtension = NO;
    }
    return _regeoRequest;
}

-(UIView *)footView{
    if(!_footView){
        _footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 44)];
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_footView addSubview:view];
        view.center = CGPointMake(self.bounds.size.width/2, 44/2);
        [view startAnimating];
    }
    return _footView;
}

-(void) reloadDataWithCoordinate:(CLLocationCoordinate2D)coordinate{
    
    self.poiData = @[].mutableCopy;
    self.tableFooterView = self.footView;
    [self reloadData];
    
    self.curReGeocode = nil;
    
    AMapGeoPoint *point = [AMapGeoPoint locationWithLatitude:coordinate.latitude  longitude:coordinate.longitude];
    _curPage = 1;
    
    self.poiRequest.location    = point;
    self.poiRequest.page        = _curPage;
    self.regeoRequest.location  = point;
    
    [self.mapSearch cancelAllRequests];
    [self.mapSearch AMapReGoecodeSearch:self.regeoRequest];
    [self.mapSearch AMapPOIAroundSearch:self.poiRequest];
    
}

//UITableView上拉刷新时，获取更多数据
- (void)fetchMorePOIData {
    if (_curPage == self.poiRequest.page) {
        self.poiRequest.page += 1;
        [self.mapSearch AMapPOIAroundSearch:self.poiRequest];
    }
}

- (NSString *)addressFromAMapPOI:(AMapPOI *)poi {
    NSString *address;
    if ([poi.city isEqualToString:poi.province]) {
        address = [NSString stringWithFormat:@"%@%@", poi.city, poi.address];
    }else {
        address = [NSString stringWithFormat:@"%@%@%@", poi.province, poi.city, poi.address];
    }
    
    return address;
}

-(TTLocationModel *)getSelectedLocation{
    TTLocationModel * model = [TTLocationModel new];
    
    if(_curSelectPath.row == 0){
        NSString * firstName;
        NSString * fullName;
        
        [[LLLocationManager sharedManager] getLocationNameAndAddressFromReGeocode:self.curReGeocode
                                                                             name:&firstName
                                                                          address:&fullName];
        model.firstName = firstName;
        model.fullName  = fullName;
    }else{
        AMapPOI * poi = self.poiData[_curSelectPath.row - 1];
        model.firstName = poi.name;
        model.fullName  = [self addressFromAMapPOI:poi];;
    }
    model.lat       = self.mapView.centerCoordinate.latitude;
    model.log       = self.mapView.centerCoordinate.longitude;
    return model;
}

#pragma mark- AMapSearchAPI delegate

////搜索发生错误时调用
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error {
    NSLog(@"%s: searchRequest = %@, errInfo= %@", __func__, [request class], error);
    _isLoading = NO;
}

////搜索成功回调
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response {
    _curPage = request.page;
    
    [self.poiData addObjectsFromArray:response.pois];
    if (response.pois.count < request.offset) {
        _isMorePOIData = NO;
    }else {
        _isMorePOIData = YES;
    }
    self.tableFooterView = nil;
    [self reloadData];
    _isLoading = NO;
}

////实现逆地理编码的回调函数
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response {
    self.curReGeocode = response.regeocode;
    _curSelectPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self reloadData];
}


#pragma mark- tableView delegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger poiDataCount = self.poiData.count;
    if(poiDataCount <=0) return 0;
    return poiDataCount + 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = self.curReGeocode.formattedAddress.length>0 ? self.curReGeocode.formattedAddress:@"[未知位置]";
        cell.detailTextLabel.text = nil;
    }else{
        AMapPOI * poi = self.poiData[indexPath.row - 1];
        cell.textLabel.text = poi.name;
        cell.detailTextLabel.text = [self addressFromAMapPOI:poi];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    if(_curSelectPath == indexPath) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.textLabel.text.length == 0 || [cell.textLabel.text isEqualToString:@"[未知位置]"])
        return;
    
    if (indexPath.row == 0) {
        if(self.itemSelectBlock){
            self.itemSelectBlock(kCLLocationCoordinate2DInvalid,indexPath.row);
        }
    }else {
        AMapPOI * poi = self.poiData[indexPath.row - 1];
        AMapGeoPoint * point = poi.location;
        CLLocationCoordinate2D coordinate2D = CLLocationCoordinate2DMake(point.latitude, point.longitude);
        if(self.itemSelectBlock){
            self.itemSelectBlock(coordinate2D,indexPath.row);
        }
    }
    
    if(_curSelectPath){
        UITableViewCell *selectcell = [tableView cellForRowAtIndexPath:_curSelectPath];
        if (selectcell) selectcell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    _curSelectPath = indexPath;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    _beginY = scrollView.contentOffset.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(_isLoading)return;
    
    CGFloat curY = scrollView.contentOffset.y;
    CGFloat d = _beginY - curY;
    if(d < -10 && scrollView.isDragging){
        _beginY = curY;
        self.viewScrollBlock(YES);
    }else if(d > 5 && scrollView.isDragging && !scrollView.isDecelerating){
        _beginY = curY;
        self.viewScrollBlock(NO);
    }
    
    //开始加载新的数据
    if ((scrollView.contentOffset.y + scrollView.frame.size.height + 20 >= scrollView.contentSize.height) && _isMorePOIData){
        _isLoading = YES;
        self.tableFooterView = self.footView;
        [self fetchMorePOIData];
    }
}

@end

@implementation TTLocationModel
-(NSString *)description{
    return [NSString stringWithFormat:@"%@ %@ lat:%f log:%f",self.firstName,self.fullName,self.lat,self.log];
}
@end
