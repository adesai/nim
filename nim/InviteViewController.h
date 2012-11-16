//
//  InviteViewController.h
//  nim
//
//  Created by Ashutosh Desai on 9/6/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullRefresh.h"

@interface InviteViewController : UIViewController <UISearchDisplayDelegate, PullRefreshDelegate>
{
	//Table View to display players to invite
	IBOutlet UITableView *tView;
	
	//Pull to refresh element
	PullRefresh *pr;
	
	//Arrays to hold list of players, and filtered list of players for search
	NSMutableArray *nonPlayers;
	NSMutableArray *filteredNonPlayers;
}

@property UITableView *tView;
@property PullRefresh *pr;
@property NSMutableArray *nonPlayers;

@end
