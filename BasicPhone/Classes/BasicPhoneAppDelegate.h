//
//  Copyright 2013-2015 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//
 
#import <UIKit/UIKit.h>

@class BasicPhoneViewController;
@class BasicPhone;

@interface BasicPhoneAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow* _window;
    BasicPhoneViewController* _viewController;
	
	BasicPhone* _phone;
}

@property (nonatomic, strong) IBOutlet UIWindow* window;
@property (nonatomic, strong) IBOutlet BasicPhoneViewController* viewController;
@property (nonatomic, strong) BasicPhone* phone;

// Returns NO if the app isn't in the foreground in a multitasking OS environment.
-(BOOL)isForeground;

@end

