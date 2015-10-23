//
//  Copyright 2013-2015 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//
 
#import <UIKit/UIKit.h>

@class BasicPhone;

@interface BasicPhoneViewController : UIViewController 
{
	BasicPhone* _phone;
	
	UIButton* _mainButton;
	UITextView* _textView;
	UISwitch* _speakerSwitch;
	UIAlertView* _alertView;
}

@property (nonatomic,strong) IBOutlet UIButton* mainButton;
@property (nonatomic,strong) IBOutlet UITextView* textView;
@property (nonatomic,strong) IBOutlet UISwitch* speakerSwitch;
@property (nonatomic,strong) BasicPhone* phone;

//Button actions
-(IBAction)mainButtonPressed:(id)sender;
-(IBAction)speakerSwitchPressed:(id)sender;

@end

