//
//  ViewController.m
//  ZLChartView
//
//  Created by 龚莎 on 15/12/4.
//  Copyright © 2015年 zl. All rights reserved.
//

#import "ViewController.h"
#import "ZLBarChartView.h"
#import "UIColor+Custom.h"

#import <HexColor.h>

@interface ViewController ()<ZLBarChartViewDelegate>

@property (weak, nonatomic) IBOutlet ZLBarChartView *barChartView;

@property (nonatomic) NSArray * datas;
@property (nonatomic) NSArray * dates;
@property (nonatomic) NSInteger startIndex;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self mockDatas];
    self.barChartView.delegate = self;
    [self.barChartView setMax:20];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self drawBarChart:self.startIndex];
}

- (void)mockDatas {
    NSMutableArray * datas = [NSMutableArray array];
    NSMutableArray * dates = [NSMutableArray array];
    for (int i = 0; i < 14; ++i) {
        NSDate * date = [NSDate date];
        [dates addObject:date];
        [datas addObject:@(i)];
    }
    self.datas = datas;
    self.dates = dates;
}

- (void)drawBarChart:(NSInteger)fromIndex {
    self.startIndex = fromIndex;
    NSMutableArray * tmpDatas = [NSMutableArray array];
    NSMutableArray * tmpDates = [NSMutableArray array];
    for (int i = (int)self.startIndex; i < (self.startIndex+7); ++i) {
        [tmpDatas addObject:self.datas[i]];
        [tmpDates addObject:self.dates[i]];
    }
    [self.barChartView drawChart:self.barChartView.frame
              withHistogramColor:[UIColor CustomBlueColor]
                        withData:tmpDatas
                       withDates:tmpDates];
}

#pragma mark - ZLBarChartViewDelegate
- (void)didChangeToLeft {
    NSInteger startIndex = self.startIndex - 7;
    if (startIndex < 0) {
        return ;
    }
    [self drawBarChart:startIndex];
}

- (void)didChangeToRight {
    NSInteger startIndex = self.startIndex + 7;
    if (startIndex >= self.dates.count) {
        return;
    }
    [self drawBarChart:startIndex];
}
@end
