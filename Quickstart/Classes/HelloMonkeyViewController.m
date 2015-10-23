//
//  Copyright 2011-2015 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//
 
#import "HelloMonkeyViewController.h"
#import "HelloMonkeyAppDelegate.h"
#import "TwilioClient.h"

@interface HelloMonkeyViewController() <TCDeviceDelegate, UITextFieldDelegate>
{
    TCDevice* _phone;
    TCConnection* _connection;
}
@end

@implementation HelloMonkeyViewController

- (void)viewDidLoad
{
    self.numberField.delegate = self;
    
#if TARGET_IPHONE_SIMULATOR
    NSString *name = @"tommy";
#else
    NSString *name = @"jenny";
#endif
    
// #warning replace this URL with your own server
    //check out https://github.com/twilio/mobile-quickstart to get a server up quickly
    NSString *urlString = [NSString stringWithFormat:@"https://twilio-client-ios.herokuapp.com/token?client=%@", name];
    NSURL *url = [NSURL URLWithString:urlString];
    NSError *error = nil;
    NSString *token = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (token == nil) {
        NSLog(@"Error retrieving token: %@", [error localizedDescription]);
    } else {
        _phone = [[TCDevice alloc] initWithCapabilityToken:token delegate:self];
    }
}

- (IBAction)dialButtonPressed:(id)sender
{
    [self.numberField resignFirstResponder];
    
    NSDictionary *params = @{@"To": self.numberField.text};
    _connection = [_phone connect:params delegate:nil];
}

- (IBAction)hangupButtonPressed:(id)sender
{
    [self.numberField resignFirstResponder];
    
    [_connection disconnect];
}

- (void)device:(TCDevice *)device didReceiveIncomingConnection:(TCConnection *)connection
{
    NSLog(@"Incoming connection from: %@", [connection parameters][@"From"]);
    if (device.state == TCDeviceStateBusy) {
        [connection reject];
    } else {
        [connection accept];
        _connection = connection;
    }
}

- (void)deviceDidStartListeningForIncomingConnections:(TCDevice*)device
{
    NSLog(@"Device: %@ deviceDidStartListeningForIncomingConnections", device);
}

- (void)device:(TCDevice *)device didStopListeningForIncomingConnections:(NSError *)error
{
    NSLog(@"Device: %@ didStopListeningForIncomingConnections: %@", device, error);
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
