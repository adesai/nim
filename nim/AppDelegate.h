//
//  AppDelegate.h
//  nim
//
//  Created by Ashutosh Desai on 7/11/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

extern NSMutableDictionary* user;
extern BOOL noPush;

@property (strong, nonatomic) UIWindow *window;

@end
