//
//  Copyright 2013-2015 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//
 

#import "BasicPhoneNotifications.h"

NSString* const BPLoginDidStart									= @"BPLoginDidStart";
NSString* const BPLoginDidFinish								= @"BPLoginDidFinish";
NSString* const BPLoginDidFailWithError							= @"BPLoginDidFailWithError";

NSString* const BPPendingIncomingConnectionReceived				= @"BPPendingIncomingConnectionReceived";
NSString* const BPPendingIncomingConnectionDidDisconnect		= @"BPPendingIncomingConnectionDidDisconnect";
NSString* const BPPendingConnectionDidDisconnect				= @"BPPendingConnectionDidDisconnect";
NSString* const BPConnectionDidConnect							= @"BPConnectionDidConnect";
NSString* const BPConnectionDidFailToConnect					= @"BPConnectionDidFailToConnect";
NSString* const BPConnectionIsConnecting						= @"BPConnectionIsConnecting";
NSString* const BPConnectionIsDisconnecting						= @"BPConnectionIsDisconnecting";
NSString* const BPConnectionDidDisconnect						= @"BPConnectionDidDisconnect";
NSString* const BPConnectionDidFailWithError					= @"BPConnectionDidFailWithError";

NSString* const BPDeviceDidStartListeningForIncomingConnections	= @"BPDeviceDidStartListeningForIncomingConnections";
NSString* const BPDeviceDidStopListeningForIncomingConnections	= @"BPDeviceDidStopListeningForIncomingConnections";
