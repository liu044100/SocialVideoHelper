//
//  SocialVideoHelper.h
//  picpak
//
//  Created by ryu-ushin on 6/5/15.
//  Copyright (c) 2015 NguyenTheQuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "Video.h"

@interface SocialVideoHelper : NSObject

+(void)uploadTwitterVideo:(Video*)video account:(ACAccount*)account withCompletion:(dispatch_block_t)completion;

+(void)uploadFacebookVideo:(Video*)video account:(ACAccount*)account withCompletion:(dispatch_block_t)completion;

+(BOOL)userHasAccessToFacebook;
+(BOOL)userHasAccessToTwitter;

@end
