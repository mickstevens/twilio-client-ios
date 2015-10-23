//
//  Copyright 2013-2015 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//
 
#import "BasicPhoneViewController.h"
#import "BasicPhoneAppDelegate.h"
#import "BasicPhoneNotifications.h"
#import "BasicPhone.h"

@interface BasicPhoneViewController () <UIActionSheetDelegate, UITextFieldDelegate> // Internal methods that don't get exposed.

/* UI elements */
@property (strong, nonatomic) IBOutlet UIView *viewIncomingSignal;
@property (strong, nonatomic) IBOutlet UIView *viewOutgoingSignal;
@property (strong, nonatomic) IBOutlet UILabel *labelIncomingSignal;
@property (strong, nonatomic) IBOutlet UILabel *labelOutgoingSignal;
@property (strong, nonatomic) IBOutlet UIButton *btnOutgoingType;
@property (strong, nonatomic) IBOutlet UILabel *labelOutgoingType;
@property (strong, nonatomic) IBOutlet UITextField *textIncomingClient;
@property (strong, nonatomic) IBOutlet UITextField *textOutgoingDest;
@property (strong, nonatomic) IBOutlet UILabel *labelMuted;
@property (strong, nonatomic) IBOutlet UISwitch *switchMuted;
@property (strong, nonatomic) IBOutlet UIView *mainButtonBaseview;
@property (strong, nonatomic) IBOutlet UIButton *btnToggleIncomingCapability;
@property (strong, nonatomic) IBOutlet UIButton *btnToggleOutgoingCapability;

-(void)syncMainButton;
-(void)addStatusMessage:(NSString*)message;

// notifications
-(void)loginDidStart:(NSNotification*)notification;
-(void)loginDidFinish:(NSNotification*)notification;
-(void)loginDidFailWithError:(NSNotification*)notification;

-(void)connectionDidConnect:(NSNotification*)notification;
-(void)connectionDidFailToConnect:(NSNotification*)notification;
-(void)connectionIsDisconnecting:(NSNotification*)notification;
-(void)connectionDidDisconnect:(NSNotification*)notification;
-(void)connectionDidFailWithError:(NSNotification*)notification;

-(void)pendingIncomingConnectionDidDisconnect:(NSNotification*)notification;
-(void)pendingIncomingConnectionReceived:(NSNotification*)notification;

-(void)deviceDidStartListeningForIncomingConnections:(NSNotification*)notification;
-(void)deviceDidStopListeningForIncomingConnections:(NSNotification*)notification;

@end

typedef enum{
    BPOutgoingNumber,
    BPOutgoingClient
}BPOutgoingType;

@implementation BasicPhoneViewController {
    BPOutgoingType _eOutgoingType;
}

@synthesize phone = _phone;
@synthesize mainButton = _mainButton;
@synthesize textView = _textView;
@synthesize speakerSwitch = _speakerSwitch;

#pragma mark -
#pragma mark Application behavior

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Limit to portrait for simplicity.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(id)init
{
    if (self = [super init]) {

    }
    
    return self;
}

-(void)viewDidLoad
{
	[super viewDidLoad];

	// Register for notifications that will be broadcast from the 
	// BasicPhone model/controller.  These may be received on any
	// thread, so calls that may update UI state should perform those
	// changes on the main thread.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loginDidStart:)
												 name:BPLoginDidStart
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loginDidFinish:)
												 name:BPLoginDidFinish
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loginDidFailWithError:)
												 name:BPLoginDidFailWithError
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionIsConnecting:)
												 name:BPConnectionIsConnecting
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionDidConnect:)
												 name:BPConnectionDidConnect
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionDidDisconnect:)
												 name:BPConnectionDidDisconnect
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionIsDisconnecting:)
												 name:BPConnectionIsDisconnecting
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionDidFailToConnect:)
												 name:BPConnectionDidFailToConnect
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(connectionDidFailWithError:)
												 name:BPConnectionDidFailWithError
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pendingIncomingConnectionReceived:)
												 name:BPPendingIncomingConnectionReceived
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pendingIncomingConnectionDidDisconnect:)
												 name:BPPendingIncomingConnectionDidDisconnect
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidStartListeningForIncomingConnections:)
												 name:BPDeviceDidStartListeningForIncomingConnections
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceDidStopListeningForIncomingConnections:)
												 name:BPDeviceDidStopListeningForIncomingConnections
											   object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
	[self syncMainButton]; // make sure the main button is up to date with the connection's status.
    
    [self prepareMainView];
}

-(void)viewDidUnload
{
	// Unregister this class from all notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.mainButton = nil;
	self.textView = nil;
	self.speakerSwitch = nil;
	
	[super viewDidUnload];
}

- (void)prepareMainView
{
    CGFloat fRadius = self.viewIncomingSignal.frame.size.height/2.0f;
    self.viewIncomingSignal.layer.cornerRadius = fRadius;
    self.viewOutgoingSignal.layer.cornerRadius = fRadius;
    
    [self.labelIncomingSignal setBackgroundColor:[UIColor clearColor]];
    [self.labelOutgoingSignal setBackgroundColor:[UIColor clearColor]];
    
    [self.labelIncomingSignal setText:@"Incoming"];
    [self.labelOutgoingSignal setText:@"Outgoing"];
    
    self.textIncomingClient.delegate = self;
    self.textOutgoingDest.delegate = self;
    
    [self.btnOutgoingType addTarget:self action:@selector(btnSelectOutgoingTypeClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardShowHide:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardShowHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [self.btnToggleIncomingCapability addTarget:self action:@selector(btnCapabilityToggleClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.btnToggleOutgoingCapability addTarget:self action:@selector(btnCapabilityToggleClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    _eOutgoingType = BPOutgoingClient;
}

#pragma mark -
#pragma mark Button Actions 

-(IBAction)mainButtonPressed:(id)sender
{
	//Action for button on main view
	BasicPhoneAppDelegate* delegate = (BasicPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	BasicPhone* basicPhone = delegate.phone;
	
	//Perform correct button function based on current connection
	if (!basicPhone.connection || basicPhone.connection.state == TCConnectionStateDisconnected)
	{
		//Connection doesn't exist or is disconnected, so make a call
        NSString* strToNumber = self.textOutgoingDest.text;
        if (strToNumber && ![strToNumber isEqualToString:@""]) {
            
            switch (_eOutgoingType) {
                /* leave phone number alone w/o prefixing it */
                case BPOutgoingNumber:
                    break;
                    
                case BPOutgoingClient:
                    strToNumber = [NSString stringWithFormat:@"client:%@", strToNumber];
                    break;
                    
                default:
                    break;
            }
            
            NSDictionary* dictParams = [NSDictionary dictionaryWithObjectsAndKeys:strToNumber, @"To", nil];
            [self.phone connectWithParams:dictParams];
        }
        else {
            [self.phone connectWithParams:nil];
        }
	}
	else
	{
		//Connection state is open, pending, or conncting, so disconnect phone
		[basicPhone disconnect];
	}
    
    [self syncMainButton];
}

-(IBAction)speakerSwitchPressed:(id)sender
{
	BasicPhoneAppDelegate* delegate = (BasicPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	BasicPhone* basicPhone = delegate.phone;

	[basicPhone setSpeakerEnabled:self.speakerSwitch.on];
}

- (IBAction)muteSwitched:(id)sender {
    UISwitch* muteSwitch = (UISwitch*)sender;
    
    [self.phone setMuted:muteSwitch.on];
}

- (IBAction)btnUpdateCapabilityTokenClicked:(id)sender
{
    if (self.phone) {
        /* to-do: add check-box for toggling incoming/outgoing on-off */
        NSString* strIncomingClientName = (self.textIncomingClient.text && ![self.textIncomingClient.text isEqualToString:@""])? self.textIncomingClient.text : BPDefaultClientName;
        NSDictionary* dictCapabilityParams = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:self.btnToggleOutgoingCapability.selected], BPCapabilityTokenKeyAllowOutgoing,
                                                                                        [NSNumber numberWithBool:self.btnToggleIncomingCapability.selected], BPCapabilityTokenKeyAllowIncoming,
                                                                                        strIncomingClientName, BPCapabilityTokenKeyIncomingClient, nil];
        
        [self.phone updateCapabilityToken:dictCapabilityParams];
    }
}

- (IBAction)btnCapabilityToggleClicked:(id)sender
{
    UIButton* btnToggle = (UIButton*)sender;
    btnToggle.selected = !btnToggle.selected;
    if (btnToggle.selected) {
        [btnToggle setImage:[UIImage imageNamed:@"checkbox_checked"] forState:UIControlStateNormal];
    }
    else {
        [btnToggle setImage:[UIImage imageNamed:@"checkbox_unchecked"] forState:UIControlStateNormal];
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 2) {
        /* Cancel */
        return;
    }
    BPOutgoingType outgoingType = (BPOutgoingType)buttonIndex;
    if (outgoingType != _eOutgoingType) {
        
        self.textOutgoingDest.text = @"";
        switch (outgoingType) {
            case BPOutgoingNumber:
                self.textOutgoingDest.placeholder = @"+14081234567";
                self.labelOutgoingType.text = @"Phone Number";
                break;
            case BPOutgoingClient:
                self.textOutgoingDest.placeholder = @"BPOutgoingClient";
                self.labelOutgoingType.text = @"Client";
                break;
                
            default:
                break;
        }
        
        _eOutgoingType = outgoingType;
    }
}

#pragma mark - keyboard events
- (void)handleKeyboardShowHide:(NSNotification*)notification
{
    if ([notification.name isEqualToString:@"UIKeyboardWillHideNotification"]) {
        CGRect frame = self.view.frame;
        frame.origin.y = 0.0f;
        self.view.frame = frame;
        return;
    }
    
    id dictKeyboard = notification.userInfo;
    CGRect frameKeyboard = [dictKeyboard[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    if (frameKeyboard.size.height > self.textView.frame.size.height) {
        CGRect frame = self.view.frame;
        frame.origin.y = -(frameKeyboard.size.height - self.textView.frame.size.height);
        self.view.frame = frame;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark Notifications

-(void)loginDidStart:(NSNotification*)notification
{
	[self addStatusMessage:@"-Logging in..."];		
}

-(void)loginDidFinish:(NSNotification*)notification
{
	NSNumber* hasOutgoing = [self.phone.device.capabilities objectForKey:TCDeviceCapabilityOutgoingKey];
    NSNumber* hasIncoming = [self.phone.device.capabilities objectForKey:TCDeviceCapabilityIncomingKey];
	if ( [hasOutgoing boolValue] == YES )
	{
		[self addStatusMessage:@"-Outgoing calls allowed"];		
	}
	else
	{
		[self addStatusMessage:@"-Unable to make outgoing calls with current capabilities"];
	}
	
	if ( [hasIncoming boolValue] == YES )
	{
		[self addStatusMessage:@"-Incoming calls allowed"];		
	}
	else
	{
		[self addStatusMessage:@"-Unable to receive incoming calls with current capabilities"];
	}
    
    [self syncMainButton];
    [self updateCapabilitySignals];
}

-(void)loginDidFailWithError:(NSNotification*)notification
{
	NSError* error = [[notification userInfo] objectForKey:@"error"];
	if ( error )
	{
		NSString* message = [NSString stringWithFormat:@"-Error logging in: %@ (%d)",
							 [error localizedDescription],
							 [error code]];
		[self addStatusMessage:message];		
	}
	else
	{
		[self addStatusMessage:@"-Unknown error logging in"];		
	}
	[self syncMainButton];	
}

-(void)connectionIsConnecting:(NSNotification*)notification
{
	[self addStatusMessage:@"-Attempting to connect"];
	[self syncMainButton];
}

-(void)connectionDidConnect:(NSNotification*)notification
{
	[self addStatusMessage:@"-Connection did connect"];
	[self syncMainButton];
    
    self.switchMuted.enabled = YES;
    self.switchMuted.on = NO;
}

-(void)connectionDidFailToConnect:(NSNotification*)notification
{
	[self addStatusMessage:@"-Couldn't establish outgoing call"];
    [self syncMainButton];
}

-(void)connectionIsDisconnecting:(NSNotification*)notification
{
	[self addStatusMessage:@"-Attempting to disconnect"];
	[self syncMainButton];
}

-(void)connectionDidDisconnect:(NSNotification*)notification
{
	[self addStatusMessage:@"-Connection did disconnect"];
	[self syncMainButton];
    
    self.switchMuted.enabled = NO;
    self.switchMuted.on = NO;
}

-(void)connectionDidFailWithError:(NSNotification*)notification
{
	NSError* error = [[notification userInfo] objectForKey:@"error"];
	if ( error )
	{
		NSString* message = [NSString stringWithFormat:@"-Connection did fail with error code %d, domain %@",
														 [error code],
														 [error domain]];
		[self addStatusMessage:message];
	}
	[self syncMainButton];
}

-(void)deviceDidStartListeningForIncomingConnections:(NSNotification*)notification
{
	[self addStatusMessage:@"-Device is listening for incoming connections"];
}

-(void)deviceDidStopListeningForIncomingConnections:(NSNotification*)notification
{
	NSError* error = [[notification userInfo] objectForKey:@"error"]; // may be nil
	if ( error )
	{
		[self addStatusMessage:[NSString stringWithFormat:@"-Device is no longer listening for connections due to error: %@ (%d)",
								[error localizedDescription], [error code]]];
	}
	else
	{
		[self addStatusMessage:@"-Device is no longer listening for connections"];
	}
}


-(BOOL)isForeground
{
	BasicPhoneAppDelegate* appDelegate = (BasicPhoneAppDelegate*)[UIApplication sharedApplication].delegate;
	return [appDelegate isForeground];
}

-(void)pendingIncomingConnectionReceived:(NSNotification*)notification
{
    NSDictionary* parameters = [notification userInfo];
    
	// Show alert view asking if user wants to accept or reject call
	[self performSelectorOnMainThread:@selector(constructAlert:) withObject:parameters waitUntilDone:NO];
	
	// Check for background support
	if (![self isForeground])
	{
		//App is not in the foreground, so send LocalNotification
		UIApplication* app = [UIApplication sharedApplication];
		UILocalNotification* notification = [[UILocalNotification alloc] init];
		NSArray* oldNots = [app scheduledLocalNotifications];
		
		if ([oldNots count] > 0)
		{
			[app cancelAllLocalNotifications];
		}
		
		notification.alertBody = @"Incoming Call";
		
		[app presentLocalNotificationNow:notification];
	}
	
	[self addStatusMessage:@"-Received incoming connection"];
	[self syncMainButton];	
}

-(void)pendingIncomingConnectionDidDisconnect:(NSNotification*)notification
{
	// Make sure to cancel any pending notifications/alerts
	[self performSelectorOnMainThread:@selector(cancelAlert) withObject:nil waitUntilDone:NO];
	
	if ( ![self isForeground] )
	{
		//App is not in the foreground, so kill the notification we posted.
		UIApplication* app = [UIApplication sharedApplication];
		[app cancelAllLocalNotifications];
	}

	[self addStatusMessage:@"-Pending connection did disconnect"];
	[self syncMainButton];	
}


#pragma mark -
#pragma mark Update UI

-(void)syncMainButton
{
	if ( ![NSThread isMainThread] )
	{
		[self performSelectorOnMainThread:@selector(syncMainButton) withObject:nil waitUntilDone:NO];
		return;
	}
	
	// Sync the main button according to the current connection's state
	if (self.phone.connection)
	{
		if (self.phone.connection.state == TCConnectionStateDisconnected)
		{
			//Connection state is closed, show idle button
			[self.mainButton setImage:[UIImage imageNamed:@"idle"] forState:UIControlStateNormal];
		}
		else if (self.phone.connection.state == TCConnectionStateConnected)
		{
			//Connection state is open, show in progress button
			[self.mainButton setImage:[UIImage imageNamed:@"inprogress"] forState:UIControlStateNormal];
		}
        else if (self.phone.connection.state == TCConnectionStateConnecting)
        {
            [self.mainButton setImage:[UIImage imageNamed:@"predialing"] forState:UIControlStateNormal];
        }
		else
		{
			//Connection is in the middle of connecting. Show dialing button
			[self.mainButton setImage:[UIImage imageNamed:@"dialing"] forState:UIControlStateNormal];
		}
	}
	else
	{
		if (self.phone.pendingIncomingConnection)
		{
			//A pending incoming connection existed, show dialing button
			[self.mainButton setImage:[UIImage imageNamed:@"dialing"] forState:UIControlStateNormal];
		}
		else
		{
			//Both connection and _pending connnection do not exist, show idle button
			[self.mainButton setImage:[UIImage imageNamed:@"idle"] forState:UIControlStateNormal];
		}
	}
}

-(void)addStatusMessage:(NSString*)message
{
	if ( ![NSThread isMainThread] )
	{
		[self performSelectorOnMainThread:@selector(addStatusMessage:) withObject:message waitUntilDone:NO];
		return;
	}
	
	//Update the text view to tell the user what the phone is doing
	self.textView.text = [self.textView.text stringByAppendingFormat:@"\n%@",message];
	
	//Scroll textview automatically for readability
	[self.textView scrollRangeToVisible:NSMakeRange([self.textView.text length], 0)];
}

- (void)updateCapabilitySignals
{
    NSNumber* hasIncoming = [self.phone.device.capabilities objectForKey:TCDeviceCapabilityIncomingKey];
    NSNumber* hasOutgoing = [self.phone.device.capabilities objectForKey:TCDeviceCapabilityOutgoingKey];
    
    UIColor* colorRedLight = [UIColor colorWithRed:(CGFloat)(0xCC)/(255.0f) green:0.0f blue:0.0f alpha:1.0];   // 0xCC0000
    UIColor* colorGreenLight = [UIColor colorWithRed:(CGFloat)(0x33)/(255.0f) green:(CGFloat)(0xCC)/(255.0f) blue:0.0f alpha:1.0];   // 0x33CC00
    [self.viewIncomingSignal setBackgroundColor:([hasIncoming boolValue])? colorGreenLight : colorRedLight ];
    [self.viewOutgoingSignal setBackgroundColor:([hasOutgoing boolValue])? colorGreenLight : colorRedLight ];
}

- (void)btnSelectOutgoingTypeClicked
{
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Outgoing Type" delegate:self
                                                     cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                                                     otherButtonTitles:@"Number", @"Client", nil];
    
    [actionSheet showInView:self.view];
}

#pragma mark -
#pragma mark UIAlertView

-(void)constructAlert:(NSDictionary*)parameters
{
    NSString* title = @"Incoming Call from ";
    title = [title stringByAppendingString:[parameters objectForKey:TCConnectionIncomingParameterFromKey]];
    
	_alertView = [[UIAlertView alloc] initWithTitle:title
											 message:nil
											delegate:self 
								   cancelButtonTitle:nil
								   otherButtonTitles:@"Accept",@"Reject", @"Ignore",nil];
	[_alertView show];
}

-(void)cancelAlert
{
	if ( _alertView )
	{
		[_alertView dismissWithClickedButtonIndex:1 animated:YES];
		_alertView = nil; // autoreleased
	}
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView* )alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{
		//Accept button pressed
		if(!self.phone.connection)
		{
			[self.phone acceptConnection];
		}
		else
		{
			//A connection already existed, so disconnect old connection and connect to current pending connectioon
			[self.phone disconnect];
			
			//Give the client time to reset itself, then accept connection
			[self.phone performSelector:@selector(acceptConnection) withObject:nil afterDelay:0.2];
		}
	}
	else if (buttonIndex == 1)
	{
		// We don't release until after the delegate callback for connectionDidConnect:
		[self.phone rejectIncomingConnection];
	}
    else {
        [self.phone ignoreIncomingConnection];
    }
}

#pragma mark -
#pragma mark Memory managment


@end
