//
//  Copyright 2013-2015 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//
 
#import "BasicPhone.h"
#import "BasicPhoneNotifications.h"
#import "Reachability.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

// private methods
@interface BasicPhone ()

//TCDevice Capability Token 
-(NSString*)getCapabilityTokenWithParameters:(NSDictionary*)dictParams error:(NSError**)error;
-(BOOL)capabilityTokenValid;

-(void)updateAudioRoute;

+(NSError*)errorFromHTTPResponse:(NSHTTPURLResponse*)response domain:(NSString*)domain;

@end


@implementation BasicPhone

@synthesize device = _device;
@synthesize connection = _connection;
@synthesize pendingIncomingConnection = _pendingIncomingConnection;
@synthesize backgroundTaskAgent = _backgroundTaskAgent;

#pragma mark -
#pragma mark Initialization

-(void)beginBackgroundUpdateTask
{
    if (self.backgroundTaskAgent == UIBackgroundTaskInvalid)
    {
        self.backgroundTaskAgent = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(void) {
            [self endBackgroundUpdateTask];
        }];
    }
}

-(void)endBackgroundUpdateTask
{
    if (self.backgroundTaskAgent != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskAgent];
        self.backgroundTaskAgent = UIBackgroundTaskInvalid;
    }
}

-(id)init
{
	if ( self = [super init] )
	{
		_speakerEnabled = YES; // enable the speaker by default
        _internetReachability = [Reachability reachabilityForInternetConnection];
        [_internetReachability stopNotifier];
        _loggedIn = NO;
        
        self.backgroundTaskAgent = UIBackgroundTaskInvalid;
        
        [[TwilioClient sharedInstance] setLogLevel:TC_LOG_VERBOSE];
	}
	return self;
}

-(void)reachabilityChanged:(NSNotification *)note
{
    NetworkStatus netStatus = [_internetReachability currentReachabilityStatus];
    
    if(netStatus != NotReachable && !_loggedIn)
    {
        [self loginHelper];
    }
}

-(void)login
{
    [self beginBackgroundUpdateTask];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BPLoginDidStart object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    NetworkStatus netStatus = [_internetReachability currentReachabilityStatus];
    
    if(netStatus != NotReachable)
    {
        [self loginHelper];
    }
    else
    {
        [_internetReachability startNotifier];
    }
}

-(void)loginHelper
{
    NSDictionary* params = @{ BPCapabilityTokenKeyAllowOutgoing : @YES,
                              BPCapabilityTokenKeyAllowIncoming : @YES,
                              BPCapabilityTokenKeyIncomingClient : BPDefaultClientName};
    [self doLoginWithCapabilityTokenParams:params];
}

-(void)updateCapabilityToken:(NSDictionary*)dictCapabilityParams
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BPLoginDidStart object:nil];
    
    [self doLoginWithCapabilityTokenParams:dictCapabilityParams];
}

-(void)doLoginWithCapabilityTokenParams:(NSDictionary*)dictCapabilityParams
{
    NSError* loginError = nil;
    NSString* capabilityToken = [self getCapabilityTokenWithParameters:dictCapabilityParams error:&loginError];
    
    if ( !loginError && capabilityToken )
    {
        if ( !_device )
        {
            // initialize a new device
            _device = [[TCDevice alloc] initWithCapabilityToken:capabilityToken delegate:self];
        }
        else
        {
            // update its capabilities
            [_device updateCapabilityToken:capabilityToken];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BPLoginDidFinish object:nil];
        _loggedIn = YES;
    }
    else if ( loginError )
    {
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:loginError forKey:@"error"];
        [[NSNotificationCenter defaultCenter] postNotificationName:BPLoginDidFailWithError object:nil userInfo:userInfo];
    }
    
    [self endBackgroundUpdateTask];
}

#pragma mark -
#pragma mark TCDevice Capability Token

-(NSString*)getCapabilityTokenWithParameters:(NSDictionary*)dictParams error:(NSError**)error
{
	//Requests a new capability token from the server
	NSString *capabilityToken = nil;
	//Make the URL Connection to your server
    
    /* Note:
        [BasicPhoneViewController::btnUpdateCapabilityTokenClicked:] will pass capabilities, specified on the UI, via dictParams. 
        Check BasicPhone.h for key reference.
            "allowOutgoing": NSNumber object with boolean value
            "allowIncoming": NSNumber object with boolean value
            "incomingClient": NSString object
        Provide these as parameters to your capability-token server application
     */
    NSString* outgoing = [NSString stringWithFormat:@"token?allowOutgoing=%@", [[dictParams objectForKey:BPCapabilityTokenKeyAllowOutgoing] boolValue] ? @"true" : @"false"];
    NSString* params;
    if ([[dictParams objectForKey:BPCapabilityTokenKeyAllowIncoming] boolValue]) {
        params = [NSString stringWithFormat:@"%@&client=%@", outgoing, [dictParams objectForKey:BPCapabilityTokenKeyIncomingClient]];
    } else {
        params = outgoing;
    }
    
#warning Change this URL to point to your token generation script on your public server
    NSString *urlString = [NSString stringWithFormat:@"http://companyfoo.com/%@", params];
    NSURL *url = [NSURL URLWithString:urlString];
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url]
										 returningResponse:&response error:error];
	if (data)
	{
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
		
		if (httpResponse.statusCode==200)
		{
			capabilityToken = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		}
		else
		{
			*error = [BasicPhone errorFromHTTPResponse:httpResponse domain:@"CapabilityTokenDomain"];
		}
	}
	// else there is likely an error which got assigned to the incoming error pointer.
	
	return capabilityToken;
}

-(BOOL)capabilityTokenValid
{
	//Check TCDevice's capability token to see if it is still valid
	BOOL isValid = NO;
	NSNumber* expirationTimeObject = [_device.capabilities objectForKey:@"expiration"];
	long long expirationTimeValue = [expirationTimeObject longLongValue];
	long long currentTimeValue = (long long)[[NSDate date] timeIntervalSince1970];

	if((expirationTimeValue-currentTimeValue)>0)
		isValid = YES;
	
	return isValid;
}

#pragma mark -
#pragma mark TCConnection Implementation

-(void)connect
{
    [self connectWithParams:nil];
}

-(void)connectWithParams:(NSDictionary*)dictParams
{
    // First check to see if the token we have is valid, and if not, refresh it.
    // Your own client may ask the user to re-authenticate to obtain a new token depending on
    // your security requirements.
    if (![self capabilityTokenValid])
    {
        //Capability token is not valid, so create a new one and update device
        [self login];
    }
    
    // Now check to see if we can make an outgoing call and attempt a connection if so
    NSNumber* hasOutgoing = [_device.capabilities objectForKey:TCDeviceCapabilityOutgoingKey];
    if ([hasOutgoing boolValue] == YES)
    {
        //Disconnect if we've already got a connection in progress
        if(_connection)
        {
            [self disconnect];
        }

#warning - use "dictParams" to handle whatever parameters you want to pass from view-controller to TCDevice
        _connection = [_device connect:dictParams delegate:self];
        
        if (!_connection) // if a connection is established, connectionDidStartConnecting: gets invoked next
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:BPConnectionDidFailToConnect object:nil];
        }
    }
}

-(void)disconnect
{
	//Destroy TCConnection
	// We don't release until after the delegate callback for connectionDidConnect:
	[_connection disconnect];

	[[NSNotificationCenter defaultCenter] postNotificationName:BPConnectionIsDisconnecting object:nil];
}	


-(void)acceptConnection
{
	//Accept the pending connection
	[_pendingIncomingConnection accept];
	_connection = _pendingIncomingConnection;
	_pendingIncomingConnection = nil;
}

-(void)rejectIncomingConnection
{
	// Reject the pending connection
	// We don't release until after the delegate callback for connectionDidConnect:
	[_pendingIncomingConnection reject];
}

-(void)ignoreIncomingConnection
{
    // Ignore the pending connection
	// We don't release until after the delegate callback for connectionDidConnect:
	[_pendingIncomingConnection ignore];
}

#pragma mark -
#pragma mark TCDeviceDelegate Methods

-(void)deviceDidStartListeningForIncomingConnections:(TCDevice*)device
{
	[[NSNotificationCenter defaultCenter] postNotificationName:BPDeviceDidStartListeningForIncomingConnections object:nil];
}

-(void)device:(TCDevice*)device didStopListeningForIncomingConnections:(NSError*)error
{
	// The TCDevice is no longer listening for incoming connections, possibly due to an error.
	NSDictionary* userInfo = nil;
	if ( error )
		userInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:BPDeviceDidStopListeningForIncomingConnections object:nil userInfo:userInfo];
}

-(void)device:(TCDevice*)device didReceiveIncomingConnection:(TCConnection*)connection
{
	//Device received an incoming connection
	if ( _pendingIncomingConnection )
	{
		NSLog(@"A pending exception already exists");
		return;
	}
	
	// Initalize pending incoming conneciton
	_pendingIncomingConnection = connection;
	[_pendingIncomingConnection setDelegate:self];
    
    NSDictionary* parameters = [connection parameters];
	
	// Send a notification out that we've received this.
	[[NSNotificationCenter defaultCenter] postNotificationName:BPPendingIncomingConnectionReceived object:nil userInfo:parameters];
}

#pragma mark -
#pragma mark TCConnectionDelegate

-(void)connectionDidStartConnecting:(TCConnection*)connection
{
	[[NSNotificationCenter defaultCenter] postNotificationName:BPConnectionIsConnecting object:nil];
}

-(void)connectionDidConnect:(TCConnection*)connection
{
	// Enable the proximity sensor to make sure the call doesn't errantly get hung up.
	UIDevice* device = [UIDevice currentDevice];
	device.proximityMonitoringEnabled = YES;
	
	// set up the route audio through the speaker, if enabled
	[self updateAudioRoute];

	[[NSNotificationCenter defaultCenter] postNotificationName:BPConnectionDidConnect object:nil];
}

-(void)connectionDidDisconnect:(TCConnection*)connection
{
	if ( connection == _connection )
	{
		UIDevice* device = [UIDevice currentDevice];
		device.proximityMonitoringEnabled = NO;

		_connection = nil;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:BPConnectionDidDisconnect object:nil];
	}
	else if ( connection == _pendingIncomingConnection )
	{
		_pendingIncomingConnection = nil;

		[[NSNotificationCenter defaultCenter] postNotificationName:BPPendingIncomingConnectionDidDisconnect object:nil];
	}
}

-(void)connection:(TCConnection*)connection didFailWithError:(NSError*)error
{
	//Connection failed
    _connection = nil;
    
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"]; // autoreleased
	[[NSNotificationCenter defaultCenter] postNotificationName:BPConnectionDidFailWithError object:nil userInfo:userInfo];
}

-(void)setSpeakerEnabled:(BOOL)enabled
{
	_speakerEnabled = enabled;
	
	[self updateAudioRoute];
}

-(void)updateAudioRoute
{
	if (_speakerEnabled)
	{
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:kAudioSessionOverrideAudioRoute_Speaker error:nil];
	}
	else
	{
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:kAudioSessionOverrideAudioRoute_None error:nil];
	}
}

-(void)setMuted:(BOOL)bMuted
{
    if (_connection) {
        _connection.muted = bMuted;
    }
}

#pragma mark -
#pragma mark Misc

// Utility method to create a simple NSError* from an HTTP response
+(NSError*)errorFromHTTPResponse:(NSHTTPURLResponse*)response domain:(NSString*)domain
{
	NSString* localizedDescription = [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode];
	
	NSDictionary* errorUserInfo = [NSDictionary dictionaryWithObject:localizedDescription
															  forKey:NSLocalizedDescriptionKey];
	
	NSError* error = [NSError errorWithDomain:domain
										 code:response.statusCode
									 userInfo:errorUserInfo];
	return error;	
}

#pragma mark -
#pragma mark Memory management


@end
