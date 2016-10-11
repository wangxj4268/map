//
//  NextViewController.m
//  newMap
//
//  Created by zkml on 16/8/23.
//  Copyright © 2016年 zkml-wxj. All rights reserved.
//

#import "NextViewController.h"
#import "JSONKit.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>

// 运动结点信息类
@interface BMKSportNode : NSObject
//经纬度
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
//方向（角度）
@property (nonatomic, assign) CGFloat angle;
//距离
@property (nonatomic, assign) CGFloat distance;
//速度
@property (nonatomic, assign) CGFloat speed;
@end

@implementation BMKSportNode
@synthesize coordinate = _coordinate;
@synthesize angle = _angle;
@synthesize distance = _distance;
@synthesize speed = _speed;
@end


// 自定义BMKAnnotationView，用于显示运动者
@interface SportAnnotationView : BMKAnnotationView
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation SportAnnotationView
@synthesize imageView = _imageView;
- (id)initWithAnnotation:(id<BMKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setBounds:CGRectMake(0.f, 0.f, 22.f, 22.f)];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 22.f, 22.f)];
        _imageView.image = [UIImage imageNamed:@"scrImage2.png"];
        [self addSubview:_imageView];
    }
    return self;
}
@end


@interface NextViewController ()<BMKMapViewDelegate>
{
    //画矩形采用
    BMKPolygon *pathPloygon;
    //画线
    BMKPolyline *polyline;
    BMKPointAnnotation *sportAnnotation;
    SportAnnotationView *sportAnnotationView;
    
    NSMutableArray *sportNodes;//轨迹点
    NSInteger sportNodeNum;//轨迹点数
    NSInteger currentIndex;//当前结点
}
@property(nonatomic,copy)BMKMapView *mapView;
@end

@implementation NextViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    //适配ios7
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0)) {
        self.navigationController.navigationBar.translucent = NO;
    }
    
    _mapView = [[BMKMapView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:_mapView];

    _mapView.zoomLevel = 19.4;
    _mapView.centerCoordinate = CLLocationCoordinate2DMake(40.056898, 116.307626);
    _mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
    
    //初始化轨迹点
    [self initSportNodes];
    

    UIBarButtonItem *item1 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(pauseLayer:)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(item2Click)];
    
    self.navigationItem.rightBarButtonItems = @[item1,item2];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_mapView viewWillAppear];
    _mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_mapView viewWillDisappear];
    _mapView.delegate = nil; // 不用时，置nil
}

- (void)dealloc {
    if (_mapView) {
        _mapView = nil;
    }
}

//初始化轨迹点
- (void)initSportNodes {
    sportNodes = [[NSMutableArray alloc] init];
    //读取数据
    NSData *jsonData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sport_path" ofType:@"json"]];
    if (jsonData) {
        NSArray *array = [jsonData objectFromJSONData];
        for (NSDictionary *dic in array) {
            BMKSportNode *sportNode = [[BMKSportNode alloc] init];
            sportNode.coordinate = CLLocationCoordinate2DMake([dic[@"lat"] doubleValue], [dic[@"lon"] doubleValue]);
            sportNode.angle = [dic[@"angle"] doubleValue];
            sportNode.distance = [dic[@"distance"] doubleValue];
            sportNode.speed = [dic[@"speed"] doubleValue];
            [sportNodes addObject:sportNode];
        }
    }
    //sportNodeNum:轨迹点数
    sportNodeNum = sportNodes.count;
 
}

//开始
- (void)start {
    CLLocationCoordinate2D paths[sportNodeNum];
    for (NSInteger i = 0; i < sportNodeNum; i++) {
        BMKSportNode *node = sportNodes[i];
        //存的是经纬度
        paths[i] = node.coordinate;
    }
    
    //根据多个点 生成多边形框
//    pathPloygon = [BMKPolygon polygonWithCoordinates:paths count:sportNodeNum];
//    [_mapView addOverlay:pathPloygon];
    
    //根据多个点  画折线
    polyline = [BMKPolyline polylineWithCoordinates:(CLLocationCoordinate2D *)paths count: (NSUInteger)sportNodeNum];
    
    [_mapView addOverlay:polyline];
    ///表示一个点的annotation
    sportAnnotation = [[BMKPointAnnotation alloc]init];
    sportAnnotation.coordinate = paths[0];
    sportAnnotation.title = @"test";
    //向地图窗口添加标注
    [_mapView addAnnotation:sportAnnotation];
    currentIndex = 0;
}




//runing
- (void)running {
    //运动节点
    BMKSportNode *node = [sportNodes objectAtIndex:currentIndex % sportNodeNum]; //达到循环效果
    //箭头的方向
    sportAnnotationView.imageView.transform = CGAffineTransformMakeRotation(node.angle);
    //动画
    [UIView animateWithDuration:node.distance/node.speed animations:^{
        currentIndex++;
        BMKSportNode *node = [sportNodes objectAtIndex:currentIndex % sportNodeNum];
        sportAnnotation.coordinate = node.coordinate;
    } completion:^(BOOL finished) {   //completion：是动画完成以后所要执行的代码块儿
        //只写else语句则代表无线循环
        if (currentIndex ==sportNodeNum-1 ) {
            
        }else{
           [self running];
            NSLog(@"第%ld 执行完了额",currentIndex);
        }
        
    }];
}

#pragma mark - BMKMapViewDelegate

- (void)mapViewDidFinishLoading:(BMKMapView *)mapView {
    [self start];
}

//根据overlay生成对应的View
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id <BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]])
    {
        //画矩形用下面的代码
//        BMKPolygonView* polygonView = [[BMKPolygonView alloc] initWithOverlay:overlay];
//        polygonView.strokeColor = [[UIColor alloc] initWithRed:0.0 green:0.5 blue:0.0 alpha:0.6];
//        polygonView.lineWidth = 3.0;
//        return polygonView;
        
        //画线用下面的代码
        BMKPolylineView *polylineView = [[BMKPolylineView alloc]initWithPolyline:overlay];
        polylineView.strokeColor = [[UIColor greenColor]colorWithAlphaComponent:1];
        polylineView.lineWidth = 5.0;
        return polylineView;
    }
    return nil;
}




// 根据anntation生成对应的View
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    if (sportAnnotationView == nil) {
        sportAnnotationView = [[SportAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"sportsAnnotation"];
        
        
        sportAnnotationView.draggable = NO;
        BMKSportNode *node = [sportNodes firstObject];
        sportAnnotationView.imageView.transform = CGAffineTransformMakeRotation(node.angle);
        
    }
    return sportAnnotationView;
}

//当mapView新添加annotation views时，调用此接口
- (void)mapView:(BMKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    [self running];
}


//暂停
-(void)item1Click{


}
//播放
-(void)item2Click{

}

-(void)pauseLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}


-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
