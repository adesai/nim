//
//  FirstViewController.m
//  nim
//
//  Created by Ashutosh Desai on 7/11/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "GamesViewController.h"
#import "AppDelegate.h"
#import "GameViewController.h"
#import "TabBarController.h"
#import "ProfilePictureCache.h"
#import "TDBadgedCell.h"

@interface GamesViewController ()

@end

@implementation GamesViewController

@synthesize games, gamesCompleted, gamesYourTurn, gamesTheirTurn, tView, pr;

- (void)viewWillAppear:(BOOL)animated
{
	//Set nav bar title
	self.tabBarController.navigationItem.title = @"Games";
}

- (void)refresh
{
	//Refresh tabBarController to reload games
	[(TabBarController*)self.tabBarController refresh];
}

//Methods for pull to refresh, will automatically call "refresh" when pulled
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[pr scrollViewWillBeginDragging:scrollView];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[pr scrollViewDidScroll:scrollView];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[pr scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

//3 sections in table view, your turn, waiting for opponent, completed games
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return @"Your Turn";
	else if (section == 1)
		return @"Waiting for Opponent";
	else
		return @"Completed";
}

//Set number of rows based on arrays of games (filtered in tabBarController)
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return [gamesYourTurn count];
	else if (section == 1)
		return [gamesTheirTurn count];
	else
		return [gamesCompleted count];
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//Create cell as TDBadgedCell (to show new message count)
	static NSString *CellIdentifier = @"Cell";
    TDBadgedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TDBadgedCell alloc]
                 initWithStyle:UITableViewCellStyleValue1 
                 reuseIdentifier:CellIdentifier];
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
	
	NSDictionary *game;
	
	//Set action text based on the state of the game
	NSString* action = @"View";
	if (indexPath.section == 0)
	{
		game = [gamesYourTurn objectAtIndex:indexPath.row];
		action = @"Play";
	}
	else if (indexPath.section == 1)
		game = [gamesTheirTurn objectAtIndex:indexPath.row];
	else
	{
		int i = [gamesCompleted count] - indexPath.row - 1;
		game = [gamesCompleted objectAtIndex:i];
		if ([[[game objectForKey:@"gamedata"] objectForKey:@"winner"] isEqualToString:[user objectForKey:@"username"]])
			action = @"Won";
		else
			action = @"Lost";
	}


	//Set name as friendName (if you're facebook friends) or username
	NSString* name = [game objectForKey:@"friendName"];
	if (!name)
	{
		NSArray* players = [game objectForKey:@"players"];
		if ([[players objectAtIndex:0] isEqualToString:[user objectForKey:@"username"]])
			name = [players objectAtIndex:1];
		else
			name = [players objectAtIndex:0];
	}
	
	//Set badge number based on how many newmessages in each game
	int newmessages = [[game objectForKey:@"newmessages"] intValue];
	if (newmessages > 0)
		cell.badgeString = [NSString stringWithFormat:@"%d", newmessages];
	else
		cell.badgeString = nil;
	
	//Set labels for name and action
	cell.textLabel.text = name;
	cell.detailTextLabel.text = action;
	
	//Asynchronously load profile picture of opponent
	NSString *uname;
	NSArray* players = [game objectForKey:@"players"];
	if ([[players objectAtIndex:0] isEqualToString:[user objectForKey:@"username"]])
		uname = [players objectAtIndex:1];
	else
		uname = [players objectAtIndex:0];
	
	cell.imageView.image = [UIImage imageNamed:@"fbdefault.png"];
	[ProfilePictureCache setProfilePicture:uname forImageView:cell.imageView inTableView:tableView forIndexPath:indexPath];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//Remove highlight on selected cell
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	//If transitioning to game, set the game depending on which cell was selected
    if([[segue identifier] isEqualToString:@"openGame"]){
		UITableViewCell *tvc = (UITableViewCell*)sender;
		NSIndexPath *indexPath = [tView indexPathForCell:tvc];
		GameViewController *gvc = (GameViewController *)[segue destinationViewController];
		
		if (indexPath.section == 0)
			gvc.game = [gamesYourTurn objectAtIndex:indexPath.row];
		else if (indexPath.section == 1)
			gvc.game = [gamesTheirTurn objectAtIndex:indexPath.row];
		else
			gvc.game = [gamesCompleted objectAtIndex:indexPath.row];
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	//Create Pull to Refresh
	pr = [[PullRefresh alloc] initWithDelegate:self];
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
