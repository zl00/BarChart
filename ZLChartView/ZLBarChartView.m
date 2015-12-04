//
//  ZLBarChartView.m
//  ZLChartView
//
//  Created by 龚莎 on 15/12/4.
//  Copyright © 2015年 zl. All rights reserved.
//

#import "ZLBarChartView.h"
#import "ZLPopupView.h"

#include <HexColor.h>
#import <POP.h>

#define ZLAxisColor         [HXColor colorWithHexString:@"000000" alpha:0.54]
#define ZLSeparatorColor    [HXColor colorWithHexString:@"000000" alpha:0.12]
#define ZLBarChartViewSelectedColor [HXColor colorWithHexString:@"ffffff" alpha:0]

NSInteger   const kZLYAxisCoordinateNum             = 7;
NSInteger   const kZLXAxisCoordinateNum             = 7;
CGFloat     const kZLBarChartViewTopPadding         = 30.0f; //
CGFloat     const kZLBarChartViewBottomPadding      = 15.f; //
CGFloat     const kZLYAxisLabelHeight               = 10.0f; // y轴坐标高度
CGFloat     const kZLYAxisLabelWidth                = 30.f; // y轴坐标宽度
CGFloat     const kZLYAxisRightPadding              = 5.0f;  // y轴坐标右边边距
CGFloat     const kZLXAxisLabelHeight               = 10;  // x轴坐标高度
CGFloat     const kZLBarChartHistogramWidthRatio    = 0.08;  // 直方图宽度占整个view的宽度比例
CGFloat     const kZLHistogramCornerRatio           = 0.15f;  // 直方图圆角
CGFloat     const kZLSeparatorLineHeight            = 0.5f; // 分割线高度
CGFloat     const kZLAnimationDelayTime             = 0.07f; // 秒为单位
CGFloat     const kZLAxisAnimationDurationTime      = 0.15f; // 坐标动画时间
CGFloat     const kZLHistogramAnimationDurationTime = 0.3f; // 柱形图动画时间
CGFloat     const kLLLightMinAlphaValue             = 0.1f; // 光柱渐变色透明度
CGFloat     const kZLLightMaxAlphaValue             = 0.8f; // 光柱渐变色透明度
CGFloat     const kZLChartViewSwipDistance          = 60.f; // chartView滑动临界值
CGFloat     const kZLPopupViewHeight                = 20.f;
CGFloat     const kZLShowDataLabelHeight            = 20.f;

/**
 * @brief 直方图
 */
@interface ZLBarView : UIView
@end

/**
 * @brief 选中时会以当前直方图的颜色为底色的渐变色
 */
@interface ZLChartVerticalSelectionView : UIView
/**
 * @brief 渐变色
 */
@property (nonatomic) UIColor *bgColor;
@end

@interface ZLBarChartView()

#pragma mark - 设置的数据
@property (nonatomic) UIColor   *color; // 主色
@property (nonatomic) NSArray   *datas; // 数据
@property (nonatomic) NSArray   *dates; // 日期
@property (nonatomic) UIColor   *axisColor; // 坐标轴颜色
@property (nonatomic) UIColor   *separatorColor; // 分割线颜色
@property (nonatomic) CGFloat   histogramWidthRatio; // 柱状宽度/chartView的宽度
@property (nonatomic) UIFont    *xAxisFont; // x轴坐标字体
@property (nonatomic) UIFont    *yAxisFont; // y轴坐标字体
@property (nonatomic) UIFont    *showDataFont; // 点击后出现
@property (nonatomic) CGFloat   popupOpacity; //

#pragma mark - UI元素，重绘会移除
@property (nonatomic) NSMutableArray                *yAxisLblArray; // y轴坐标label数组
@property (nonatomic) NSMutableArray                *xAxisLblArray; // x轴坐标label数组
@property (nonatomic) NSMutableArray                *histogramArray; // 直方图数组
@property (nonatomic) NSMutableArray                *lightHistogramArray; // 光柱直方图数组
@property (nonatomic) NSMutableArray                *separatorLineArray; // 分割线数组
@property (nonatomic) NSMutableArray                *popUpViewArray; //点击事件会弹出的气泡
@property (nonatomic) NSMutableArray                *showDataLblArray; //

#pragma mark - 缓存位置数据，初始化后不会发生改变
@property (nonatomic) NSArray   *yAxisCoordinates; // y轴坐标
@property (nonatomic) NSArray   *xAxisCoordinates; // x轴坐标

#pragma mark - 手势
@property (nonatomic) BOOL      isTouched; // 是否触摸
@property (nonatomic) CGPoint   startTouchPoint; // 触摸开始位置
@property (nonatomic) UIView    *touchedView; //
@end

@implementation ZLBarChartView

#pragma mark - UIView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
}

- (void)setHiddenOfView:(UIView*)view hidden:(BOOL)hidden {
    
    if (hidden) {
        view.alpha = .02f;
    } else {
        view.alpha = 1.0f;
    }
}

- (BOOL)isHidden:(UIView*)view {
    
    if (view.alpha <= .02f) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - 外部调用接口

- (void)drawChart:(CGRect)rect
withHistogramColor:(UIColor *)histogramColor
         withData:(NSArray *)datas
        withDates:(NSArray *)dates
{
    if (!datas.count || !dates.count) {
        return;
    }
    self.frame = rect;
    [self setupAttr];
    if (histogramColor)
    {
        _color = histogramColor;
    }
    _datas = datas;
    _dates = dates;
    
    [self goOut];
    [self comeIn];
}

#pragma mark - 初始化

/**
 * @brief 设置缺省参数
 */
- (void)setupAttr
{
    _axisColor = ZLAxisColor;
    _separatorColor = ZLSeparatorColor;
    
    _xAxisFont = [UIFont fontWithName:@"STHeitiSC-Light" size:11.f];
    _yAxisFont = [UIFont fontWithName:@"Helvetica" size:11.f];
    _showDataFont = [UIFont fontWithName:@"Helvetica" size:14.f];
    
    
    _histogramWidthRatio = kZLBarChartHistogramWidthRatio;
    
    _xAxisCoordinates = [self calcXAxisCoordinates];
    _yAxisCoordinates = [self calcYAxisCoordinates];
    
    self.clipsToBounds = YES; // 子view超出部分被截断
}

/**
 * @brief 计算y周坐标位置
 */
- (NSArray *)calcYAxisCoordinates
{
    NSMutableArray *results = [NSMutableArray array];
    
    CGFloat yAxisAverageHeight = [self chartViewHeight]/(kZLYAxisCoordinateNum-1);
    for (int yIndex = kZLYAxisCoordinateNum-1; yIndex >= 0; --yIndex)
    {
        CGFloat yLabelCenter = [self chartViewTopPadding]+yIndex*yAxisAverageHeight;
        //        if (yIndex == (kLLYAxisCoordinateNum-1)) {
        //            yLabelCenter += kLLBarChartViewBottomPadding/2.f;
        //        }
        
        [results addObject:@(yLabelCenter)];
    }
    
    return results;
}

/**
 * @brief 计算x轴坐标位置
 */
- (NSArray *)calcXAxisCoordinates
{
    NSMutableArray *results = [NSMutableArray array];
    
    for (int xIndex = 0; xIndex < kZLXAxisCoordinateNum; ++xIndex)
    {
        CGFloat xLabelCenter = [self chartViewLeftPadding]+[self xAxisLabelWidth]/2.0f+xIndex*[self xAxisLabelWidth];
        [results addObject:@(xLabelCenter)];
    }
    
    return results;
}

#pragma mark - UI绘制包括动画

/**
 * @brief 退出动画，同时会删除掉UI资源
 */
- (void)goOut
{
    /// y轴坐标从右到左退出，顺序是从下到上依次退出
    [self erraseYCoordinates];
    
    /// x轴坐标从上到下退出，顺序是从左到右依次推出
    [self erraseXCoordinates];
    
    [self erraseView:_popUpViewArray];
    _popUpViewArray = nil;
    [self erraseView:_histogramArray];
    _histogramArray = nil;
    [self erraseView:_lightHistogramArray];
    _lightHistogramArray = nil;
}

/**
 * @brief 渐入动画，如果有残余的UI资源会事前清除再创建资源
 */
- (void)comeIn
{
    /// 分割线，没有动画
    [self drawSeparatorLines];
    
    /// y轴坐标从左到右进入，顺序是从下到上依次进入
    [self drawYCoordinates];
    
    /// x轴坐标从下到上进入，顺序是从左到右依次进入
    [self drawXCoordinates];
    
    /// 柱状图从下到上进入，顺序是从左到右依次进入
    [self drawHistogram];
    
    /// popupview
    [self drawPopupView];
}

/**
 * @brief 创建y轴坐标标签
 * @return 返回y轴坐标标签
 */
- (NSMutableArray *)createYAxisLblArray
{
    NSMutableArray *yAxisArr = [NSMutableArray array];
    
    NSArray *yAxisLblDespArr = [self createYAxisCoordinateDesp];
    for (int idx = 0; idx < yAxisLblDespArr.count; ++idx)
    {
        UILabel *yAxisLbl = [[UILabel alloc] init];
        /// 文字
        yAxisLbl.text = yAxisLblDespArr[idx];
        
        /// 位置大小
        CGRect rect;
        rect.origin.x = -[self yAxisCoordinateXOutDistance];
        rect.origin.y = [_yAxisCoordinates[idx] floatValue]-kZLYAxisLabelHeight/2.0f;
        rect.size.width = kZLYAxisLabelWidth;
        rect.size.height = kZLYAxisLabelHeight;
        yAxisLbl.frame = rect;
        
        ///
        [yAxisLbl setTextAlignment:NSTextAlignmentLeft];
        yAxisLbl.font = _yAxisFont;
        yAxisLbl.textColor = _axisColor;
        yAxisLbl.adjustsFontSizeToFitWidth = YES;
        
        [yAxisArr addObject:yAxisLbl];
    }
    
    return yAxisArr;
}


/**
 * @brief 创建x轴坐标标签
 * @return 返回x轴坐标标签
 */
- (NSMutableArray *)createXAxisLblArray
{
    NSMutableArray *xAxisArr = [NSMutableArray array];
    
    NSArray *xAxisLblDespArr = [self createXAxisCoordinateDesp];
    CGFloat xAxisLblWidth = [self xAxisLabelWidth];
    for (int idx = 0; idx < xAxisLblDespArr.count; ++idx)
    {
        UILabel *xAxisLbl = [[UILabel alloc] init];
        /// 文字
        xAxisLbl.text = xAxisLblDespArr[idx];
        
        /// 位置大小
        CGRect rect;
        rect.origin.x = [_xAxisCoordinates[idx] floatValue]-xAxisLblWidth/2.0f;
        rect.origin.y = self.frame.size.height;
        rect.size.height = kZLXAxisLabelHeight;
        rect.size.width = xAxisLblWidth;
        xAxisLbl.frame = rect;
        xAxisLbl.adjustsFontSizeToFitWidth = YES;
        
        ///
        [xAxisLbl setTextAlignment:NSTextAlignmentCenter];
        xAxisLbl.font = _xAxisFont;
        xAxisLbl.textColor = _axisColor;
        
        [xAxisArr addObject:xAxisLbl];
    }
    
    return xAxisArr;
}

/**
 * @brief 创建柱形图
 * @return 返回柱形图数组
 */
- (NSMutableArray *)createHistogramArray
{
    NSMutableArray *histogramArr = [NSMutableArray array];
    
    for (int idx = 0; idx < kZLXAxisCoordinateNum; ++idx)
    {
        ZLBarView *histogramV = [[ZLBarView alloc] init];
        
        CGRect rect;
        rect.origin.x = [_xAxisCoordinates[idx] floatValue]-[self histogramWidth]/2.0f;
        rect.origin.y = self.frame.size.height;
        rect.size.height = [self calcHistogramHeightWithData:[_datas[idx] floatValue]];
        rect.size.width = [self histogramWidth];
        histogramV.frame = rect;
        
        [histogramV.layer setCornerRadius:[self histogramWidth]*kZLHistogramCornerRatio];
        
        histogramV.backgroundColor = _color;
        histogramV.tag = idx;
        
        [histogramArr addObject:histogramV];
    }
    
    return histogramArr;
}

- (NSMutableArray*)createShowDataLblArray {
    
    NSMutableArray *showdataLbls = [NSMutableArray array];
    
    NSArray *histograms = [self createHistogramArray];
    float lightHistogramHeight = [self calcLightHistogreamHeight];
    for (UIView *histogram in histograms) {
        UILabel *lbl = [[UILabel alloc] init];
        lbl.backgroundColor = [UIColor clearColor];
        CGFloat originY = lightHistogramHeight-histogram.frame.size.height-kZLShowDataLabelHeight;
        if (originY < 0) {
            originY = 0;
        }
        lbl.frame = CGRectMake(0, originY, histogram.frame.size.width, kZLShowDataLabelHeight);
        lbl.font = self.showDataFont;
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = [UIColor whiteColor];
        lbl.adjustsFontSizeToFitWidth = YES;
        lbl.tag = [histograms indexOfObject:histogram];
        NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
        numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSString *valueStr = [numberFormatter stringFromNumber:
                              [NSNumber numberWithInteger:(int)[_datas[histogram.tag] floatValue]]];
        lbl.text = valueStr;
        [showdataLbls addObject:lbl];
    }
    return showdataLbls;
}

- (NSMutableArray*)createPopupArray {
    
    NSMutableArray *popupArr = [NSMutableArray array];
    
    for (int idx = 0; idx < kZLXAxisCoordinateNum; ++idx) {
        CGRect rect;
        rect.origin.x = [_xAxisCoordinates[idx] floatValue]-[self popupViewWidth]/2.0f;
        rect.origin.y = 0;
        rect.size.height = kZLPopupViewHeight;
        rect.size.width = [self popupViewWidth];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd"];
        NSString *dateStr = [dateFormatter stringFromDate:self.dates[idx]];
        ZLPopupView *popupView = [[ZLPopupView alloc] init];
        popupView.alpha = .0f;
        popupView.viewColor = self.color;
        popupView.arrowHeight = 5.f;
        popupView.backgroundColor = [UIColor clearColor];
        UILabel *lbltext = [[UILabel alloc] init];
        lbltext.text = dateStr;
        lbltext.font = self.showDataFont;
        lbltext.textColor = [UIColor whiteColor];
        lbltext.textAlignment = NSTextAlignmentCenter;
        [lbltext setFrame:CGRectMake(0, 0, rect.size.width, rect.size.height-popupView.arrowHeight)];
        [popupView addSubview:lbltext];
        [popupView setFrame:rect];
        [popupArr addObject:popupView];
    }
    return popupArr;
}

/**
 * @brief 创建光柱直方图
 * @return 光柱直方图数组
 */
- (NSMutableArray *)createLightHistogramArray
{
    NSMutableArray *lightHistogramArr = [NSMutableArray array];
    
    for (int idx = 0; idx < kZLXAxisCoordinateNum; ++idx)
    {
        ZLChartVerticalSelectionView *lightHistogramV = [[ZLChartVerticalSelectionView alloc] init];
        
        CGRect rect;
        rect.origin.x = [_xAxisCoordinates[idx] floatValue]-[self histogramWidth]/2.0f;
        rect.origin.y = [self chartViewTopPadding]-kZLPopupViewHeight;
        rect.size.height = [self calcLightHistogreamHeight];
        rect.size.width = [self histogramWidth];
        lightHistogramV.frame = rect;
        
        [lightHistogramV.layer setCornerRadius:[self histogramWidth]*kZLHistogramCornerRatio];
        
        lightHistogramV.bgColor = _color;
        lightHistogramV.tag = idx;
        [self setHiddenOfView:lightHistogramV hidden:YES];
        [lightHistogramArr addObject:lightHistogramV];
    }
    
    return lightHistogramArr;
}

/**
 * @brief 创建分割线
 * @return 返回分割线数组
 */
- (NSMutableArray *)createSeparatorLineArray
{
    NSMutableArray *separatorArr = [NSMutableArray array];
    
    for (int idx = 0; idx < _yAxisCoordinates.count; ++idx)
    {
        UIView *sepV = [[UIView alloc] init];
        
        /// 位置大小
        CGRect rect;
        rect.origin.x = [self chartViewLeftPadding];
        rect.origin.y = [_yAxisCoordinates[idx] floatValue];
        //        rect.size.width = (idx == 0 ? 0 : kLLSeparatorLineWidth);
        rect.size.width = (idx == 0 ? 0 : [self chartViewWidth]);
        rect.size.height = kZLSeparatorLineHeight;
        sepV.frame = rect;
        
        sepV.backgroundColor = _separatorColor;
        
        [separatorArr addObject:sepV];
    }
    
    return separatorArr;
}


- (void)drawSeparatorLines
{
    if (_separatorLineArray)
    {
        return ;
    }
    _separatorLineArray = [self createSeparatorLineArray];
    for (UIView *sV in _separatorLineArray)
    {
        [self addSubview:sV];
    }
}

- (void)drawYCoordinates
{
    if (_yAxisLblArray)
    {
        for (UILabel *yLbl in _yAxisLblArray)
        {
            [yLbl removeFromSuperview];
        }
        [_yAxisLblArray removeAllObjects];
    }
    _yAxisLblArray = [self createYAxisLblArray];
    for (UILabel *yLbl in _yAxisLblArray)
    {
        [self addSubview:yLbl];
    }
    
    for(NSInteger i = 0;i < [_yAxisLblArray count];i++)
    {
        UILabel *label = [_yAxisLblArray objectAtIndex:i];
        CGFloat delayTime = kZLAnimationDelayTime*(i+1);
        __weak typeof(self) weakSelf = self;
        label.alpha = 0.f;
        [UIView animateWithDuration:kZLAxisAnimationDurationTime delay:delayTime options:UIViewAnimationOptionTransitionNone animations:^{
            label.transform = CGAffineTransformTranslate(label.transform, [weakSelf yAxisCoordinateXOutDistance], 0);
            label.alpha = 1.0f;
        } completion:nil];
    }
}

- (void)drawXCoordinates
{
    if (_xAxisLblArray)
    {
        for (UILabel *lbl in _xAxisLblArray)
        {
            [lbl removeFromSuperview];
        }
        [_xAxisLblArray removeAllObjects];
    }
    _xAxisLblArray = [self createXAxisLblArray];
    for (UILabel *lbl in _xAxisLblArray)
    {
        [self addSubview:lbl];
    }
    
    for(NSInteger i = 0;i < [_xAxisLblArray count];i++)
    {
        UILabel *label = [_xAxisLblArray objectAtIndex:i];
        CGFloat delayTime = kZLAnimationDelayTime*(i+1);
        __weak typeof(self) weakSelf = self;
        label.alpha = 0.f;
        [UIView animateWithDuration:kZLAxisAnimationDurationTime delay:delayTime options:UIViewAnimationOptionTransitionNone animations:^{
            label.alpha = 1.f;
            label.transform = CGAffineTransformTranslate(label.transform, 0, -[weakSelf xAxisCoordinateYOutDistance]);
        } completion:nil];
    }
}

- (void)drawPopupView {
    
    if (_popUpViewArray) {
        return ;
    }
    _popUpViewArray = [self createPopupArray];
    for (UIView* v in _popUpViewArray) {
        [self addSubview:v];
    }
}

- (void)drawLightHistogram
{
    if (_lightHistogramArray)
    {
        return ;
    }
    _lightHistogramArray = [self createLightHistogramArray];
    for (UIView *v in _lightHistogramArray)
    {
        [self addSubview:v];
    }
    _showDataLblArray = [self createShowDataLblArray];
    for (int idx = 0; idx < _showDataLblArray.count; ++idx) {
        [_lightHistogramArray[idx] addSubview:_showDataLblArray[idx]];
    }
}

- (void)drawHistogram
{
    [self drawLightHistogram];
    
    if (_histogramArray)
    {
        for (UIView *v in _histogramArray)
        {
            [v removeFromSuperview];
        }
        [_histogramArray removeAllObjects];
    }
    _histogramArray = [self createHistogramArray];
    
    for (int idx = 0; idx < kZLXAxisCoordinateNum; ++idx)
    {
        [self addSubview:_histogramArray[idx]];
    }
    
    for (NSInteger i = 0; i < _histogramArray.count; ++i)
    {
        UIView *v = [_histogramArray objectAtIndex:i];
        CGFloat delayTime = kZLAnimationDelayTime*(i+1);
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:kZLHistogramAnimationDurationTime delay:delayTime options:UIViewAnimationOptionTransitionNone animations:^{
            v.transform = CGAffineTransformTranslate(v.transform, 0, -v.frame.size.height-[weakSelf chartViewButtomPadding]);
        } completion:nil];
    }
}

- (void)erraseYCoordinates
{
    if (_yAxisLblArray)
    {
        for (NSInteger i = 0;i < [_yAxisLblArray count];i++)
        {
            UILabel *label = [_yAxisLblArray objectAtIndex:i];
            CGFloat delayTime = kZLAnimationDelayTime*(i+1);
            __weak typeof(self) weakSelf = self;
            label.alpha = 1.f;
            [UIView animateWithDuration:kZLAxisAnimationDurationTime delay:delayTime options:UIViewAnimationOptionTransitionNone animations:^{
                label.alpha = 0.f;
                label.transform = CGAffineTransformTranslate(label.transform, [weakSelf yAxisCoordinateXEraseDistance], 0);
            } completion:^(BOOL finished) {
                [label removeFromSuperview];
            }];
            
        }
        [_yAxisLblArray removeAllObjects];
        _yAxisLblArray = nil;
    }
}

- (void)erraseXCoordinates
{
    if (_xAxisLblArray)
    {
        for (NSInteger i = 0; i < [_xAxisLblArray count]; i++)
        {
            UILabel *lbl = [_xAxisLblArray objectAtIndex:i];
            CGFloat delayTime = 0;//kLLAnimationDelayTime*(i+1);
            __weak typeof(self) weakSelf = self;
            lbl.alpha = 1.f;
            [UIView animateWithDuration:kZLAxisAnimationDurationTime delay:delayTime options:UIViewAnimationOptionTransitionNone animations:^{
                lbl.alpha = 0.f;
                lbl.transform = CGAffineTransformTranslate(lbl.transform, [weakSelf xAxisCoordinateYEraseDistance], 0);
            } completion:^(BOOL finished) {
                [lbl removeFromSuperview];
            }];
        }
        [_xAxisLblArray removeAllObjects];
        _xAxisLblArray = nil;
    }
}

- (void)erraseView:(NSArray*)views {
    for (UIView *v in views) {
        [v removeFromSuperview];
    }
}

#pragma mark - 数据

- (CGFloat)calcLightHistogreamHeight {
    
    //    return [self chartViewHeight]-kLLHistogramCornerRatio*[self histogramWidth];
    return [self chartViewHeight]+kZLPopupViewHeight;
}


- (CGFloat)calcHistogramHeightWithData:(CGFloat)data
{
    CGFloat maxV = [self maxValue];
    if (maxV <= 0.0f)
    {
        return 0.0f;
    }
    
    CGFloat result = data/maxV*[self chartViewHeight];
    return result > [self chartViewHeight] ? [self chartViewHeight] : result;
}

- (CGFloat)maxValue
{
    if (self.max > 0.0f) {
        return self.max;
    }
    
    CGFloat result = -.0f;
    for (int idx = 0; idx < _datas.count; ++idx)
    {
        if (result < [_datas[idx] floatValue])
        {
            result = [_datas[idx] floatValue];
        }
    }
    
    return result;
}

/**
 * @brief 创建x轴坐标文字描述
 */
- (NSArray *)createXAxisCoordinateDesp
{
    return @[@"一",@"二",@"三",@"四",@"五",@"六",@"日"];
}

/**
 * @brief 创建y轴坐标文字描述
 */
- (NSArray *)createYAxisCoordinateDesp
{
    NSMutableArray *results = [NSMutableArray arrayWithArray:@[@"0",@"0",@"0",@"0",@"0",@"0",@"0"]];
    
    CGFloat minV = 0;
    CGFloat maxV = ((NSInteger)([self maxValue]+9))/10*10;
    CGFloat gap = (maxV-minV)/(kZLYAxisCoordinateNum-1);
    
    for (int index = 0; index < kZLYAxisCoordinateNum; ++index)
    {
        results[index] = [NSString stringWithFormat:@"%d", (int)(minV+index*gap)];
    }
    
    return results;
}

#pragma mark - 最基础的计算

- (CGFloat)histogramWidth
{
    return self.frame.size.width*_histogramWidthRatio;
}

- (CGFloat)popupViewWidth {
    return [self histogramWidth]*2;
}

/**
 * @brief y轴坐标出现时，x轴方向移动距离
 */
- (CGFloat)yAxisCoordinateXOutDistance
{
    return kZLYAxisLabelWidth;
}

/**
 * @brief x轴坐标出现时，y轴方向移动距离
 */
- (CGFloat)xAxisCoordinateYOutDistance
{
    return kZLYAxisLabelHeight;
}

- (CGFloat)yAxisCoordinateXEraseDistance
{
    return -[self yAxisCoordinateXOutDistance]-10.0f;
}

- (CGFloat)xAxisCoordinateYEraseDistance
{
    return -[self xAxisCoordinateYOutDistance]-10.0f;
}


- (CGFloat)chartViewTopPadding
{
    return kZLBarChartViewTopPadding;
}

- (CGFloat)chartViewButtomPadding
{
    //    CGFloat yAxisBottomPadding = kLLXAxisLabelHeight; // y轴距离frame下边距
    return kZLBarChartViewBottomPadding;
}

- (CGFloat)chartViewLeftPadding
{
    CGFloat xAxisLeftPadding = kZLYAxisLabelWidth+kZLYAxisRightPadding; // x轴距离frame左边距
    return xAxisLeftPadding;
}

- (CGFloat)chartViewRightPadding
{
    return 0.0f;
}

- (CGFloat)chartViewHeight
{
    return self.frame.size.height-[self chartViewButtomPadding]-[self chartViewTopPadding];
}

- (CGFloat)chartViewWidth
{
    return self.frame.size.width-[self chartViewLeftPadding]-[self chartViewRightPadding];
}

- (CGFloat)xAxisLabelWidth
{
    CGFloat result = [self chartViewWidth]/kZLXAxisCoordinateNum;
    return result;
}

#pragma mark - 根据index创建UI元素

/**
 * @brief 根据下标得到Bar
 */
- (UIView *)createBarWithIndex:(NSInteger)index
{
    if (index < 0 || index >= _datas.count
        || index >= _xAxisCoordinates.count)
    {
        return nil;
    }
    
    UIView *barView = [[UIView alloc] init];
    CGRect rect;
    
    /// origin.x
    CGFloat xCenter = [_xAxisCoordinates[index] floatValue];
    rect.origin.x = [self chartViewLeftPadding]+xCenter-[self histogramWidth]/2.0f;
    /// size.width
    rect.size.width = [self histogramWidth];
    /// size.height
    CGFloat data = [_datas[index] floatValue];
    CGFloat maxValue = [self maxValue];
    if ([self maxValue])
    {
        NSLog(@"%s:%d Inner error.", __func__, __LINE__);
        return nil;
    }
    rect.size.height = data/maxValue*[self chartViewHeight];
    /// origin.y
    rect.origin.y = [self chartViewTopPadding]+[self chartViewHeight]-rect.size.height;
    
    barView.frame = rect;
    barView.tag = index;
    
    barView.backgroundColor = _color;
    
    return barView;
}


- (UILabel *)createYAxisCoordinate:(NSInteger)index
{
    if (index < 0 || index >= _yAxisCoordinates.count)
    {
        return nil;
    }
    
    UILabel *yAxisCoordinateLbl = [[UILabel alloc] init];
    
    CGRect rect;
    rect.origin.x = 0.0f;
    rect.origin.y = [_yAxisCoordinates[index] floatValue]-kZLYAxisLabelHeight/2.0f;
    rect.size.width = kZLYAxisLabelWidth;
    rect.size.height = kZLYAxisLabelHeight;
    
    yAxisCoordinateLbl.frame = rect;
    yAxisCoordinateLbl.text = [self createYAxisCoordinateDesp][index];
    yAxisCoordinateLbl.font = _yAxisFont;
    [yAxisCoordinateLbl setTextAlignment:NSTextAlignmentRight];
    yAxisCoordinateLbl.adjustsFontSizeToFitWidth = YES;
    
    return yAxisCoordinateLbl;
}

- (UILabel *)createXAxisCoordinate:(NSInteger)index
{
    if (index < 0 || index >= _xAxisCoordinates.count)
    {
        return nil;
    }
    
    UILabel *xAxisCoordinateLbl = [[UILabel alloc] init];
    CGRect rect;
    rect.origin.x = [_xAxisCoordinates[index] floatValue]-[self histogramWidth]/2.0f;
    rect.origin.y = self.frame.size.height-kZLXAxisLabelHeight;
    rect.size.height = kZLXAxisLabelHeight;
    rect.size.width = [self xAxisLabelWidth];
    
    xAxisCoordinateLbl.frame = rect;
    xAxisCoordinateLbl.text = [self createXAxisCoordinateDesp][index];
    xAxisCoordinateLbl.font = _xAxisFont;
    [xAxisCoordinateLbl setTextAlignment:NSTextAlignmentCenter];
    xAxisCoordinateLbl.adjustsFontSizeToFitWidth = YES;
    
    return xAxisCoordinateLbl;
}

- (UIView *)createSeparatorLine:(NSInteger)index
{
    if (index < 0 || index >= _yAxisCoordinates.count)
    {
        return nil;
    }
    
    UIView *separatorV = [[UIView alloc] init];
    
    CGRect rect;
    rect.origin.x = 0.0f;
    rect.origin.y = [_yAxisCoordinates[index] floatValue]-kZLYAxisLabelHeight/2.0f;
    rect.size.width = [self chartViewWidth];
    rect.size.height = kZLSeparatorLineHeight;
    
    separatorV.frame = rect;
    separatorV.backgroundColor = _separatorColor;
    
    return separatorV;
}

#pragma mark - 手势

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_isTouched)
    {
        return;
    }
    _isTouched = YES;
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    _startTouchPoint = touchPoint;
    UIView *subview = [self hitTest:touchPoint withEvent:nil];
    self.touchedView = subview;
    [self touchPoint:subview];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    
    [self touchPoint:self.touchedView];
    if (touchPoint.x - _startTouchPoint.x > kZLChartViewSwipDistance)
    {
        if ([self.delegate respondsToSelector:@selector(didChangeToLeft)])
        {
            [self.delegate didChangeToLeft];
        }
    }
    else if(touchPoint.x - _startTouchPoint.x < -kZLChartViewSwipDistance)
    {
        if ([self.delegate respondsToSelector:@selector(didChangeToRight)])
        {
            [self.delegate didChangeToRight];
        }
    }
    self.touchedView = nil;
    _isTouched = NO;
    [super touchesEnded:touches withEvent:event];
}

- (void)touchPoint:(UIView *)touchView
{
    if ([touchView isKindOfClass:[ZLBarView class]]
        || [touchView isKindOfClass:[ZLChartVerticalSelectionView class]])
    {
        NSInteger tag = touchView.tag;
        
        BOOL lastHidden = [self isHidden:[_lightHistogramArray objectAtIndex:tag]];
        [self setHiddenOfView:[_lightHistogramArray objectAtIndex:tag] hidden:!lastHidden];
        
        if (lastHidden)
        {
            touchView.opaque = 1.f;
            [self showAnimated:[_popUpViewArray objectAtIndex:tag] andFromY:[self chartViewHeight] andToY:kZLPopupViewHeight];
        } else
        {
            touchView.opaque = 0.f;
            [self hideAnimated:[_popUpViewArray objectAtIndex:tag]];
        }
    }
}

- (void)showAnimated:(UIView*)view andFromY:(float)fromY andToY:(float)toY
{
    
    [CATransaction begin]; {
        
        POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPositionY];
        positionAnimation.velocity = @2000;
        positionAnimation.springBounciness = 5;
        positionAnimation.springSpeed = 20;
        positionAnimation.fromValue = @(fromY);
        positionAnimation.toValue = @(toY);
        [positionAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
            view.bounds = CGRectMake(view.bounds.origin.x, view.bounds.origin.y, view.bounds.size.width, view.bounds.size.height);
        }];
        [view.layer pop_addAnimation:positionAnimation forKey:@"positionAnimation"];
        
        POPBasicAnimation *opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
        opacityAnimation.duration = 0.2f;
        opacityAnimation.fromValue = @(.0f);
        opacityAnimation.toValue = @(1.f);
        [opacityAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
            view.alpha = 1.0;
        }];
        [view.layer pop_addAnimation:opacityAnimation forKey:@"opacity"];
    } [CATransaction commit];
}

- (void)hideAnimated:(UIView*)view
{
    [CATransaction begin]; {
        
        POPBasicAnimation *opacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
        opacityAnimation.property = [POPAnimatableProperty propertyWithName:kPOPLayerOpacity];
        opacityAnimation.fromValue = @(1.f);
        opacityAnimation.toValue = @(0.f);
        [opacityAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
            view.alpha = 0.f;
        }];
        [view.layer pop_addAnimation:opacityAnimation forKey:@"opacity"];
    } [CATransaction commit];
}

- (void)shutDownAllLight
{
    for (int i = 0; i < kZLXAxisCoordinateNum; ++i)
    {
        [self setHiddenOfView:[_lightHistogramArray objectAtIndex:i] hidden:YES];
    }
}
@end

@implementation ZLChartVerticalSelectionView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - drawing

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, rect);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = nil;
    
    if (self.bgColor != nil)
    {
        colors = @[(__bridge id)[self.bgColor colorWithAlphaComponent:kZLLightMaxAlphaValue].CGColor, (__bridge id)[self.bgColor colorWithAlphaComponent:kLLLightMinAlphaValue].CGColor];
    }
    else
    {
        colors = @[(__bridge id)ZLBarChartViewSelectedColor.CGColor, (__bridge id)[ZLBarChartViewSelectedColor colorWithAlphaComponent:0.0].CGColor];
    }
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    
    CGContextSaveGState(context);
    {
        CGContextAddRect(context, rect);
        CGContextClip(context);
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    }
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

#pragma mark - Setters

- (void)setBgColor:(UIColor *)color
{
    _bgColor = color;
    [self setNeedsDisplay];
}

@end

@implementation ZLBarView


@end
