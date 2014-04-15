//
//  TIAppDelegate.m
//  TouchInput
//
//  Created by Андрей Зарембо on 09.04.14.
//  Copyright (c) 2014 AndreyZarembo. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

-(void) initializationComplete
{
#ifdef KK_ARC_ENABLED
	NSLog(@"ARC is enabled");
#else
	NSLog(@"ARC is either not available or not enabled");
#endif
}

-(id) alternateView
{
	return nil;
}


@end
