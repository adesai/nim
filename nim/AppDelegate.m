//
//  AppDelegate.m
//  nim
//
//  Created by Ashutosh Desai on 7/11/12.
//  Copyright (c) 2012 makegameswithus inc. All rights reserved.
//

#import "AppDelegate.h"
#import "TabBarController.h"
#import "GameViewController.h"
#import "ChatViewController.h"

@implementation AppDelegate

NSMutableDictionary* user;

BOOL noPush;

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	//Setup MGWU SDK
	[MGWU loadMGWU:@"nimble"];
	
	[MGWU forceFacebook];
	
	[MGWU setReminderMessage:@"wohoo"];
	
	[MGWU useIAPs];
		
	[MGWU setHipmobAppId:@"846a64af2db5489c9bbfa2e340a10fe4" andAwayMessage:@"Sorry, Kilahu is out for a swim. If you leave a message along with your email address he will get back to you as soon as possible!"];
	
	[MGWU setAppiraterAppId:@"532042459" andAppName:@"Nim"];
		
	//To flag whether push notifications are disabled
	noPush = FALSE;
	
    // Override point for customization after application launch.
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)tokenId {
	[MGWU registerForPush:tokenId];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [MGWU gotPush:userInfo];
	
	//Auto refresh views when a message or move has been received
	//If move has been received
	if ([[userInfo allKeys] containsObject:@"gameid"])
	{
		UINavigationController *nc = (UINavigationController*) self.window.rootViewController;
		UIViewController *vc = nc.topViewController;
		
		//If the current view displayed is the tab bar controller, refresh list of games
		if ([vc isMemberOfClass:[TabBarController class]])
			[(TabBarController*)vc refresh];
		//Else if current view is in game, refresh the game
		else if ([vc isMemberOfClass:[GameViewController class]])
		{
			GameViewController *gvc = (GameViewController*)vc;
			if ([[gvc.game objectForKey:@"gameid"] isEqualToNumber:[userInfo objectForKey:@"gameid"]])
				[gvc refresh];
		}
	}
	//If message has been received
	else if ([[userInfo allKeys] containsObject:@"from"])
	{
		UINavigationController *nc = (UINavigationController*) self.window.rootViewController;
		UIViewController *vc = nc.topViewController;
		
		//If the current view is in the chat, refresh the chat
		if ([vc isMemberOfClass:[ChatViewController class]])
		{
			ChatViewController *cvc = (ChatViewController*)vc;
			if ([cvc.friendId isEqualToString:[userInfo objectForKey:@"from"]])
				[cvc refresh];
		}
	}
}


- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error{
    [MGWU failedPush:error];
	
	//Flag that push notifications were turned off
	noPush = TRUE;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	[MGWU gotLocalPush:notification];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	
	//When the app is launched from the background, refresh the current view
	UINavigationController *nc = (UINavigationController*) self.window.rootViewController;
	UIViewController *vc = nc.topViewController;
	
	if ([vc isMemberOfClass:[TabBarController class]])
		[(TabBarController*)vc refresh];
	else if ([vc isMemberOfClass:[GameViewController class]])
		[(GameViewController*)vc refresh];
	else if ([vc isMemberOfClass:[ChatViewController class]])
		[(ChatViewController*)vc refresh];

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

//- (void)applicationWillTerminate:(UIApplication *)application
//{
//	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    return [MGWU handleURL:url];
}
//
//- (void)applicationWillTerminate:(UIApplication *)application {
//    // FBSample logic
//    // if the app is going away, we close the session object
//	[MGWU closefb];
//}

@end
