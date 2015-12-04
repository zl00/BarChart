//
//  UIColor+Custom.m
//  ZLChartView
//
//  Created by 龚莎 on 15/12/4.
//  Copyright © 2015年 zl. All rights reserved.
//

#import "UIColor+Custom.h"

#import <HexColor.h>

@implementation UIColor (Custom)

+ (UIColor*)CustomRedColor {
    return [HXColor colorWithHexString:@"f86763"];
}

+ (UIColor*)CustomBlueColor {
    return [HXColor colorWithHexString:@"36c7d9"];
}
@end
