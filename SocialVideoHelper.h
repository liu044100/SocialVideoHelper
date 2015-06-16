//
//  SocialVideoHelper.h
//
//  Created by ryu-ushin on 6/5/15.
//  Copyright (c) 2015 ryu-ushin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

#define DispatchMainThread(block, ...) if(block) dispatch_async(dispatch_get_main_queue(), ^{ block(__VA_ARGS__); })

@interface SocialVideoHelper : NSObject

+(void)uploadTwitterVideo:(NSData*)videoData account:(ACAccount*)account withCompletion:(dispatch_block_t)completion;

+(void)uploadFacebookVideo:(NSData*)videoData account:(ACAccount*)account withCompletion:(dispatch_block_t)completion;

+(BOOL)userHasAccessToFacebook;
+(BOOL)userHasAccessToTwitter;

@end
