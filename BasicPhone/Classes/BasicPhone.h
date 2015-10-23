//
//  Copyright 2013-2015 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//
 
#import <Foundation/Foundation.h>
#import "TwilioClient.h"
#import "Reachability.h"

#define BPDefaultClientName @"jenny"
#define BPCapabilityTokenKeyAllowOutgoing @"allowOutgoing"
#define BPCapabilityTokenKeyAllowIncoming @"allowIncoming"
#define BPCapabilityTokenKeyIncomingClient @"incomingClient"

@interface BasicPhone : NSObject<TCDeviceDelegate, TCConnectionDelegate, UIAlertViewDelegate> 
{
@private
	TCDevice* _device;
	TCConnection* _connection;
	TCConnection* _pendingIncomingConnection;
	BOOL _speakerEnabled;
    Reachability *_internetReachability;
    BOOL _loggedIn;
    UIBackgroundTaskIdentifier _backgroundTaskAgent;
}

@property (nonatomic,strong) TCDevice* device;
@property (nonatomic,strong) TCConnection* connection;
@property (nonatomic,strong) TCConnection* pendingIncomingConnection;
@property (nonatomic,strong) Reachability *internetReachability;
@property (assign) UIBackgroundTaskIdentifier backgroundTaskAgent;

-(void)login;
-(void)loginHelper;
-(void)updateCapabilityToken:(NSDictionary*)dictCapabilityParams;

// Turn the speaker on or off.
-(void)setSpeakerEnabled:(BOOL)enabled;

/* Mute the connection */
-(void)setMuted:(BOOL)bMuted;

//TCConnection Methods
-(void)connect;
-(void)connectWithParams:(NSDictionary*)dictParams;
-(void)disconnect;
-(void)acceptConnection;
-(void)rejectIncomingConnection;
-(void)ignoreIncomingConnection;

@end
