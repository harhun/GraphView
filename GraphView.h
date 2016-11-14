//
//  GraphView.h
//  GraphView
//
//  Created by Harhun on 12.05.16.
//  Copyright © 2016 Harhun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GraphInterval.h"

@interface AVISleepGraphViewAxisConfig : NSObject

@property (atomic) CGFloat marginLeftPx;
@property (atomic) CGFloat marginBottomPx;
@property (atomic) CGFloat marginRightPx;
@property (atomic) CGFloat marginTopPx;
@property (atomic) CGFloat zeroOffsetXPx;
@property (atomic) CGFloat zeroOffsetYPx;
@property (atomic) CGFloat widthXPx;
@property (atomic) CGFloat widthYPx;
@property (nonnull, nonatomic, strong) UIColor *colorX;
@property (nonnull, nonatomic, strong) UIColor *colorY;
@property (nonnull, nonatomic, strong) NSDictionary<NSString *, id> *textAttributesX;
@property (nonnull, nonatomic, strong) NSDictionary<NSString *, id> *textAttributesY;

@end

@interface AVISleepGraphViewViewportConfig : NSObject

@property (atomic) CGRect viewport;

@end

@interface AVISleepViewGridConfig : NSObject

@property (atomic) CGFloat marginLeftPx;
@property (atomic) CGFloat marginBottomPx;
@property (atomic) CGFloat marginRightPx;
@property (atomic) CGFloat marginTopPx;
@property (atomic) CGFloat widthXPx;
@property (atomic) CGFloat widthYPx;
@property (nonnull, nonatomic, strong) UIColor *colorX;
@property (nonnull, nonatomic, strong) UIColor *colorY;
@property (nullable, nonatomic, strong) NSArray<NSNumber *> *dashesX;
@property (nullable, nonatomic, strong) NSArray<NSNumber *> *dashesY;
@property (atomic) CGFloat paddingTextX;
@property (atomic) CGFloat paddingTextY;

@end

@interface AVISleepViewDataViewConfig : NSObject

@property (nonnull, nonatomic, strong) UIColor *shallowColor;
@property (nonnull, nonatomic, strong) UIColor *deepColor;
@property (nonnull, nonatomic, strong) UIColor *wakeColor;

@end

@interface AVISleepGraphDataModel : NSObject

/*
 location - pisition times on minutes, example: 1.41 it is 60+41=101 minuts. 
            If you have different days, that second day it is summ previous day(24 hours = 1440) and current day of minuts.
 length - it is number of minuts, how many people spent
 */

@property (nonatomic, assign, readonly) NSRange sleepRange;
@property (nonatomic, assign, readonly) AVISleepIntervalType sleepType;

- (_Nonnull instancetype)initWithSleepType:(AVISleepIntervalType)sleepType sleepRange:(NSRange)sleepRange;

@end


@class AVISleepGraphView;

@protocol AVISleepGraphViewDataSource <NSObject>
@required
- (NSArray<AVISleepGraphDataModel *>* _Nonnull)getDataGraphView:(nonnull AVISleepGraphView *)graphView;

@end

@protocol AVISleepGraphViewViewDelegate <NSObject>
@optional
- (void)graphView:(nonnull AVISleepGraphView *)graphView didSelectValueX:(CGFloat)valueX;

@end


@interface AVISleepGraphView : UIView

@property (nonnull, nonatomic, strong) AVISleepGraphViewAxisConfig *axisConfig;
@property (nonnull, nonatomic, strong) AVISleepGraphViewViewportConfig *viewportConfig;
@property (nonnull, nonatomic, strong) AVISleepViewGridConfig *gridConfig;
@property (nonnull, nonatomic, strong) AVISleepViewDataViewConfig *dataViewConfig;

@property (nullable, nonatomic, weak) IBOutlet id<AVISleepGraphViewDataSource> dataSource;
@property (nullable, nonatomic, weak) IBOutlet id<AVISleepGraphViewViewDelegate> delegate;

- (void)reloadData;

@end
