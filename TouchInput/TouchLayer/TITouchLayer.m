//
//  TITouchLayer.m
//  TouchInput
//
//  Created by Андрей Зарембо on 09.04.14.
//  Copyright (c) 2014 AndreyZarembo. All rights reserved.
//

#import "TITouchLayer.h"

@interface TITouchLayer() {
    UITouch *_currentTouch;
    CGFloat _time;
    NSMutableArray *_points;
    CCSprite *_arrow;
}

- (void)updatePointsCount: (NSUInteger)newPointsCount;

@end

@implementation TITouchLayer

-(id) init
{
	if ((self = [super init]))
	{
		glClearColor(0.1f, 0.1f, 0.3f, 1.0f);
        
        _arrow = [CCSprite spriteWithFile: @"arrow.png"];
        _arrow.opacity = 0;
        _arrow.position = CGPointMake(0, 0);
        [self addChild: _arrow z:1];
        
        self.trajectoryManager = [[TITrajectoryManager alloc] init];
        self.trajectoryManager.arrow = _arrow;
        
        _points = [NSMutableArray array];
        
        _time = 0;
        [self scheduleUpdate];
	}
    
	return self;
}

- (void)update:(ccTime)delta {
    _time += delta;
}

- (void)draw {
    [super draw];
    
    NSArray *splinePoints = [self.trajectoryManager.spline splinePoints];
    
    if (splinePoints.count >= 2) {
        
        [self updatePointsCount:floorf((splinePoints.count-1)/2)];
        
        for (int segmentID = 0; segmentID < floorf((splinePoints.count-1)/2); segmentID++) {
            CGPoint pt0 = [splinePoints[segmentID*2] CGPointValue];
            CGPoint pt1 = [splinePoints[segmentID*2+1] CGPointValue];
            CGPoint pt2 = [splinePoints[segmentID*2+2] CGPointValue];
            
            CGPoint pos = pt0;
            CGFloat t = 2 -  MAX(0,MIN(2,fmodf(_time*20, 20.)/10.));
            if (t <= 1) {
                pos = CGPointMake(pt0.x*t+pt1.x*(1-t), pt0.y*t+pt1.y*(1-t));
            } else {
                t = t-1;
                pos = CGPointMake(pt1.x*t+pt2.x*(1-t), pt1.y*t+pt2.y*(1-t));
            }
//            ccDrawCircle(pos, 4, 0, 8, NO);
            CCSprite *point = _points[segmentID];
            point.position = pos;
            point.opacity = 255;
        }
    }
}

- (void)updatePointsCount: (NSUInteger)newPointsCount {
    
    if (_points.count < newPointsCount) {
        for (NSUInteger newPointID = _points.count; newPointID < newPointsCount; newPointID++) {
            CCSprite *point = [CCSprite spriteWithFile: @"dot.png"];
            [self addChild: point z:0];
            point.opacity = 0;
            [_points addObject: point];
        }
    } else if (_points.count > newPointsCount) {
        for (NSUInteger newPointID = newPointsCount; newPointID < _points.count; newPointID++) {
            CCSprite *point = _points[newPointID];
            point.opacity = 0;
            point.position = CGPointMake(0, 0);
        }
    }
}

@end
