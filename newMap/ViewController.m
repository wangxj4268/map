//
//  ViewController.m
//  newMap
//
//  Created by zkml on 16/8/23.
//  Copyright © 2016年 zkml-wxj. All rights reserved.
//

#import "ViewController.h"
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import "NextViewController.h"
@interface ViewController ()<BMKMapViewDelegate, BMKLocationServiceDelegate>
/** 记录上一次的位置 */
@property (nonatomic, strong) CLLocation *preLocation;

/** 位置数组 */
@property (nonatomic, strong) NSMutableArray *locationArrayM;

/** 轨迹线 */
@property (nonatomic, strong) BMKPolyline *polyLine;

/** 百度地图View */
@property (nonatomic,strong) BMKMapView *mapView;

/** 百度定位地图服务 */
@property (nonatomic, strong) BMKLocationService *LocationService;
@end

@implementation ViewController
-(void)viewWillAppear:(BOOL)animated
{
    [_mapView viewWillAppear];
    _mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
    _LocationService.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [_mapView viewWillDisappear];
    _mapView.delegate = nil; // 不用时，置nil
    _LocationService.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 初始化地图窗口
    _mapView = [[BMKMapView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:_mapView];
    
    // 初始化位置百度位置服务
    _LocationService = [[BMKLocationService alloc] init];
    [_LocationService startUserLocationService];
    
    // 显示定位图层
    _mapView.showsUserLocation = NO;
    
    // 设置定位模式
    _mapView.userTrackingMode = BMKUserTrackingModeFollow;
    
    _mapView.showsUserLocation = YES;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(btnClick)];
    self.navigationItem.rightBarButtonItem=item;
}


// *  用户位置更新后，会调用此函数
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
//    NSLog(@"位置更新");
//    NSLog(@"*****%@",userLocation.location);
    // 如果此时位置更新的水平精准度大于10米，直接返回该方法
    // 可以用来简单判断GPS的信号强度
    if (userLocation.location.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters) {
        return;
    }
      [_mapView updateLocationData:userLocation];
   
}

// *  用户方向更新后，会调用此函数
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
//    NSLog(@"方向改变");
    NSLog(@"----%@",userLocation.location);
    // 动态更新我的位置数据
    [_mapView updateLocationData:userLocation];
  
}

-(void)willStartLocatingUser{
    NSLog(@"开始定位");
}

// *  定位失败会调用该方法
- (void)didFailToLocateUserWithError:(NSError *)error
{
    NSLog(@"did failed locate,error is %@",[error localizedDescription]);
}

-(void)btnClick{
    NextViewController *next = [[NextViewController alloc]init];
    [self.navigationController pushViewController:next animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
