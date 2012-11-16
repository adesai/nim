//
//  SecondViewController.m
//  nim
//
//  Created by Ashutosh Desai on 7/11/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "PlayersViewController.h"
#import "AppDelegate.h"
#import "GameViewController.h"
#import "TabBarController.h"
#import "ProfilePictureCache.h"

@interface PlayersViewController ()

@end

@implementation PlayersViewController

@synthesize tView, pr, players, recommendedFriends, newFriends;

- (void)viewWillAppear:(BOOL)animated
{
	//Set nav bar title
	self.tabBarController.navigationItem.title = @"Players";
	
	//Set new friends to 0 and set badge value to nil (when the view is being shown these are reset)
	newFriends = 0;
	self.tabBarItem.badgeValue = nil;
}

- (void)refresh
{
	//Refresh tabBarController to reload games
	[(TabBarController*)self.tabBarController refresh];
	
	//Set new friends to 0 and set badge value to nil (when the view is being shown these are reset)
	newFriends = 0;
	self.tabBarItem.badgeValue = nil;
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

//Three sections in table view, first section has random buttons, then recommended friends, then all friends
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return [MGWU getUsername];
	else if (section == 1)
		return @"Recommended Friends";
	else
		return @"All Friends";
}

//Set number of rows based on sections, first section will have 2, next two depend on arrays
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 2;
	else if (section == 1)
		return [recommendedFriends count];
	else
		return [players count];
}

//The sectionIndexTitles are for the scroll bar on the right (such as in the iPod app), only kick into gear if you have more than 20 friends playing the app
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *charactersForSort = [[NSMutableArray alloc] init];
	
	if ([players count] < 20)
		return charactersForSort;
	
	[charactersForSort addObject:@"#"];
	for (NSDictionary *item in players)
	{
		if (![charactersForSort containsObject:[[item valueForKey:@"name"] substringToIndex:1]])
		{
			[charactersForSort addObject:[[item valueForKey:@"name"] substringToIndex:1]];
		}
	}
	return charactersForSort;
}

//Allows you to use the scroll bar on the right to scroll to a letter
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if ([title isEqualToString:@"#"])
		[tView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
	else
	{
		BOOL found = NO;
		NSInteger b = 0;
		for (NSDictionary *item in players)
		{
			if ([[[item valueForKey:@"name"] substringToIndex:1] isEqualToString:title])
				if (!found)
				{
					[tView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:b inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:NO];
					found = YES;
				}
			b++;
		}
	}
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//Create cell based on section (the different CellIdentifiers are connected to different segue's in the storyboard)
	static NSString *CellIdentifier;
	if (indexPath.section == 0)
		CellIdentifier = @"RandomCell";
	else if (indexPath.section == 1)
		CellIdentifier = @"RecommendedCell";
	else
		CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc]
				initWithStyle:UITableViewCellStyleValue1
				reuseIdentifier:CellIdentifier];
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	}
	
	cell.imageView.image = [UIImage imageNamed:@"fbdefault.png"];
	
	//Set name and action based on cell
	NSString *name;
	NSString *action = @"Play";
	//First section has random friend and random player
	if (indexPath.section == 0)
	{
		if (indexPath.row == 0)
			name = @"Random Friend";
		else
			name = @"Random";
	}
	//Second section has recommended friends, using play or invite depending on whether the friend plays the game
	else if (indexPath.section == 1)
	{
		name = [[recommendedFriends objectAtIndex:indexPath.row] objectForKey:@"name"];
		NSString *uname = [[recommendedFriends objectAtIndex:indexPath.row] objectForKey:@"username"];
		[ProfilePictureCache setProfilePicture:uname forImageView:cell.imageView inTableView:tableView forIndexPath:indexPath];
		if (indexPath.row == 2 || indexPath.row >= [players count])
			action = @"Invite!";
	}
	//Third section has friends who play the game
	else
	{
		name = [[players objectAtIndex:indexPath.row] objectForKey:@"name"];
		NSString *uname = [[players objectAtIndex:indexPath.row] objectForKey:@"username"];
		[ProfilePictureCache setProfilePicture:uname forImageView:cell.imageView inTableView:tableView forIndexPath:indexPath];
	}
	
	//Set text of name and action
	cell.textLabel.text = name;
	cell.detailTextLabel.text = action;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//For random section
	if (indexPath.section == 0)
	{
		//If random friend, start a game with a random available friend
		if (indexPath.row == 0)
		{
			if ([players count] < 1)
				[MGWU showMessage:@"Already playing with all friends" withImage:nil];
			else
			{
				int i = arc4random()%[players count];
				GameViewController *gvc = [self.storyboard instantiateViewControllerWithIdentifier:@"GameViewController"];
				gvc.opponent = [[players objectAtIndex:i] objectForKey:@"username"];
				[self.navigationController pushViewController:gvc animated:YES];
			}
		}
		//If random player, load random player from the server, callback will begin game
		else
			[MGWU getRandomPlayerWithCallback:@selector(gotPlayer:) onTarget:self];
	}
	//If recommended friend, start a game with the friend
	else if (indexPath.section == 1)
	{
		//If it's a friend who isn't playing, invite them on facebook
		if (indexPath.row == 2 || indexPath.row >= [players count])
			[MGWU inviteFriend:[[recommendedFriends objectAtIndex:indexPath.row] objectForKey:@"username"] withMessage:@"Play a game with me!"];
		GameViewController *gvc = (GameViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"GameViewController"];
		gvc.opponent = [[recommendedFriends objectAtIndex:indexPath.row] objectForKey:@"username"];
		[self.navigationController pushViewController:gvc animated:YES];
	}
	//Remove highlight from selected cell
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(IBAction)search:(id)sender
{
	//Hide keyboard and search for player with username, callback begins a game with the player
	[searchbox resignFirstResponder];
	[MGWU getPlayerWithUsername:searchbox.text withCallback:@selector(gotPlayer:) onTarget:self];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
	//Hide keyboard when done clicked
    [textField resignFirstResponder];
    return YES;
}

-(void)gotPlayer:(NSDictionary*)p
{
	//If player doesn't exist (no player of that username), do nothing
	if (!p)
		return;

	//Start game with player
    GameViewController *gvc = [self.storyboard instantiateViewControllerWithIdentifier:@"GameViewController"];
	gvc.opponent = [p objectForKey:@"username"];
	[self.navigationController pushViewController:gvc animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	//If transitioning to game from list of players, start game with the player
    if([[segue identifier] isEqualToString:@"beginGame"]){
		UITableViewCell *tvc = (UITableViewCell*)sender;
		NSIndexPath *indexPath = [tView indexPathForCell:tvc];
		GameViewController *gvc = (GameViewController *)[segue destinationViewController];
		gvc.opponent = [[players objectAtIndex:indexPath.row] objectForKey:@"username"];
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	//Set properties of searchbox
	searchbox.delegate = self;
	[searchbox setReturnKeyType:UIReturnKeyDone];
	[searchbox setAutocorrectionType:UITextAutocorrectionTypeNo];
	[searchbox setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	
	//If app is in landscape orientation and device is iPhone 5, expand searchbox
	if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && self.view.frame.size.height == 568) //Since rotation is not done until viewDidAppear
		searchbox.frame = CGRectMake(searchbox.frame.origin.x, searchbox.frame.origin.y, searchbox.frame.size.width+88, searchbox.frame.size.height);
	
	//Create pull to refresh element
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
