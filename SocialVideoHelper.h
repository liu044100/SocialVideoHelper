//
//  SocialVideoHelper.h
//
//  Created by ryu-ushin on 6/5/15.
//  Copyright (c) 2015 ryu-ushin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

typedef void(^VideoUploadCompletion)(BOOL success, NSString *errorMessage);

@interface SocialVideoHelper : NSObject

+(void)uploadTwitterVideo:(NSData*)videoData comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion;
+(void)uploadFacebookVideo:(NSData*)videoData comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion;
+(BOOL)userHasAccessToFacebook;
+(BOOL)userHasAccessToTwitter;

@end
