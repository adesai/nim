//
//  MenuViewController.m
//  nim
//
//  Created by Ashutosh Desai on 7/31/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "MenuViewController.h"

@interface MenuViewController ()

@end

@implementation MenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//Buttons to demonstrate features of SDK

- (IBAction)moreGames:(id)sender
{
	[MGWU displayCrossPromo];
}

- (IBAction)about:(id)sender
{
	[MGWU displayAboutPage];
}

- (IBAction)likeMGWU:(id)sender
{
	[MGWU likeMGWU];
}

- (IBAction)likeNim:(id)sender
{
	[MGWU likeAppWithPageId:@"155368531182767"];
}

- (IBAction)inviteFriends:(id)sender
{
	[MGWU inviteFriendsWithMessage:@"Check out this cool app!"];
}

- (IBAction)share:(id)sender
{
	[MGWU shareWithTitle:@"Nim" caption:@"The best multiplayer iPhone Game" andDescription:@"I'm beating you!!!"];
}

- (IBAction)contact:(id)sender
{
	[MGWU displayHipmob];
}

- (IBAction)testBuy:(id)sender
{
	[MGWU testBuyProduct:@"com.mgwu.kw.5000C" withCallback:@selector(test:) onTarget:self];
}

- (IBAction)buy:(id)sender
{
	[MGWU buyProduct:@"com.mgwu.kw.CD" withCallback:@selector(test:) onTarget:self];
}

- (IBAction)testRestore:(id)sender
{
	[MGWU testRestoreProducts:@[@"com.mgwu.kw.CD"] withCallback:@selector(test:) onTarget:self];
}

- (IBAction)restore:(id)sender
{
	[MGWU restoreProductsWithCallback:@selector(test:) onTarget:self];
}

-(void)test:(NSArray*)dude
{
	NSLog(@"foo");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
