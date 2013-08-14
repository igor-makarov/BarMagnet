//
//  AppDelegate.m
//  BarMagnet
//
//  Created by Carlo Tortorella on 4/06/13.
//  Copyright (c) 2013 Carlo Tortorella. All rights reserved.
//

#import "AppDelegate.h"
#import "PingHandler.h"
#import "FileHandler.h"
#import "ConnectionHandler.h"
#import "TorrentDelegate.h"
#import "TorrentDelegateConfig.h"
#import "TorrentJobChecker.h"

@implementation AppDelegate
	
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[TestFlight takeOff:@"1d15ef35-8692-4cc4-9d94-96f36bb449b6"];
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] becameActive];
	pingHandler = [PingHandler new];
    __block NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(updateConnectionStatus)]];
	[invocation setTarget:self];
	[invocation setSelector:@selector(updateConnectionStatus)];
	[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:[[[FileHandler sharedInstance] settingsValueForKey:@"refresh_connection_seconds"] doubleValue] invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];

	invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(updateTorrentJobs)]];
	[invocation setTarget:self];
	[invocation setSelector:@selector(updateTorrentJobs)];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:[[[FileHandler sharedInstance] settingsValueForKey:@"refresh_connection_seconds"] doubleValue] invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];
	});
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clear_field_notification" object:nil];
    [[TorrentDelegate sharedInstance] handleMagnet:[url absoluteString]];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] becameIdle];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[FileHandler sharedInstance] saveAllPlists];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] becameActive];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	[[[TorrentDelegate sharedInstance] currentlySelectedClient] willExit];
}

- (void)updateTorrentJobs
{
	[[TorrentJobChecker sharedInstance] updateTorrentClientWithJobsData];
}

- (void)updateConnectionStatus
{
	[[TorrentJobChecker sharedInstance] performSelectorInBackground:@selector(connectionCheckInvocation) withObject:nil];
	[[TorrentJobChecker sharedInstance] performSelectorInBackground:@selector(jobCheckInvocation) withObject:nil];
}
@end