//
//  Copyright 2013-2015 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//
 
#import "BasicPhoneAppDelegate.h"
#import "BasicPhoneViewController.h"
#import "BasicPhone.h" 

@implementation BasicPhoneAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize phone = _phone;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions 
{
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        /* iOS 8.0 later */
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|
                                                                                                    UIUserNotificationTypeBadge|
                                                                                                    UIUserNotificationTypeSound
                                                                                        categories:nil]];
    }
    
	// Set the view controller as the window's root view controller and display.
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
	
	// Initialize the BasicPhone object that coordinates with the Twilio Client SDK.
	// Note that the code immediately fetches a Capability Token
	// in BasicPhone's login method and initializes a TCDevice.  In a production-ready
	// application, you will want to defer any network requests until after your UIApplication 
	// launch has completed in case any of those requests end up timing out -- otherwise
	// the application risks getting shut down by the operating system if the launch takes too long.
	self.phone = [[BasicPhone alloc] init];
	
	self.viewController.phone = self.phone;
	
	[self.phone login];
	
    return YES;
}


#pragma mark -
#pragma mark UIApplication 

-(BOOL)isForeground
{
	UIApplicationState state = [UIApplication sharedApplication].applicationState;
	return (state==UIApplicationStateActive);
}


#pragma mark -
#pragma mark Memory management




@end
