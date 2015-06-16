//
//  SocialVideoHelper.m
//  picpak
//
//  Created by ryu-ushin on 6/5/15.
//  Copyright (c) 2015 NguyenTheQuan. All rights reserved.
//

#import "SocialVideoHelper.h"


@implementation SocialVideoHelper

+(BOOL)userHasAccessToFacebook
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook];
}

+(BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

+(void)uploadFacebookVideo:(Video*)video account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    
    NSLog(@"account des -> %@, account token -> %@", account.description,account.credential.oauthToken);
    
    NSURL *videoURL = [NSURL fileURLWithPath:video.videoPath];
    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    
    NSLog(@"video url -> %@, video size -> %@", videoURL, [NSNumber numberWithInteger: videoData.length].stringValue);
    
    NSURL *facebookPostURL = [[NSURL alloc] initWithString:@"https://graph-video.facebook.com/v2.3/me/videos"];
    
    NSDictionary *postParams = @{
                                 @"access_token": account.credential.oauthToken,
                                 @"upload_phase" : @"start",
                                 @"file_size" : [NSNumber numberWithInteger: videoData.length].stringValue
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:facebookPostURL parameters:postParams];
    request.account = account;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"There was an error:%@", [error localizedDescription]);
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            NSLog(@"stage1 dic -> %@", returnedData);
            
            NSString *upload_session_id = returnedData[@"upload_session_id"];
            [SocialVideoHelper facebookVideoStage2:video upload_session_id:upload_session_id account:account withCompletion:completion];
        }
    }];
    
}

+(void)facebookVideoStage2:(Video*)video upload_session_id:(NSString *)upload_session_id account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    NSURL *videoURL = [NSURL fileURLWithPath:video.videoPath];
    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    
    NSURL *facebookPostURL = [[NSURL alloc] initWithString:@"https://graph-video.facebook.com/v2.3/me/videos"];
    
    NSDictionary *postParams = @{
                                 @"access_token": account.credential.oauthToken,
                                 @"upload_phase" : @"transfer",
                                 @"start_offset" : @"0",
                                 @"upload_session_id" : upload_session_id
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:facebookPostURL parameters:postParams];
    request.account = account;
    
    [request addMultipartData:videoData withName:@"video_file_chunk" type:@"video/mp4" filename:videoURL.absoluteString];
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"There was an error:%@", [error localizedDescription]);
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            NSLog(@"stage2 dic -> %@", returnedData);
            
            [SocialVideoHelper facebookVideoStage3:video upload_session_id:upload_session_id account:account withCompletion:completion];
        }
    }];
}


+(void)facebookVideoStage3:(Video*)video upload_session_id:(NSString *)upload_session_id account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    
    NSURL *facebookPostURL = [[NSURL alloc] initWithString:@"https://graph-video.facebook.com/v2.3/me/videos"];
    
    NSDictionary *postParams = @{
                                 @"access_token": account.credential.oauthToken,
                                 @"upload_phase" : @"finish",
                                 @"upload_session_id" : upload_session_id
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:facebookPostURL parameters:postParams];
    request.account = account;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"There was an error:%@", [error localizedDescription]);
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            NSLog(@"dic -> %@", returnedData);
            
            if ([urlResponse statusCode] == 200){
                NSLog(@"upload success !");
                DispatchMainThread(^(){completion();});
            }
        }
    }];
}



+(void)uploadTwitterVideo:(Video*)video account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    
    NSURL *videoURL = [NSURL fileURLWithPath:video.videoPath];
    
    NSLog(@"video url -> %@", videoURL);
    
    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    NSDictionary *postParams = @{@"command": @"INIT",
                                @"total_bytes" : [NSNumber numberWithInteger: videoData.length].stringValue,
                                @"media_type" : @"video/mp4"
                                };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    request.account = account;
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"There was an error:%@", [error localizedDescription]);
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            NSString *mediaID = [NSString stringWithFormat:@"%@", [returnedData valueForKey:@"media_id_string"]];
            
            [SocialVideoHelper tweetVideoStage2:video mediaID:mediaID account:account withCompletion:completion];
            
            NSLog(@"stage one success, mediaID -> %@", mediaID);
        }
    }];
}

+(void)tweetVideoStage2:(Video*)video mediaID:(NSString *)mediaID account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    
    NSURL *videoURL = [NSURL fileURLWithPath:video.videoPath];
    
    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    NSDictionary *postParams = @{@"command": @"APPEND",
                                 @"media_id" : mediaID,
                                 @"segment_index" : @"0",
                                 };
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    postRequest.account = account;
    
    [postRequest addMultipartData:videoData withName:@"media" type:@"video/mp4" filename:videoURL.absoluteString];
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Stage2 HTTP Response: %li, %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (!error) {
            [SocialVideoHelper tweetVideoStage3:video mediaID:mediaID account:account withCompletion:completion];
        }
        else {
            NSLog(@"Error stage 2 - %@", error);
        }
    }];
}

+(void)tweetVideoStage3:(Video*)video mediaID:(NSString *)mediaID account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    NSDictionary *postParams = @{@"command": @"FINALIZE",
                               @"media_id" : mediaID };
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    
    // Set the account and begin the request.
    postRequest.account = account;
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Stage3 HTTP Response: %li, %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Error stage 3 - %@", error);
        } else {
            [SocialVideoHelper tweetVideoStage4:video mediaID:mediaID account:account withCompletion:completion];
        }
    }];
}

+(void)tweetVideoStage4:(Video*)video mediaID:(NSString *)mediaID account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
     NSString *statusContent = [NSString stringWithFormat:@"%@ #hichee %@", video.title, SHARE_URL];

    // Set the parameters for the third twitter video request.
    NSDictionary *postParams = @{@"status": statusContent,
                               @"media_ids" : @[mediaID]};
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    postRequest.account = account;
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Stage4 HTTP Response: %li, %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Error stage 4 - %@", error);
        } else {
            if ([urlResponse statusCode] == 200){
                NSLog(@"upload success !");
                DispatchMainThread(^(){completion();});
            }
        }
    }];
    
}

@end
