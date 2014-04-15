//
//  TITrajectoryManager.h
//  TouchInput
//
//  Created by Андрей Зарембо on 09.04.14.
//  Copyright (c) 2014 AndreyZarembo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TISpline.h"

@interface TITrajectoryManager : NSObject <CCTouchOneByOneDelegate>

@property (nonatomic,strong,readonly) TISpline *spline;

@property (nonatomic,weak) CCSprite *arrow;
@property (nonatomic,weak) CCLabelTTF *tripleLoopLabel;

@end
