//
//  ChatViewController.m
//  nim
//
//  Created by Ashutosh Desai on 8/19/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "ChatViewController.h"
#import "AppDelegate.h"
#import "ProfilePictureCache.h"
#import <QuartzCore/QuartzCore.h>

@interface ChatViewController ()

@end

@implementation ChatViewController

@synthesize friendId, tView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		//Initialize the array to empty
		transcript = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	//Get messages from server
	[MGWU getMessagesWithFriend:friendId andCallback:@selector(reload:) onTarget:self];
	//Set variables for text entry field
	[message setReturnKeyType:UIReturnKeyDone];
	[message setDelegate:self];
	
	//Stretch out text entry field if app is in landscape and user has iPhone 5 (longer screen)
	if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && self.view.frame.size.height == 568)
		message.frame = CGRectMake(message.frame.origin.x, message.frame.origin.y, message.frame.size.width+88, message.frame.size.height);
}

- (void)viewWillAppear:(BOOL)animated {
	
	//Register to get alerts when the keyboard is about to appear or hide
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification object:self.view.window];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification object:self.view.window];
	
	//If push notifications are disabled, alert the user that the chat won't be live
	if (noPush)
		[MGWU showMessage:@"Turn on Push Notifications in Settings for live chat" withImage:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	//Unregister for alerts
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(IBAction)refresh:(id)sender
{
	//Hide Keyboard then reload chat, using button instead of pull to refresh because of layout of chat
	[message resignFirstResponder];
	[MGWU getMessagesWithFriend:friendId andCallback:@selector(reload:) onTarget:self];
}

-(void)refresh
{
	//Hide Keyboard then reload chat
	[message resignFirstResponder];
	[MGWU getMessagesWithFriend:friendId andCallback:@selector(reload:) onTarget:self];
}

- (void)reload:(NSMutableArray*)t
{
	//Update transcript and reload the table view
	transcript = t;
	[tView reloadData];
	
	//Scroll to bottom to show newest chats
	if([transcript count] > 0)
	{
		NSUInteger index = [transcript count] - 1;
		[tView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
	}
}

- (IBAction)send:(id)sender
{
	//Hide keyboard
	[message resignFirstResponder];
	//If text input is not empty, send message up to server and empty text input. Callback will reload chat
	if (![[message text] isEqualToString:@""])
	{
		[MGWU sendMessage:message.text toFriend:friendId andCallback:@selector(reload:) onTarget:self];
		[message setText:@""];
	}
}

//Method to hide keyboard when done is pressed
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)keyboardWillShow:(NSNotification *)notif {
	//Animate view to resize along with keyboard displaying
	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];

	int delta;
	if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
		delta = 216;
	else
		delta = 162;
	
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height-delta);
	
	[UIView commitAnimations];
	
	//Scroll to bottom of table view
	if([transcript count] > 0)
	{
		NSUInteger index = [transcript count] - 1;
		if (tView.contentSize.height-tView.contentOffset.y > tView.frame.size.height+delta)
			[tView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
		else
			[tView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
	}
	
}

- (void)keyboardWillHide:(NSNotification *)notif {
	//Animate view to resize along with keyboard hiding
	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
	
	int delta;
	if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
		delta = 216;
	else
		delta = 162;
	
	self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height+delta);
	
	[UIView commitAnimations];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	//Only one section for chat
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	//One row for each message in the transcript
	return [transcript count];
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//Create cell
	static NSString *CellIdentifier = @"Cell";
	
	UIImageView *balloonView;
	UILabel *label;
	UIImageView *pictureView;
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		
		//Balloon View displays chat bubble
		balloonView = [[UIImageView alloc] initWithFrame:CGRectZero];
		balloonView.tag = 1;
		
		//Label displays message
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.backgroundColor = [UIColor clearColor];
		label.tag = 2;
		label.numberOfLines = 0;
		label.lineBreakMode = UILineBreakModeWordWrap;
		label.font = [UIFont systemFontOfSize:14.0];
		
		//Picture displays profile picture of message sender
		pictureView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fbdefault.png"]];
		pictureView.tag = 3;
		
		//Add subviews to messageview, and add messageview to cell
		UIView *messageview = [[UIView alloc] initWithFrame:CGRectMake(0.0, 2.0, cell.frame.size.width, cell.frame.size.height-2)];
		messageview.tag = 0;
		[messageview addSubview:balloonView];
		[messageview addSubview:label];
		[messageview addSubview:pictureView];
		[cell.contentView addSubview:messageview];
		
	}
	else
	{
		//If reusing a cell, simply update elements
		balloonView = (UIImageView *)[[cell.contentView viewWithTag:0] viewWithTag:1];
		label = (UILabel *)[[cell.contentView viewWithTag:0] viewWithTag:2];
		pictureView = (UIImageView *)[[cell.contentView viewWithTag:0] viewWithTag:3];
		pictureView.image = [UIImage imageNamed:@"fbdefault.png"];
	}
	
	//Set size and placement of subviews based on message length
	NSString *text = [[transcript objectAtIndex:indexPath.row] objectForKey:@"message"];
	CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(self.view.bounds.size.width-80-40, self.view.bounds.size.height) lineBreakMode:UILineBreakModeWordWrap];
	
	UIImage *balloon;
	
	if ([[[transcript objectAtIndex:indexPath.row] objectForKey:@"from"] isEqualToString:[user objectForKey:@"username"]])
	{
		balloonView.frame = CGRectMake(self.view.bounds.size.width-40 - (size.width + 28.0f), 2.0f, size.width + 28.0f, size.height + 15.0f);
		balloon = [[UIImage imageNamed:@"green.png"] stretchableImageWithLeftCapWidth:24 topCapHeight:15];
		label.frame = CGRectMake((self.view.bounds.size.width-13-40) - (size.width + 5.0f), 8.0f, size.width + 5.0f, size.height);
		
		pictureView.frame = CGRectMake(self.view.bounds.size.width - (40.f), size.height-18.f, 34.f, 34.f);
	}
	else
	{
		balloonView.frame = CGRectMake(40.0, 2.0, size.width + 28, size.height + 15);
		balloon = [[UIImage imageNamed:@"grey.png"] stretchableImageWithLeftCapWidth:24 topCapHeight:15];
		label.frame = CGRectMake(16+40, 8, size.width + 5, size.height);
		
		pictureView.frame = CGRectMake(6.f, size.height-18.f, 34.f, 34.f);
	}
	
	//Asynchronously load profile picture
	[ProfilePictureCache setProfilePicture:[[transcript objectAtIndex:indexPath.row] objectForKey:@"from"] forImageView:pictureView inTableView:tableView forIndexPath:indexPath];
	
	//Add border radius to profile picture
	CALayer *l = [pictureView layer];
	[l setMasksToBounds:YES];
	[l setCornerRadius:5.0];
	
	//Set balloon image and label text
	balloonView.image = balloon;
	label.text = text;
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	//Set variable height of cell based on length of message
	NSString *body = [[transcript objectAtIndex:indexPath.row] objectForKey:@"message"];
	CGSize size = [body sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(self.view.bounds.size.width-80-40, self.view.bounds.size.height) lineBreakMode:UILineBreakModeWordWrap];
	return size.height + 22;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == [[UIApplication sharedApplication] statusBarOrientation]);
}

@end
