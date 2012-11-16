//
//  TabBarController.m
//  nim
//
//  Created by Ashutosh Desai on 9/3/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "TabBarController.h"
#import "AppDelegate.h"

@interface TabBarController ()

@end

@implementation TabBarController

@synthesize pvc;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	//Set references to the actual view controllers
	gvc = (GamesViewController*)[self.viewControllers objectAtIndex:0];
	pvc = (PlayersViewController*)[self.viewControllers objectAtIndex:1];
	ivc = (InviteViewController*)[self.viewControllers objectAtIndex:2];
	
}

//When the view is about to appear, getMyInfo
- (void)viewWillAppear:(BOOL)animated
{
	[MGWU getMyInfoWithCallback:@selector(loadedUserInfo:) onTarget:self];
}

//Refresh user info
- (void)refresh
{
	[MGWU getMyInfoWithCallback:@selector(loadedUserInfo:) onTarget:self];
}

//Callback for getmyInfo
- (void)loadedUserInfo:(NSMutableDictionary*)userInfo
{
	//Set variables to save data retrieved
	user = [userInfo objectForKey:@"info"];
	gvc.games = [userInfo objectForKey:@"games"];
	pvc.players = [userInfo objectForKey:@"friends"];//[[NSMutableArray alloc] init];
	ivc.nonPlayers = [MGWU friendsToInvite];
	
	//Set badge number for new friends when they join the game
	int numOldFriends = [[NSUserDefaults standardUserDefaults] integerForKey:@"numFriends"];
	int numNewFriends = [pvc.players count];
	[[NSUserDefaults standardUserDefaults] setInteger:numNewFriends forKey:@"numFriends"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	if (numNewFriends > numOldFriends)
	{
		pvc.newFriends += numNewFriends-numOldFriends;
	}
	
	
	//Sort games by dateplayed
	NSArray *sortedGames = [gvc.games sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
		NSNumber *first = [a objectForKey:@"dateplayed"];
		NSNumber *second = [b objectForKey:@"dateplayed"];
		return [second compare:first];
	}];
	
	gvc.games = [NSMutableArray arrayWithArray:sortedGames];
	
	
	//Split up games based on whose turn it is / whether the game is over
	gvc.gamesCompleted = [[NSMutableArray alloc] init];
	gvc.gamesYourTurn = [[NSMutableArray alloc] init];
	gvc.gamesTheirTurn = [[NSMutableArray alloc] init];
	
	NSString *username = [user objectForKey:@"username"];
	
	for (NSMutableDictionary *game in gvc.games)
	{
		NSString* gameState = [game objectForKey:@"gamestate"];
		NSString* turn = [game objectForKey:@"turn"];
		
		NSString* oppName;
		NSArray* gamers = [game objectForKey:@"players"];
		if ([[gamers objectAtIndex:0] isEqualToString:username])
			oppName = [gamers objectAtIndex:1];
		else
			oppName = [gamers objectAtIndex:0];

		if ([gameState isEqualToString:@"ended"])
		{
			[gvc.gamesCompleted addObject:game];
			for (NSMutableDictionary *friend in pvc.players)
			{
				//Add friendName to game if you're friends
				if ([[friend objectForKey:@"username"] isEqualToString:oppName])
				{
					[game setObject:[friend objectForKey:@"name"] forKey:@"friendName"];
					break;
				}
			}
		}
		else if ([turn isEqualToString:[user objectForKey:@"username"]])
		{
			[gvc.gamesYourTurn addObject:game];
			for (NSMutableDictionary *friend in pvc.players)
			{
				//Add friendName to game if you're friends, remove the friend from list of players (so you can't start a new game with someone you're already playing)
				if ([[friend objectForKey:@"username"] isEqualToString:oppName])
				{
					[game setObject:[friend objectForKey:@"name"] forKey:@"friendName"];
					[pvc.players removeObject:friend];
					break;
				}
			}
		}
		else
		{
			[gvc.gamesTheirTurn addObject:game];
			for (NSMutableDictionary *friend in pvc.players)
			{
				//Add friendName to game if you're friends, remove the friend from list of players (so you can't start a new game with someone you're already playing)
				if ([[friend objectForKey:@"username"] isEqualToString:oppName])
				{
					[game setObject:[friend objectForKey:@"name"] forKey:@"friendName"];
					[pvc.players removeObject:friend];
					break;
				}
			}
		}
	}
	
	//Create set of recommended friends
	pvc.recommendedFriends = [[NSMutableArray alloc] init];
	
	NSMutableArray *randomPlayingFriends = [NSMutableArray arrayWithArray:pvc.players];
	NSMutableArray *randomNonPlayingFriends = [NSMutableArray arrayWithArray:[MGWU friendsToInvite]];
	
	//Shuffle list of friends who play the game
	if ([randomPlayingFriends count] > 0)
	{
		for (NSUInteger i = [randomPlayingFriends count] - 1; i >= 1; i--)
		{
			u_int32_t j = arc4random_uniform(i + 1);
			
			[randomPlayingFriends exchangeObjectAtIndex:j withObjectAtIndex:i];
		}
	}
	
	//Shuffle list of friends who don't play yet
	if ([randomNonPlayingFriends count] > 0)
	{
		for (NSUInteger i = [randomNonPlayingFriends count] - 1; i >= 1; i--)
		{
			u_int32_t j = arc4random_uniform(i + 1);
			
			[randomNonPlayingFriends exchangeObjectAtIndex:j withObjectAtIndex:i];
		}
	}
	
	int i;
	//First add up to 2 friends who currently play the game
	for (i = 0; i < 2 && i < [randomPlayingFriends count]; i++)
	{
		[pvc.recommendedFriends addObject:[randomPlayingFriends objectAtIndex:i]];
	}
	//Then add friends who don't play for a maximum of 3 total recommended friends
	for (int j = i; j < 3 && (j-i < [randomNonPlayingFriends count]); j++)
	{
		[pvc.recommendedFriends addObject:[randomNonPlayingFriends objectAtIndex:j]];
	}
	
	//Set badges on tab bar based on games that are your turn and new friends who are playing
	gvc.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [gvc.gamesYourTurn count]];
	if (pvc.newFriends == 0)
		pvc.tabBarItem.badgeValue = nil;
	else
		pvc.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", pvc.newFriends];
	
	//Reload all views, and stop all pull to refresh from happening
	[gvc.tView reloadData];
	[gvc.pr stopLoading];
	[pvc.tView reloadData];
	[pvc.pr stopLoading];
	[ivc.tView reloadData];
	[ivc.pr stopLoading];
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
