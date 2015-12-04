//
//  ZLBarChartView.h
//  ZLChartView
//
//  Created by 龚莎 on 15/12/4.
//  Copyright © 2015年 zl. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * @brief 柱状图向左或者右swip事件
 */
@protocol ZLBarChartViewDelegate <NSObject>

@optional
- (void)didChangeToLeft;
- (void)didChangeToRight;

@end

/**
 * @brief 提供柱形图
 *
 * 动画 x轴和y轴坐标从左侧进入，柱形图从下往上
 *
 * 事件 选中直方图，左右滑动
 */
@interface ZLBarChartView : UIView

@property (nonatomic) CGFloat max;
@property (weak, nonatomic) id<ZLBarChartViewDelegate> delegate;

/**
 * @brief 绘制barChart
 *
 * @param rect 绘制区域
 * @param histogramColor 直方图颜色，如果是nil则使用默认的颜色
 * @param datas 数据
 * @param dates 日期
 */
- (void)drawChart:(CGRect)rect
withHistogramColor:(UIColor *)histogramColor
         withData:(NSArray *)datas
        withDates:(NSArray*)dates;


@end
