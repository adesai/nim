//
//  GameViewController.h
//  nim
//
//  Created by Ashutosh Desai on 7/11/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameViewController : UIViewController
{
	//Dictionary containing game object
	NSMutableDictionary *game;
	//Username of opponenet
	NSString *opponent;
	//Variable to save whether the game is being created
	BOOL new;
	
	//Game specific UIElements
	IBOutlet UILabel *info;
	IBOutlet UILabel *board;
	IBOutlet UILabel *number;
	IBOutlet UISlider *slider;
	IBOutlet UIButton *pick;
	
	//Button to post on opponents wall
	IBOutlet UIButton *smackTalk;
	
	//Images to display profile pictures
	IBOutlet UIImageView *otherGuy;
	IBOutlet UIImageView *me;
		
	//Variable to control reloading of game
	BOOL loaded;
}

@property NSMutableDictionary *game;
@property NSString *opponent;

- (void)loadGame;
- (void)refresh;

@end
