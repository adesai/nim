//
//  GameViewController.m
//  nim
//
//  Created by Ashutosh Desai on 7/11/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "GameViewController.h"
#import "AppDelegate.h"
#import "ChatViewController.h"
#import "ProfilePictureCache.h"
#import "TabBarController.h"
#import "MKNumberBadgeView.h"
#import <QuartzCore/QuartzCore.h>

@interface GameViewController ()

@end

@implementation GameViewController

@synthesize game, opponent;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		//When view is created, set loaded to false
		loaded = false;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	//Load the game
	[self loadGame];
	
	//Display smackTalk button only if opponent is a facebook friend
	if (![MGWU isFriend:opponent])
		[smackTalk setHidden:YES];
	
	//Set images to default images, then load them asynchronously
	otherGuy.image = [UIImage imageNamed:@"fbdefault.png"];
	me.image = [UIImage imageNamed:@"fbdefault"];
	
	[ProfilePictureCache setProfilePicture:opponent forImageView:otherGuy];
	[ProfilePictureCache setProfilePicture:[user objectForKey:@"username"] forImageView:me];
	
}

- (void)viewWillAppear:(BOOL)animated
{
	//Only reload the game if returning from chat view (since getMyInfo preloads all the games)
	//If loaded is false then the view has just been created from the list of games and doesn't need to be reloaded
	if (loaded)
		[MGWU getGame:[[game objectForKey:@"gameid"] intValue] withCallback:@selector(gotGame:) onTarget:self];
	else
		loaded = true;
}

- (void)gotGame:(NSMutableDictionary*)g
{
	//Update game object and reload game
	game = g;
	[self loadGame];
}

- (void) loadGame
{
	//If game doesn't exist yet
	if (!game)
	{
		//Flag it as a new game, and set game specific variables to reflect a new game
		new = TRUE;
		info.text = [NSString stringWithFormat:@"Begin Game Against %@", opponent];
		[pick setTitle:@"Pick" forState:UIControlStateNormal];
		[slider setEnabled:YES];
		[slider setValue:1];
		[board setText:@"| | | | | | | | | | |"];
		[number setText:[NSString stringWithFormat:@"%d", (int)[slider value]]];
	}
	//If game already exists
	else
	{
		//Flag it as a game in progress
		new = FALSE;
		
		NSString* gameState = [game objectForKey:@"gamestate"];
		NSString* turn = [game objectForKey:@"turn"];
		
		//Set opponent name from list of players
		NSArray* players = [game objectForKey:@"players"];
		if ([[players objectAtIndex:0] isEqualToString:[user objectForKey:@"username"]])
			opponent = [players objectAtIndex:1];
		else
			opponent = [players objectAtIndex:0];
		
		//Based on state of game, set game specific variables
		if ([gameState isEqualToString:@"ended"])
		{
			info.text = [NSString stringWithFormat:@"Completed Game Against %@", opponent];
			[number setText:@" "];
			[slider setEnabled:NO];
			[pick setTitle:@"Rematch" forState:UIControlStateNormal];
			//[pick setEnabled:NO];
		}
		else if ([turn isEqualToString:[user objectForKey:@"username"]])
		{
			info.text = [NSString stringWithFormat:@"Your Turn Against %@", opponent];
			[pick setTitle:@"Pick" forState:UIControlStateNormal];
			[slider setEnabled:YES];
			[number setText:[NSString stringWithFormat:@"%d", (int)[slider value]]];
		}
		else
		{
			info.text = [NSString stringWithFormat:@"Waiting for %@", opponent];
			[number setText:@" "];
			[slider setEnabled:NO];
			[pick setTitle:@"Refresh" forState:UIControlStateNormal];
//			[pick setEnabled:NO];
		}
		
		//Set board to reflect gameData
		NSDictionary *gameData = [game objectForKey:@"gamedata"];
		board.text = [gameData objectForKey:@"board"];
	}
}

- (IBAction)sliderChanged:(id)sender
{
	//Set number to reflect slider
	number.text = [NSString stringWithFormat:@"%d", (int)round([slider value])];
	//Make slider discrete instead of continuous
	slider.value = (int)round([slider value]);
}

- (void)refresh
{
	//If game object exists, reload the game
	if (game)
		[MGWU getGame:[[game objectForKey:@"gameid"] intValue] withCallback:@selector(gotGame:) onTarget:self];
}

//Action to make a move, refresh the game, or start a rematch
- (IBAction)pick:(id)sender
{
	//If game doesn't exist, start a game with the initial move
	if (!game)
	{
		NSNumber *picked = [NSNumber numberWithInt:[number.text intValue]];
		NSNumber *sticks = [NSNumber numberWithInt:(11-[picked intValue])];
		NSString* b = @"|";
		for (int i = 1; i < [sticks intValue]; i++)
			b = [b stringByAppendingString:@" |"];
		
		NSDictionary *gameData = [[NSDictionary alloc] initWithObjectsAndKeys:sticks, @"sticks", b, @"board", nil];
		
		NSDictionary *move = [[NSDictionary alloc] initWithObjectsAndKeys:picked, @"picked", nil];
		[MGWU move:move withMoveNumber:0 forGame:0 withGameState:@"started" withGameData:gameData againstPlayer:opponent withPushNotificationMessage:@"test" withCallback:@selector(moveCompleted:) onTarget:self];
	}
	else {
		//If it is not your turn, refresh the game
		if ([[[pick titleLabel] text] isEqualToString:@"Refresh"])
		{
			[self refresh];
			return;
		}
		//If the game is over, start a new game
		else if ([[[pick titleLabel] text] isEqualToString:@"Rematch"])
		{
			game = nil;
			[self loadGame];
			return;
		}
		
		//If the game is in progress, send move to server, deciding locally whether the game is over / who won
		NSDictionary *oldGameData = [game objectForKey:@"gamedata"];
		int gameID = [[game objectForKey:@"gameid"] intValue];
		
		NSNumber *picked = [NSNumber numberWithInt:[number.text intValue]];
		NSNumber *left = [oldGameData objectForKey:@"sticks"];
		NSDictionary *move = [[NSDictionary alloc] initWithObjectsAndKeys:picked, @"picked", nil];
		int moveNumber = [[game objectForKey:@"movecount"] intValue] +1;
		NSNumber *sticks = [NSNumber numberWithInt:([left intValue] - [picked intValue])];
		
		NSString *b;
		NSString *gameState;
		NSString *winner;
		if ([picked intValue] >= [left intValue])
		{
			gameState = @"ended";
			b = [NSString stringWithFormat:@"%@ Won!", [user objectForKey:@"username"]];
			winner = [user objectForKey:@"username"];
		}
		else
		{
			gameState = @"inprogress";
			b = @"|";
			for (int i = 1; i < [sticks intValue]; i++)
				b = [b stringByAppendingString:@" |"];
		}
		
		NSDictionary *gameData = [[NSDictionary alloc] initWithObjectsAndKeys:sticks, @"sticks", b, @"board", winner, @"winner", nil];
		
		[MGWU move:move withMoveNumber:moveNumber forGame:gameID withGameState:gameState withGameData:gameData againstPlayer:opponent withPushNotificationMessage:@"test" withCallback:@selector(moveCompleted:) onTarget:self];
	}
}

- (void)moveCompleted:(NSMutableDictionary*)newGame
{
	//Refresh the game once a move has been made
	game = newGame;
	[self loadGame];
	
	//Remove the opponent from the list of players in case you just started a new game
	[[[(TabBarController*)self.tabBarController pvc] players] removeObject:opponent];
}

- (IBAction)smackTalk:(id)sender
{
	//Post to friends' wall
	[MGWU postToFriendsWall:opponent withTitle:@"Nim" caption:@"The best multiplayer iPhone Game" andDescription:@"I'm beating you!!!"];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	//If you're opening the chat view, set the opponent before the transition (segue)
    if([[segue identifier] isEqualToString:@"openChat"]){
		ChatViewController *cvc = (ChatViewController*)[segue destinationViewController];
		cvc.friendId = opponent;
	}
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
