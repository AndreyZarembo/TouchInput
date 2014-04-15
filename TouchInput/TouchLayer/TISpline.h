//
//  TISpline.h
//  TouchInput
//
//  Created by Андрей Зарембо on 09.04.14.
//  Copyright (c) 2014 AndreyZarembo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TISpline : NSObject {
    NSMutableArray *_points;
    NSMutableArray *_allPoints;
    NSMutableArray *_splinePoints;
    NSMutableArray *_tempPoints;
}

- (void)addPoint: (CGPoint)point;
- (void)reset;

- (NSArray*)findLoops;

@property (nonatomic,readonly) CGFloat length;
@property (nonatomic,readonly) NSArray *splinePoints;

@end
