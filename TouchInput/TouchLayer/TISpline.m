//
//  TISpline.m
//  TouchInput
//
//  Created by Андрей Зарембо on 09.04.14.
//  Copyright (c) 2014 AndreyZarembo. All rights reserved.
//

#import "TISpline.h"

#define filterDistance 20
#define tension 0.75
#define distancePart 10

@interface TISpline() {
    NSUInteger _lastParsedSegmentID;
    CGFloat _length;
    CGFloat _tempLength;
}

- (void)refreshSpline;

@end

@implementation TISpline

- (id)init {
    self = [super init];
    if (self) {
        _points = [NSMutableArray array];
        _allPoints = [NSMutableArray array];
        _splinePoints = [NSMutableArray array];
        _tempPoints = [NSMutableArray array];
    }
    return self;
}

- (void)addPoint: (CGPoint)point {

    [_allPoints addObject: [NSValue valueWithCGPoint: point]];
    if (_points.count == 0) {
        [_points addObject: [NSValue valueWithCGPoint: point]];
    } else {
        CGPoint prevPoint = [[_points lastObject] CGPointValue];
        CGFloat distance = hypotf(point.x-prevPoint.x, point.y-prevPoint.y);
        if (distance >= filterDistance) {
            [_points addObject: [NSValue valueWithCGPoint: point]];
            [self refreshSpline];
        }
    }
}

- (void)reset {
    _length = 0;
    _tempLength = 0;
    [_points removeAllObjects];
    [_allPoints removeAllObjects];
    [_splinePoints removeAllObjects];
    [_tempPoints removeAllObjects];
    _lastParsedSegmentID = 0;
}

- (NSArray *)splinePoints {
    return _splinePoints;
}

- (CGFloat)length {
    return _length;
}

- (void)refreshSpline {
    if (_points.count < 4) return;
    
    [_splinePoints removeObjectsInArray: _tempPoints];
    _length -= _tempLength;
    [_tempPoints removeAllObjects];
    CGPoint a,b,c,d;
    
    for (NSUInteger segmentID = _lastParsedSegmentID; segmentID < _points.count-1; segmentID++) {
        
        if (segmentID == 0) {
            CGPoint pt0 = [_points[0] CGPointValue];
            CGPoint pt1 = [_points[1] CGPointValue];
            CGPoint diff = CGPointMake(pt1.x-pt0.x, pt1.y-pt0.y);
            a = CGPointMake(pt0.x-diff.x, pt0.y-diff.y);
        } else {
            a = [_points[segmentID-1] CGPointValue];
        }
        b = [_points[segmentID] CGPointValue];
        c = [_points[segmentID+1] CGPointValue];
        if (segmentID == _points.count-2) {
            CGPoint ptLast_1 = [_points[_points.count-2] CGPointValue];
            CGPoint ptLast = [_points[_points.count-1] CGPointValue];
            CGPoint diff = CGPointMake(ptLast.x-ptLast_1.x, ptLast.y-ptLast_1.y);
            d = CGPointMake( ptLast.x + diff.x, ptLast.y + diff.y);
        } else {
            d = [_points[segmentID+2] CGPointValue];
        }
        
        CGFloat prevLength = _length;
        NSArray *newPoints = [self getBezierPartForPointA:a pointB:b pointC:c andPointD:d withLength: &_length splinePrevPoint: _splinePoints.lastObject];
        if (segmentID > 1 && segmentID > _lastParsedSegmentID) {
            _tempLength = _length - prevLength;
            [_tempPoints addObjectsFromArray: newPoints];
        }
        [_splinePoints addObjectsFromArray: newPoints];
    }
    _lastParsedSegmentID = _points.count-2;
}

- (NSArray*)getBezierPartForPointA: (CGPoint)p0 pointB: (CGPoint)p1 pointC: (CGPoint)p2 andPointD: (CGPoint)p3 withLength:(CGFloat *)length splinePrevPoint: (NSValue*)splinePrevPoint {
    
    NSMutableArray *result = [NSMutableArray array];
    
    CGFloat lengthEstimate = hypotf(p2.x-p1.x, p2.y-p1.y);
    CGFloat tStep =  1 / lengthEstimate;
    
    BOOL first = splinePrevPoint == nil ? YES : NO;
    CGPoint prevPoint = splinePrevPoint.CGPointValue;
    
    for (CGFloat t = 0; t < 1; t+= tStep) {
        
        CGFloat t2 = t * t;
        CGFloat t3 = t2 * t;
        
        CGFloat s = tension;
        
        CGFloat b1 = s * (-t3 + 2 * t2 - t);
        CGFloat b2 = s * (-t3 + t2) + (2 * t3 - 3 * t2 + 1);
        CGFloat b3 = s * (t3 - 2 * t2 + t) + (-2 * t3 + 3 * t2);
        CGFloat b4 = s * (t3 - t2);
        
        CGFloat x = (p0.x*b1 + p1.x*b2 + p2.x*b3 + p3.x*b4);
        CGFloat y = (p0.y*b1 + p1.y*b2 + p2.y*b3 + p3.y*b4);
        
        CGPoint point = CGPointMake(x, y);
        if (first) {
            first = NO;
            prevPoint = point;
            continue;
        }
        
        CGPoint diff = CGPointMake(point.x-prevPoint.x, point.y - prevPoint.y);
        
        CGFloat distance = hypotf(diff.x, diff.y);
        
        CGFloat currentLength = *length+distance;
        CGFloat targetLength = floorf(*length)+distancePart;
        
        if (currentLength > targetLength) {
            
            CGFloat T = (currentLength - targetLength)/distancePart;
            if (T > 0.2) T = 0.2;
            if (T < -0.2) T = -0.2;
            CGPoint pt = CGPointMake(point.x - diff.x*T, point.y - diff.y*T);
            
            CGFloat newPointDistance = hypotf(pt.x-prevPoint.x, pt.y-prevPoint.y);
            
            *length = *length+newPointDistance;
            [result addObject: [NSValue valueWithCGPoint:pt]];
            prevPoint = pt;
        }
    }
    
    return result;
}

#pragma mark loops

#define pointSkip 5

- (NSArray *)findLoops {
    
    NSMutableArray *loops = [NSMutableArray array];
    
    if (_splinePoints.count < pointSkip*2) return loops;
    
    for (NSUInteger currentPointID = pointSkip*2+1; currentPointID < _splinePoints.count; currentPointID+=pointSkip) {
        for (NSUInteger prevPointID = pointSkip; prevPointID < currentPointID-pointSkip-2; prevPointID+=pointSkip) {
            
            NSValue *cpSv = _splinePoints[currentPointID];
            NSValue *cpEv = _splinePoints[currentPointID-pointSkip];
            NSValue *ppSv = _splinePoints[prevPointID];
            NSValue *ppEv = _splinePoints[prevPointID-pointSkip];
            
            CGPoint cpS = cpSv.CGPointValue;
            CGPoint cpE = cpEv.CGPointValue;
            CGPoint ppS = ppSv.CGPointValue;
            CGPoint ppE = ppEv.CGPointValue;
            
            BOOL result = [self boundsCheck: cpS.x b: cpE.x c: ppS.x d: ppE.x] &&
            [self boundsCheck: cpS.y b: cpE.y c: ppS.y d: ppE.y] &&
            ([self areaOfTriangleWithPtA:cpS ptB:cpE ptC: ppS] * [self areaOfTriangleWithPtA:cpS ptB:cpE ptC: ppE] <= 0) &&
            ([self areaOfTriangleWithPtA:ppS ptB:ppE ptC: cpS] * [self areaOfTriangleWithPtA:ppS ptB:ppE ptC: cpE] <= 0);
            
            if (result) {
                [loops addObject: @{ @"from": @(prevPointID), @"to": @(currentPointID) }];
            }
        }
    }
    return loops;
}

- (CGFloat)areaOfTriangleWithPtA: (CGPoint)a ptB: (CGPoint)b ptC: (CGPoint)c {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

- (bool)boundsCheck: (CGFloat)a b:(CGFloat)b c:(CGFloat)c d:(CGFloat)d {
    if (a > b)  {
        CGFloat t = a;
        a = b;
        b = t;
    }
    if (c > d)  {
        CGFloat t = c;
        c = d;
        d = t;
    }
    return MAX(a,c) <= MIN(b,d);
}


@end
