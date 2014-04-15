//
//  TITrajectoryManager.m
//  TouchInput
//
//  Created by Андрей Зарембо on 09.04.14.
//  Copyright (c) 2014 AndreyZarembo. All rights reserved.
//

#import "TITrajectoryManager.h"
#import "TITouchLayer.h"
#import <kobold2d.h>

#define maxLength 768*2+1024*2

#define arrowSpeed 600
#define hideEffectDuration 0.25

@interface TITrajectoryManager() {
    UITouch *_currentTouch;
}

- (void)resetArrow;
- (void)sendArrow;
- (void)detectLoops;

@end

@implementation TITrajectoryManager

- (id)init {
    self = [super init];
    if (self) {
        _spline = [[TISpline alloc] init];
        [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate: self priority:0 swallowsTouches: YES];
    }
    return self;
}

#pragma mark CCTouchOneByOneDelegate

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    if (_currentTouch == nil || _currentTouch.phase == kCCTouchCancelled) {
        _currentTouch = touch;
        [self.spline reset];
    }
    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    if (touch == _currentTouch) {
        
        if (self.spline.length >= maxLength) return;
        
        CGPoint location = [_currentTouch locationInView: touch.view];
        CGPoint pointToAdd = CGPointMake(location.x, touch.view.frame.size.height - location.y);
        [self.spline addPoint: pointToAdd];
    }
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    _currentTouch = nil;
    [self sendArrow];
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    _currentTouch = nil;
    [self sendArrow];
}

#pragma mark ArrowControl

- (void)sendArrow {
    
    [self resetArrow];
    
    [self detectLoops];
    
    NSArray *splinePoints = self.spline.splinePoints;
    if (splinePoints.count < 2) {
        return;
    }
    
    NSMutableArray *moves = [NSMutableArray array];
    
    CGPoint lastDirectionVector;
    
    NSValue *prevPointVal = nil;
    for (NSValue *pointVal in splinePoints) {
        if (prevPointVal == nil) {
            CCCallBlock *setInitialPosition = [CCCallBlock actionWithBlock:^{
                _arrow.position = pointVal.CGPointValue;
                _arrow.opacity = 255;
            }];
            [moves addObject: setInitialPosition];
        } else {
            
            CGPoint point = pointVal.CGPointValue;
            CGPoint prevPoint = prevPointVal.CGPointValue;
            CGPoint diff = CGPointMake(point.x-prevPoint.x, point.y-prevPoint.y);
        
            CGFloat distance = hypotf(diff.x,diff.y);
            CGFloat duration = distance / arrowSpeed;
            lastDirectionVector = CGPointMake(diff.x/distance, diff.y/distance);
            
            CGFloat angle = -atan2f(diff.y,diff.x)*180./M_PI;
            
            CCMoveTo *moveArrow = [CCMoveTo actionWithDuration: duration position: point];
            CCRotateTo *rotateArrow = [CCRotateTo actionWithDuration: duration angle: angle];
            CCSpawn *moveAndRotate = [CCSpawn actionWithArray: @[ moveArrow, rotateArrow ]];
            
            [moves addObject: moveAndRotate];
        }
        prevPointVal = pointVal;
    }
    
    CCFadeTo *hideArrow = [CCFadeTo actionWithDuration: hideEffectDuration opacity:0];
    CCMoveBy *moveArrow = [CCMoveBy actionWithDuration: hideEffectDuration position: CGPointMake(lastDirectionVector.x*arrowSpeed*hideEffectDuration, lastDirectionVector.y*arrowSpeed*hideEffectDuration)];
    CCSpawn *moveAndHide = [CCSpawn actionWithArray: @[ moveArrow, hideArrow ]];
    
    [moves addObject: moveAndHide];
    
    [_arrow runAction: [CCSequence actionWithArray: moves]];
}

- (void)resetArrow {
    [_arrow stopAllActions];
    _arrow.opacity = 0;
    _arrow.position = CGPointMake(0, 0);
}

#pragma mark loops

- (void)detectLoops {
    NSArray *loops = [_spline findLoops];
    NSLog(@"Loops: %@",loops);
}

@end
