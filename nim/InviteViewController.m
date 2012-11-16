//
//  InviteViewController.m
//  nim
//
//  Created by Ashutosh Desai on 9/6/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "InviteViewController.h"
#import "AppDelegate.h"
#import "GameViewController.h"
#import "TabBarController.h"
#import "ProfilePictureCache.h"

@interface InviteViewController ()

@end

@implementation InviteViewController

@synthesize tView, pr, nonPlayers;

- (void)viewWillAppear:(BOOL)animated
{
	//Set nav bar title
	self.tabBarController.navigationItem.title = @"Invite";
}

- (void)refresh
{
	//Refresh tabBarController to reload list of friends to invite
	[(TabBarController*)self.tabBarController refresh];
}

//Methods for pull to refresh, refresh will be automatically called when pulled
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[pr scrollViewWillBeginDragging:scrollView];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[pr scrollViewDidScroll:scrollView];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[pr scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

//Depending on whether table is regular or filtered, set number of rows
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.searchDisplayController.searchResultsTableView)
        return [filteredNonPlayers count];
	else
		return [nonPlayers count];
}

//The sectionIndexTitles are for the scroll bar on the right (such as in the iPod app), only kick into gear if you have more than 20 friends playing the app
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *charactersForSort = [[NSMutableArray alloc] init];
	
	if (tableView == self.searchDisplayController.searchResultsTableView || [nonPlayers count] < 20)
        return charactersForSort;
	
	for (NSDictionary *item in nonPlayers)
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
    BOOL found = NO;
    NSInteger b = 0;
    for (NSDictionary *item in nonPlayers)
    {
        if ([[[item valueForKey:@"name"] substringToIndex:1] isEqualToString:title])
            if (!found)
            {
                [tView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:b inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                found = YES;
            }
        b++;
    }
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//Create cell
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc]
				initWithStyle:UITableViewCellStyleValue1
				reuseIdentifier:CellIdentifier];
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	}
	
	//Set name and username based on which table (filtered or unfiltered)
	NSString *name;
	NSString *uname;
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		name = [[filteredNonPlayers objectAtIndex:indexPath.row] objectForKey:@"name"];
		uname = [[filteredNonPlayers objectAtIndex:indexPath.row] objectForKey:@"username"];
	}
	else
	{
		name = [[nonPlayers objectAtIndex:indexPath.row] objectForKey:@"name"];
		uname = [[nonPlayers objectAtIndex:indexPath.row] objectForKey:@"username"];
	}
	
	NSString *action = @"Invite!";
	
	//Set name and action text
	cell.textLabel.text = name;
	cell.detailTextLabel.text = action;
	
	//Asynchronously load profile picture
	cell.imageView.image = [UIImage imageNamed:@"fbdefault.png"];
	[ProfilePictureCache setProfilePicture:uname forImageView:cell.imageView inTableView:tableView forIndexPath:indexPath];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//Filtered table can't use segue, invite friend on facebook then create game
	if (tableView == self.searchDisplayController.searchResultsTableView)
	{
		[MGWU inviteFriend:[[filteredNonPlayers objectAtIndex:indexPath.row] objectForKey:@"username"] withMessage:@"Play a game with me!"];
		[self.searchDisplayController setActive:NO animated:YES];
		GameViewController *gvc = (GameViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"GameViewController"];
		gvc.opponent = [[nonPlayers objectAtIndex:indexPath.row] objectForKey:@"username"];
		[self.navigationController pushViewController:gvc animated:YES];
	}
	//For unfiltered table, simply invite friend on facebook
	else
	{
		[MGWU inviteFriend:[[nonPlayers objectAtIndex:indexPath.row] objectForKey:@"username"] withMessage:@"Play a game with me!"];
	}
	//Remove highlight on selected cell
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	//If transitioning to game, start game with player
    if([[segue identifier] isEqualToString:@"beginGame"]){
		UITableViewCell *tvc = (UITableViewCell*)sender;
		NSIndexPath *indexPath = [tView indexPathForCell:tvc];
		GameViewController *gvc = (GameViewController *)[segue destinationViewController];
		gvc.opponent = [[nonPlayers objectAtIndex:indexPath.row] objectForKey:@"username"];
	}
}

- (void)filterContentForSearchText:(NSString*)searchText
{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	
	[filteredNonPlayers removeAllObjects]; // First clear the filtered array.
	
	/*
	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
	for (NSDictionary *f in nonPlayers)
	{
		//Match names if they contain the searched value as a substring
		BOOL match = FALSE;
		NSArray *names = [[f objectForKey:@"name"] componentsSeparatedByString:@" "];
		for (NSString *name in names)
		{
			NSComparisonResult result = [name compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
			if (result == NSOrderedSame)
			{
				match = TRUE;
			}
		}
		if (match)
			[filteredNonPlayers addObject:f];
	}
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	//Filter content by search criteria
    [self filterContentForSearchText:searchString];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	//Create filteredNonPlayers array
	filteredNonPlayers = [[NSMutableArray alloc] init];
	
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
