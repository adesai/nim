//
//  FirstViewController.h
//  nim
//
//  Created by Ashutosh Desai on 7/11/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullRefresh.h"

@interface GamesViewController : UIViewController <PullRefreshDelegate>
{
	//Arrays to store games based on status
	NSMutableArray *games;
	NSMutableArray *gamesYourTurn;
	NSMutableArray *gamesTheirTurn;
	NSMutableArray *gamesCompleted;
	
	//Table view to display games
	IBOutlet UITableView *tView;
	
	//Pull to refresh element
	PullRefresh *pr;
}

@property NSMutableArray *games, *gamesYourTurn, *gamesTheirTurn, *gamesCompleted;
@property UITableView *tView;
@property PullRefresh *pr;

@end
