//
//  PictureCache.h
//  nim
//
//  Created by Ashutosh Desai on 11/9/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//
//  Class to asynchronously load Facebook Profile Pictures

#import <Foundation/Foundation.h>

@interface ProfilePictureCache : NSObject
{
	//Username of profile picture to pull
	NSString *username;
	//Image view to fill with profile picture
	UIImageView *imageView;
	//If part of table view, table view of cell containing image view
	UITableView *tView;
	//If part of table view, index path of cell containing image view
	NSIndexPath *indexPath;
}

//Set profile picture to generic image view
+(void)setProfilePicture:(NSString *)u forImageView:(UIImageView *)iv;

//Set profile picture to image view residing in a table view cell (needs to be treated differently since table views reuse cells)
+(void)setProfilePicture:(NSString *)u forImageView:(UIImageView *)iv inTableView:(UITableView*)tv forIndexPath:(NSIndexPath*)ip;

-(id)initWithUsername:(NSString*)u andImageView:(UIImageView*)iv inTableView:(UITableView*)tv forIndexPath:(NSIndexPath*)ip;

@end
