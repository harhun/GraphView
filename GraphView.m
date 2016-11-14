//
//  GraphView.m
//  GraphView
//
//  Created by Harhun on 12.05.16.
//  Copyright © 2016 Harhun. All rights reserved.
//

#import "GraphView.h"

const NSInteger SlEEP_HEIGHT_GRAPH = 3; //4 steps it is 3 lines

const NSInteger SlEEP_WIDTH_GRAPH = 1440; // 1 day, it is default value

const NSInteger SlEEP_Y_SPACE_GRAPH = 180; // 3 hours

const CGFloat START_POS_SELECTED_LINE = -5.0f;

@interface AVISleepGraphView() <UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSArray<AVISleepGraphDataModel *>* dataArray;
@property (nonnull, nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

// selected value
@property (atomic) CGFloat selectedValueX;

@end

@interface AVISleepGraphDataModel()

@property (nonatomic, assign, readwrite) NSRange sleepRange;
@property (nonatomic, assign, readwrite) AVISleepIntervalType sleepType;

@end

#pragma mark -- Implementations



@implementation AVISleepGraphDataModel

- (instancetype)initWithSleepType:(AVISleepIntervalType)sleepType sleepRange:(NSRange)sleepRange {
    self = [super init];
    if (self) {
        self.sleepType = sleepType;
        self.sleepRange = sleepRange;
    }
    return self;
}

@end

@implementation AVISleepGraphViewAxisConfig
@end

@implementation AVISleepGraphViewViewportConfig
@end

@implementation AVISleepViewGridConfig
@end

@implementation AVISleepViewDataViewConfig
@end

@implementation AVISleepGraphView

#pragma mark -- Initialization

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self realInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self realInit];
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self realInit];
    }
    return self;
}

- (void)realInit {
    // default config
    _axisConfig = [AVISleepGraphViewAxisConfig new];
    
    _axisConfig.marginLeftPx = 16;
    _axisConfig.marginBottomPx = 0;
    _axisConfig.marginRightPx = 0;
    _axisConfig.marginTopPx = 16;
    
    _axisConfig.zeroOffsetXPx = 16;
    _axisConfig.zeroOffsetYPx = 16;
    
    _axisConfig.widthXPx = 0.5f;
    _axisConfig.widthYPx = 0.5f;
    
    _axisConfig.colorX = [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0];
    _axisConfig.colorY = [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0];
    
    _axisConfig.textAttributesX = @{NSFontAttributeName: [UIFont fontWithName:@"ProximaNova-Light" size:12],
                                    NSForegroundColorAttributeName: [[UIColor blackColor] colorWithAlphaComponent:0.5]};
    _axisConfig.textAttributesY = @{NSFontAttributeName: [UIFont fontWithName:@"ProximaNova-Light" size:8],
                                    NSForegroundColorAttributeName: [[UIColor blackColor] colorWithAlphaComponent:0.5]};
    
    
    _viewportConfig = [AVISleepGraphViewViewportConfig new];
    _viewportConfig.viewport = CGRectMake(0, 0, SlEEP_WIDTH_GRAPH, SlEEP_HEIGHT_GRAPH);
    
    _gridConfig = [AVISleepViewGridConfig new];
    _gridConfig.marginLeftPx = 16;
    _gridConfig.marginBottomPx = 16;
    _gridConfig.marginRightPx = 0;
    _gridConfig.marginTopPx = 0;
    _gridConfig.widthXPx = 1.0f;
    _gridConfig.widthYPx = 0.5f;
    _gridConfig.colorX = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    _gridConfig.colorY = [[UIColor blackColor] colorWithAlphaComponent:0.1];
    _gridConfig.dashesX = @[@(1.5), @(2)];
    _gridConfig.dashesY = nil;
    _gridConfig.paddingTextX = 2;
    _gridConfig.paddingTextY = 2;
    
    _dataViewConfig = [AVISleepViewDataViewConfig new];
    _dataViewConfig.shallowColor = [UIColor colorWithRed:192/255.0 green:196/255.0 blue:250/255.0 alpha:1.0];
    _dataViewConfig.deepColor = [UIColor colorWithRed:132/255.0 green:140/255.0 blue:249/255.0 alpha:1.0];
    _dataViewConfig.wakeColor = [UIColor colorWithRed:235/255.0 green:236/255.0 blue:255/255.0 alpha:1.0];
    
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longPressGestureRecognizer];
    
    _selectedValueX = START_POS_SELECTED_LINE;
}

#pragma mark -- Reload Data

- (void)reloadData {
    _selectedValueX = START_POS_SELECTED_LINE;
    [self setNeedsDisplay];
}

#pragma mark -- Primitive drawing

// reverse Y axis
- (void)drawAbsLineInContext:(CGContextRef)context
                       width:(CGFloat)width
                       color:(UIColor *)color
                       fromX:(CGFloat)fromX
                       fromY:(CGFloat)fromY
                         toX:(CGFloat)toX
                         toY:(CGFloat)toY
                      dashes:(nullable NSArray<NSNumber *> *)dashes {
    static CGFloat *dashPattern = NULL;
    static size_t dashPatternLength = 0;
    static CGPoint points[2];
    
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, width);
    points[0] = CGPointMake(fromX, fromY);
    points[1] = CGPointMake(toX, toY);
    if (dashes != nil) {
        if (dashPatternLength < dashes.count) {
            free(dashPattern);
            dashPattern = malloc(sizeof(CGFloat) * dashes.count);
            dashPatternLength = dashes.count;
        }
        for (size_t i = 0; i < dashes.count; ++i) {
            dashPattern[i] = dashes[i].floatValue;
        }
        CGContextSetLineDash(context, 0, dashPattern, dashPatternLength);
    } else {
        CGContextSetLineDash(context, 0, NULL, 0);
    }
    CGContextStrokeLineSegments(context, points, 2);
}


#pragma mark -- Drawing

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    [self drawGridInContext:context];
    [self drawDataInContext:context];
    [self drawGridLabelsInContext:context];
    [self drawAxisInContext:context];
    [self drawSelectedLineInContext:context];
}

- (void)drawAbsLineInContext:(CGContextRef)context
                       width:(CGFloat)width
                       color:(UIColor *)color
                       fromX:(CGFloat)fromX
                       fromY:(CGFloat)fromY
                         toX:(CGFloat)toX
                         toY:(CGFloat)toY {
    
    [self drawAbsLineInContext:context
                         width:width
                         color:color
                         fromX:fromX
                         fromY:fromY
                           toX:toX
                           toY:toY
                        dashes:nil];
}

- (void)drawSelectedLineInContext:(CGContextRef)context {
    CGContextSaveGState(context);
    CGContextClipToRect(context, self.gridDrawingRect);
    
    CGFloat absX = [self localXToAbs:self.selectedValueX];
    
    [self drawAbsLineInContext:context
                         width:1.0
                         color:[UIColor redColor]
                         fromX:absX
                         fromY:_axisConfig.marginBottomPx
                           toX:absX
                           toY:(self.bounds.size.height - _axisConfig.marginTopPx)];
    
    CGContextRestoreGState(context);
}

#pragma mark -- Calculation

- (CGRect)gridDrawingRect {
    return CGRectMake(_gridConfig.marginLeftPx,
                      _gridConfig.marginTopPx,
                      self.bounds.size.width - _gridConfig.marginLeftPx - _gridConfig.marginRightPx,
                      self.bounds.size.height - _gridConfig.marginTopPx - _gridConfig.marginBottomPx);
}

- (CGPoint)absPointToLocal:(CGPoint)absPoint {
    return CGPointMake([self absXToLocal:absPoint.x], [self absYToLocal:absPoint.y]);
}

- (CGFloat)absXToLocal:(CGFloat)absX {
    return (absX - _axisConfig.zeroOffsetXPx) * _viewportConfig.viewport.size.width / self.gridDrawingRect.size.width + _viewportConfig.viewport.origin.x;
}
- (CGFloat)absYToLocal:(CGFloat)absY {
    return ((self.bounds.size.height - absY) - _axisConfig.zeroOffsetYPx) * _viewportConfig.viewport.size.height / self.gridDrawingRect.size.height + _viewportConfig.viewport.origin.y;
}

- (CGFloat)localXToAbs:(CGFloat)localX {
    return (localX  * self.gridDrawingRect.size.width / _viewportConfig.viewport.size.width) + _axisConfig.zeroOffsetXPx;
}

- (CGFloat)localWidthToAbs:(CGFloat)localX {
    return (localX  * self.gridDrawingRect.size.width / _viewportConfig.viewport.size.width);
}

- (CGFloat)localYToAbs:(CGFloat)localY {
    return self.bounds.size.height - ((localY * self.gridDrawingRect.size.height / _viewportConfig.viewport.size.height) + _axisConfig.zeroOffsetYPx);
}

- (CGPoint)localPointToAbs:(CGPoint)localPoint {
    return CGPointMake([self localXToAbs:localPoint.x], [self localYToAbs:localPoint.y]);
}

- (CGRect)localRectToAbs:(CGRect)localRect {
    CGPoint minPoint = [self localPointToAbs:CGPointMake(CGRectGetMinX(localRect), CGRectGetMaxY(localRect))];
    CGPoint maxPoint = [self localPointToAbs:CGPointMake(CGRectGetMaxX(localRect), CGRectGetMinY(localRect))];
    return CGRectMake(minPoint.x, minPoint.y, maxPoint.x - minPoint.x, maxPoint.y - minPoint.y);
}

#pragma mark - Draw Grid

- (void)drawDataInContext:(CGContextRef)context {
    [self drawDataInContext:context
                      alpha:1.f];
}

- (void)drawAxisInContext:(CGContextRef)context {
    [self drawAbsLineInContext:context
                         width:_axisConfig.widthXPx
                         color:_axisConfig.colorX
                         fromX:_axisConfig.marginLeftPx
                         fromY:(roundf(self.bounds.size.height - _axisConfig.zeroOffsetYPx) + _axisConfig.widthXPx / 2)
                           toX:(self.bounds.size.width - _axisConfig.marginRightPx)
                           toY:(roundf(self.bounds.size.height - _axisConfig.zeroOffsetYPx) + _axisConfig.widthXPx / 2)];
    
    [self drawAbsLineInContext:context
                         width:_axisConfig.widthYPx
                         color:_axisConfig.colorY
                         fromX:(roundf(_axisConfig.zeroOffsetXPx) + _axisConfig.widthYPx / 2)
                         fromY:_axisConfig.marginBottomPx
                           toX:(roundf(_axisConfig.zeroOffsetXPx) + _axisConfig.widthYPx / 2) toY:(self.bounds.size.height - _axisConfig.marginTopPx)];
}

- (void)drawGridInContext:(CGContextRef)context {
    [self drawGridInContext:context
                      alpha:1.f];
}

- (void)drawGridLabelsInContext:(CGContextRef)context {
    [self drawGridLabelsAndIconsInContext:context
                                    alpha:1];
}

- (void)drawDataInContext:(CGContextRef)context alpha:(CGFloat)alpha {
    if (self.dataSource != nil && [self.dataSource respondsToSelector:@selector(getDataGraphView:)]) {
        
//        NSArray* dataArray = [self.dataSource getDataGraphView:self];
//        [self saveAndSortData:dataArray];
        
        CGContextSaveGState(context);
        CGRect clipRect = [self localRectToAbs:_viewportConfig.viewport];
        clipRect = CGRectInset(clipRect, -0.5f, -0.5f);
        clipRect = CGRectIntersection(clipRect, self.gridDrawingRect);
        CGContextClipToRect(context, clipRect);
        CGContextSetAlpha(context, alpha);

        for (AVISleepGraphDataModel* data in self.dataArray) {
            
            CGFloat x = [self localXToAbs:(float)data.sleepRange.location-self.dataArray.firstObject.sleepRange.location];
            CGFloat width = [self localWidthToAbs:(float)data.sleepRange.length] + 0.25;
            
            CGFloat y = [self localYToAbs:0.5+data.sleepType];
         
            UIColor *color;
            switch (data.sleepType) {
                case AVISleepIntervalShallow:
                    color = _dataViewConfig.shallowColor;
                    break;
                case AVISleepIntervalDeep:
                    color = _dataViewConfig.deepColor;
                    break;
                case AVISleepIntervalActive:
                    color = _dataViewConfig.wakeColor;
                    break;
                
                default:
                    break;
            }

            
            [self drawAbsLineInContext:context
                                 width:width
                                 color:color
                                 fromX:x+width/2
                                 fromY:y+_gridConfig.widthYPx/2
                                   toX:x+width/2
                                   toY:self.gridDrawingRect.size.height];
        }
        
        CGContextRestoreGState(context);
        
    }
}

- (void)drawGridInContext:(CGContextRef)context alpha:(CGFloat)alpha {
    
    if (self.dataSource != nil && [self.dataSource respondsToSelector:@selector(getDataGraphView:)]) {
        NSArray* dataArray = [self.dataSource getDataGraphView:self];
        
        [self saveAndSortData:dataArray];
        
        CGContextSaveGState(context);
        CGRect clipRect = [self localRectToAbs:_viewportConfig.viewport];
        clipRect = CGRectInset(clipRect, -0.5f, -0.5f);
        clipRect = CGRectIntersection(clipRect, self.gridDrawingRect);
        CGContextClipToRect(context, clipRect);
        CGContextSetAlpha(context, alpha);
        
        //y axis
        
        for (int i = 0; i < SlEEP_HEIGHT_GRAPH; i++) {
            
            CGFloat y = [self localYToAbs:0.5+i];
            CGFloat const roundY = roundf(y) + _gridConfig.widthYPx / 2;
            
            UIColor *color = _gridConfig.colorX;
            
            [self drawAbsLineInContext:context
                                 width:_gridConfig.widthYPx
                                 color:color
                                 fromX:_gridConfig.marginLeftPx
                                 fromY:roundY
                                   toX:(self.frame.size.width - _gridConfig.marginRightPx)
                                   toY:roundY
                                dashes:_gridConfig.dashesY];
        }
        
        //x axis
     
        NSInteger length = self.dataArray.lastObject.sleepRange.location + self.dataArray.lastObject.sleepRange.length;
    
        for (int i = (int)self.dataArray.firstObject.sleepRange.location/SlEEP_Y_SPACE_GRAPH; i <= length/SlEEP_Y_SPACE_GRAPH; i++) {

            CGFloat x = [self localXToAbs:(float)length-i*SlEEP_Y_SPACE_GRAPH];
            
            CGFloat const roundX = roundf(x) + _gridConfig.widthXPx / 2;

            UIColor *color = _gridConfig.colorX;
    
            [self drawAbsLineInContext:context
                                 width:_gridConfig.widthXPx
                                 color:color
                                 fromX:roundX
                                 fromY:_axisConfig.marginBottomPx
                                   toX:roundX
                                   toY:(self.frame.size.height - _axisConfig.marginTopPx)
                                dashes:_gridConfig.dashesX];
        }
    }
    
    CGContextRestoreGState(context);
}

- (void)drawGridLabelsAndIconsInContext:(CGContextRef)context alpha:(CGFloat)alpha {
    
    
    if (self.dataSource != nil && [self.dataSource respondsToSelector:@selector(getDataGraphView:)]) {
        CGContextSaveGState(context);
        CGContextSetAlpha(context, alpha);
        
//        NSArray* dataArray = [self.dataSource getDataGraphView:self];
//        [self saveAndSortData:dataArray];
        
        //y icons
        for (int i = 0; i < SlEEP_HEIGHT_GRAPH; i++) {
            
            CGFloat y = [self localYToAbs:0.5+i];
            CGFloat roundY = roundf(y) + _gridConfig.widthYPx / 2 + _gridConfig.marginLeftPx/4;
            roundY -= _gridConfig.marginLeftPx/2;

            switch (i) {
                case AVISleepIntervalDeep: {
                    AVIDeepSleepIcon *si = [[AVIDeepSleepIcon alloc] initWithFrame:CGRectMake(0, roundY, _gridConfig.marginLeftPx, _gridConfig.marginLeftPx)];
                    [si drawRect:CGRectMake(0, roundY, _gridConfig.marginLeftPx, _gridConfig.marginLeftPx)];
                    break;
                }
                case AVISleepIntervalShallow: {
                    AVIShallowSleepIcon *si = [[AVIShallowSleepIcon alloc] initWithFrame:CGRectMake(0, roundY, _gridConfig.marginLeftPx, _gridConfig.marginLeftPx)];
                    [si drawRect:CGRectMake(0, roundY, _gridConfig.marginLeftPx, _gridConfig.marginLeftPx)];
                    break;
                }
                case AVISleepIntervalActive: {
                    AVIAwakeSleepIcon *si = [[AVIAwakeSleepIcon alloc] initWithFrame:CGRectMake(0, roundY, _gridConfig.marginLeftPx, _gridConfig.marginLeftPx)];
                    [si drawRect:CGRectMake(0, roundY, _gridConfig.marginLeftPx, _gridConfig.marginLeftPx)];
                    
                    break;
                }
                default:
                    break;
            }
        }
        
        //x time of begin & end
        NSDictionary *attributes = _axisConfig.textAttributesX;
        

        CGFloat xBegin = [self localXToAbs:0.f];
        CGFloat const roundXBegin = roundf(xBegin) + _gridConfig.widthXPx / 2;

        NSInteger minutsBegin = self.dataArray.firstObject.sleepRange.location - SlEEP_WIDTH_GRAPH*(self.dataArray.firstObject.sleepRange.location/SlEEP_WIDTH_GRAPH);

        NSString *axisStringBegin = [NSString stringWithFormat:@"%ld:%02ld",minutsBegin/60, minutsBegin-((minutsBegin/60)*60)]; //60 minuts in hour
        
        CGSize axisStringSizeBegin = [axisStringBegin sizeWithAttributes:attributes];
        CGFloat axisStringXPxBegin = roundXBegin - axisStringSizeBegin.width / 2;
        
        CGPoint axisStringPosBegin = CGPointMake(axisStringXPxBegin, (self.frame.size.height - _axisConfig.zeroOffsetYPx + _gridConfig.paddingTextX));
        [axisStringBegin drawAtPoint:axisStringPosBegin withAttributes:attributes];
        
        
        
        CGFloat xLast = [self localXToAbs:_viewportConfig.viewport.size.width];
        CGFloat const roundXLast = roundf(xLast) + _gridConfig.widthXPx / 2;
        
        NSInteger minutsLast = self.dataArray.lastObject.sleepRange.location + self.dataArray.lastObject.sleepRange.length -
                                SlEEP_WIDTH_GRAPH*((self.dataArray.lastObject.sleepRange.location + self.dataArray.lastObject.sleepRange.length)/SlEEP_WIDTH_GRAPH);

        NSString *axisStringLast = [NSString stringWithFormat:@"%ld:%02ld",minutsLast/60, minutsLast-((minutsLast/60)*60)]; //60 minuts in hour
        
        CGSize axisStringSizeLast = [axisStringLast sizeWithAttributes:attributes];
        CGFloat axisStringXPxLast = roundXLast - axisStringSizeLast.width;
        
        CGPoint axisStringPosLast = CGPointMake(axisStringXPxLast, (self.frame.size.height - _axisConfig.zeroOffsetYPx + _gridConfig.paddingTextX));
        [axisStringLast drawAtPoint:axisStringPosLast withAttributes:attributes];
        
        //x labels
        
        NSInteger length = self.dataArray.lastObject.sleepRange.location + self.dataArray.lastObject.sleepRange.length;
        
        for (int i = (int)length/SlEEP_Y_SPACE_GRAPH; i > (int)self.dataArray.firstObject.sleepRange.location/SlEEP_Y_SPACE_GRAPH; i--) {
            
            CGFloat x = [self localXToAbs:(float)length-i*SlEEP_Y_SPACE_GRAPH];
            CGFloat const roundX = roundf(x) + _gridConfig.widthXPx / 2;
            
            NSString *axisString = [NSString stringWithFormat:@"%ld", ((i%(24/SlEEP_HEIGHT_GRAPH))*SlEEP_Y_SPACE_GRAPH)/60]; //60 minuts in hour
            NSDictionary *attributes = _axisConfig.textAttributesX;
            
            CGSize axisStringSize = [axisString sizeWithAttributes:attributes];
            CGFloat axisStringXPx = roundX - axisStringSize.width / 2;
            
            CGPoint axisStringPos = CGPointMake(axisStringXPx, (self.frame.size.height - _axisConfig.zeroOffsetYPx + _gridConfig.paddingTextX));

            if ((axisStringPos.x+axisStringSize.width) < axisStringPosLast.x && axisStringPos.x > (axisStringPosBegin.x+axisStringSizeBegin.width)) {
                [axisString drawAtPoint:axisStringPos withAttributes:attributes];
            }
        }
    }
    
    CGContextRestoreGState(context);
}

- (void)saveAndSortData:(NSArray*)data {
    NSComparisonResult (^sortBlock)(AVISleepGraphDataModel *, AVISleepGraphDataModel *) = ^(AVISleepGraphDataModel* obj1, AVISleepGraphDataModel* obj2) {
        if (obj1.sleepRange.location > obj2.sleepRange.location) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        if (obj1.sleepRange.location <= obj2.sleepRange.location) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    };
    
    self.dataArray = [data sortedArrayUsingComparator:sortBlock];
    
    _viewportConfig.viewport = CGRectMake(0,
                                          0,
                                          
                                          self.dataArray.lastObject.sleepRange.location +
                                          self.dataArray.lastObject.sleepRange.length -
                                          self.dataArray.firstObject.sleepRange.location + 1,
                                          
                                          SlEEP_HEIGHT_GRAPH);
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan
        || sender.state == UIGestureRecognizerStateChanged) {
        CGPoint absPoint = [sender locationInView:self];
        CGPoint localPoint = [self absPointToLocal:absPoint];
        
        self.selectedValueX = localPoint.x;
        
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(graphView:didSelectValueX:)]) {
            [self.delegate graphView:self didSelectValueX:self.selectedValueX];
        }
        [self setNeedsDisplay];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        self.selectedValueX = START_POS_SELECTED_LINE;
        [self setNeedsDisplay];
    }
}

@end
