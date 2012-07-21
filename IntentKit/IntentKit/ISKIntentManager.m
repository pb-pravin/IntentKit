//
//  ISKIntentManager.m
//  IntentKit
//
//  Created by Zac Bowling on 7/21/12.
//  Copyright (c) 2012 IntentKit. All rights reserved.
//

#import "ISKIntentManager.h"
#import "IntentKit.h"

@interface ISKIntentManager () {
	NSString *_cachePath;
}

@end

@implementation ISKIntentManager 

+(ISKIntentManager *)sharedIntentManager {
	static ISKIntentManager *sharedInstanceManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstanceManager = [[self alloc] init];
	});
	return sharedInstanceManager;
}

-(id) init {
	self = [super init];
	if(self) {
		_cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
		
		
	}
	return self;
}

-(void)startIntentManager {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		NSDictionary *infoDict= [[NSBundle mainBundle] infoDictionary];
		NSArray *calledIntentTypes = [infoDict objectForKey:@"ISKCalledIntentTypes"];
		for (NSString *intentType in calledIntentTypes) {
			[self fetchAppDataForIntentType:intentType];
		}
	});

}

-(void)stopIntentManager {
	
}

-(NSURL *)defaultURLForIntent:(ISKIntent *)intent {
	//checks preferences to see if the intent type has a registered default handler for an app 
	//and if it's still installed. 
	
	return nil;
}

- (NSArray *)installedAppsForIntent:(ISKIntent *)intent {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *cacheFileName = [_cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.handlers",intent.type]];
	if ([manager fileExistsAtPath:cacheFileName]){
		return [NSArray arrayWithContentsOfFile:cacheFileName];
	}
	return [NSArray array];
}

- (void)setPerferredApp:(NSDictionary *)dictionary forType:(NSString *)type {
	//
}

- (NSDictionary *)preferredAppForType:(NSString *)type {
	return nil;
}

- (NSArray *)URLPrefixesForIntentType:(NSString *)type {
	
	//TODO check age of cache file. do async.
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *cacheFileName = [_cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.handlers",type]];
	
	if ([manager fileExistsAtPath:cacheFileName]){
		return [NSArray arrayWithContentsOfFile:cacheFileName];
	}
	
	NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http:///"]];

	NSURLResponse *response;
	NSError *error;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	
	NSArray *prefixes = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
	
	[prefixes writeToFile:cacheFileName atomically:YES];
	
	return prefixes;
}

- (void)fetchAppDataForIntentType:(NSString *)type {
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *cacheFileName = [_cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.appdatas",type]];

	NSArray *prefixes = [self URLPrefixesForIntentType:type];
	
	NSMutableArray *appDatas = nil;
	
	if ([manager fileExistsAtPath:cacheFileName]) {
		appDatas = [NSMutableArray arrayWithContentsOfFile:cacheFileName];
	}
	else {
		appDatas = [NSMutableArray arrayWithCapacity:3];
	}
	
	for (NSString *prefix in prefixes) {
		if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:prefix]]) {
			NSString *requestString = [NSString stringWithFormat:@"http://<domain>/appdata/?type=%@&prefix=%@",
									   [type stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
									   [prefix stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			NSURLRequest *appDataRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
			NSURLResponse *response = nil;
			NSError *error = nil;
			NSData *responeData = [NSURLConnection sendSynchronousRequest:appDataRequest returningResponse:&response error:&error];
			
			if (responeData) {
				NSDictionary *appData = [NSJSONSerialization JSONObjectWithData:responeData options:0 error:&error];
				[appDatas addObject:appData];
			}
		}
		
	}
	
	[appDatas writeToFile:cacheFileName atomically:YES];
	
}


@end
