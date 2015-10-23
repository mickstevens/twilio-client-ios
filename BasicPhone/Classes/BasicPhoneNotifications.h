//
//  Copyright 2013-2015 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//
 
// Notification strings used with NSNotification to convey significant events
// between the model and the views.

extern NSString* const BPLoginDidStart;
extern NSString* const BPLoginDidFinish;
extern NSString* const BPLoginDidFailWithError;

extern NSString* const BPPendingIncomingConnectionReceived; // userInfo contains [TCConnection parameters]
extern NSString* const BPPendingIncomingConnectionDidDisconnect;
extern NSString* const BPConnectionIsConnecting;
extern NSString* const BPConnectionIsDisconnecting;
extern NSString* const BPConnectionDidConnect;
extern NSString* const BPConnectionDidFailToConnect;
extern NSString* const BPConnectionDidDisconnect;
extern NSString* const BPConnectionDidFailWithError;

extern NSString* const BPDeviceDidStartListeningForIncomingConnections;
extern NSString* const BPDeviceDidStopListeningForIncomingConnections; // has an optional "error" payload in the userInfo
