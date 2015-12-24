//
//  SocialVideoHelper.m
//
//  Created by ryu-ushin on 6/5/15.
//  Copyright (c) 2015 ryu-ushin. All rights reserved.
//

#import "SocialVideoHelper.h"


@implementation SocialVideoHelper

#define DispatchMainThread(block, ...) if(block) dispatch_async(dispatch_get_main_queue(), ^{ block(__VA_ARGS__); })

#define Video_Chunk_Max_size 1000 * 1000 * 5

+(void)uploadError:(NSError*)error withCompletion:(VideoUploadCompletion)completion{
    NSString *errorDes = [error localizedDescription];
    NSLog(@"There was an error:%@", errorDes);
    DispatchMainThread(^(){completion(NO, errorDes);});
}

+(void)uploadSuccessWithCompletion:(VideoUploadCompletion)completion{
    DispatchMainThread(^(){completion(YES, nil);});
}

#pragma mark - For Facebook

+(BOOL)userHasAccessToFacebook
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook];
}

+(void)uploadFacebookVideo:(NSData*)videoData comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *facebookPostURL = [[NSURL alloc] initWithString:@"https://graph-video.facebook.com/v2.3/me/videos"];
    
    NSDictionary *postParams = @{
                                 @"access_token": account.credential.oauthToken,
                                 @"upload_phase" : @"start",
                                 @"file_size" : [NSNumber numberWithInteger: videoData.length].stringValue
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:facebookPostURL parameters:postParams];
    request.account = account;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Facebook Stage1 HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Facebook Error stage 1 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            NSLog(@"Facebook Stage1 dic -> %@", returnedData);
            
            NSString *upload_session_id = returnedData[@"upload_session_id"];
            [SocialVideoHelper facebookVideoStage2:videoData comment:(NSString*)comment upload_session_id:upload_session_id account:account withCompletion:completion];
        }
    }];
    
}

+(void)facebookVideoStage2:(NSData*)videoData comment:(NSString*)comment upload_session_id:(NSString *)upload_session_id account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *facebookPostURL = [[NSURL alloc] initWithString:@"https://graph-video.facebook.com/v2.3/me/videos"];
    
    NSDictionary *postParams = @{
                                 @"access_token": account.credential.oauthToken,
                                 @"upload_phase" : @"transfer",
                                 @"start_offset" : @"0",
                                 @"upload_session_id" : upload_session_id
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:facebookPostURL parameters:postParams];
    request.account = account;
    
    [request addMultipartData:videoData withName:@"video_file_chunk" type:@"video/mp4" filename:@"video"];
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Facebook Stage2 HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Facebook Error stage 2 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            NSLog(@"Facebook Stage2 dic -> %@", returnedData);
            
            [SocialVideoHelper facebookVideoStage3:videoData comment:(NSString*)comment upload_session_id:upload_session_id account:account withCompletion:completion];
        }
    }];
}


+(void)facebookVideoStage3:(NSData*)videoData comment:(NSString*)comment upload_session_id:(NSString *)upload_session_id account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *facebookPostURL = [[NSURL alloc] initWithString:@"https://graph-video.facebook.com/v2.3/me/videos"];
    
    if (comment == nil) {
        comment = [NSString stringWithFormat:@"#SocialVideoHelper# https://github.com/liu044100/SocialVideoHelper"];
    }
    
    NSDictionary *postParams = @{
                                 @"access_token": account.credential.oauthToken,
                                 @"upload_phase" : @"finish",
                                 @"upload_session_id" : upload_session_id,
                                 @"description": comment
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:facebookPostURL parameters:postParams];
    request.account = account;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Facebook Stage3 HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Facebook Error stage 3 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            NSLog(@"Facebook Stage3 dic -> %@", returnedData);
            
            if ([urlResponse statusCode] == 200){
                NSLog(@"Facebook upload success !");
                [SocialVideoHelper uploadSuccessWithCompletion:completion];
            }
        }
    }];
}

#pragma mark - For Twitter

+(BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

+(void)uploadTwitterVideo:(NSData*)videoData comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    NSDictionary *postParams = @{@"command": @"INIT",
                                @"total_bytes" : [NSNumber numberWithInteger: videoData.length].stringValue,
                                @"media_type" : @"video/mp4"
                                };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    request.account = account;
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Twitter Stage1 HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Twitter Error stage 1 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            NSString *mediaID = [NSString stringWithFormat:@"%@", [returnedData valueForKey:@"media_id_string"]];
            
            [SocialVideoHelper tweetVideoStage2:videoData mediaID:mediaID comment:comment account:account withCompletion:completion];
            
            NSLog(@"stage one success, mediaID -> %@", mediaID);
        }
    }];
}

+(void)tweetVideoStage2:(NSData*)videoData mediaID:(NSString *)mediaID comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    NSArray *chunks = [SocialVideoHelper separateToMultipartData:videoData];
    NSMutableArray *requests = [NSMutableArray array];
    
    for (int i = 0; i < chunks.count; i++) {
        NSString *seg_index = [NSString stringWithFormat:@"%d",i];
        NSDictionary *postParams = @{@"command": @"APPEND",
                                     @"media_id" : mediaID,
                                     @"segment_index" : seg_index,
                                     };
        SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
        postRequest.account = account;
        [postRequest addMultipartData:chunks[i] withName:@"media" type:@"video/mp4" filename:@"video"];
        [requests addObject:postRequest];
    }

    __block NSError *theError = nil;
    dispatch_queue_t chunksRequestQueue = dispatch_queue_create("chunksRequestQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(chunksRequestQueue, ^{
        dispatch_group_t requestGroup = dispatch_group_create();
        for (int i = 0; i < (requests.count - 1); i++) {
            dispatch_group_enter(requestGroup);
            SLRequest *postRequest = requests[i];
            [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSLog(@"Twitter Stage2 - %d HTTP Response: %li, %@", (i+1),(long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                if (error) {
                    NSLog(@"Twitter Error stage 2 - %d, error - %@", (i+1), error);
                    theError = error;
                } else {
                    if (i == requests.count - 1) {
                         [SocialVideoHelper tweetVideoStage3:videoData mediaID:mediaID comment:comment account:account withCompletion:completion];
                    }
                }
                dispatch_group_leave(requestGroup);
            }];
            dispatch_group_wait(requestGroup, DISPATCH_TIME_FOREVER);
        }
        
        if (theError) {
            [SocialVideoHelper uploadError:theError withCompletion:completion];
        } else {
            SLRequest *postRequest = requests.lastObject;
            [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSLog(@"Twitter Stage2 - final, HTTP Response: %li, %@",(long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                if (error) {
                    NSLog(@"Twitter Error stage 2 - final, error - %@", error);
                } else {
                    [SocialVideoHelper tweetVideoStage3:videoData mediaID:mediaID comment:comment account:account withCompletion:completion];
                }
            }];
        }
    });
}

+(void)tweetVideoStage3:(NSData*)videoData mediaID:(NSString *)mediaID comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    NSDictionary *postParams = @{@"command": @"FINALIZE",
                               @"media_id" : mediaID };
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    
    // Set the account and begin the request.
    postRequest.account = account;
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Twitter Stage3 HTTP Response: %li, %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Twitter Error stage 3 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            [SocialVideoHelper tweetVideoStage4:videoData mediaID:mediaID comment:comment account:account withCompletion:completion];
        }
    }];
}

+(void)tweetVideoStage4:(NSData*)videoData mediaID:(NSString *)mediaID comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    
    if (comment == nil) {
        comment = [NSString stringWithFormat:@"#SocialVideoHelper# https://github.com/liu044100/SocialVideoHelper"];
    }
    
    // Set the parameters for the third twitter video request.
    NSDictionary *postParams = @{@"status": comment,
                               @"media_ids" : @[mediaID]};
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    postRequest.account = account;
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Twitter Stage4 HTTP Response: %li", (long)[urlResponse statusCode]);
        if (error) {
            NSLog(@"Twitter Error stage 4 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            if ([urlResponse statusCode] == 200){
                NSLog(@"Twitter upload success !");
                [SocialVideoHelper uploadSuccessWithCompletion:completion];
            }
        }
    }];
}

+(NSArray*)separateToMultipartData:(NSData*)videoData{
    NSMutableArray *multipartData = [NSMutableArray new];
    CGFloat length = videoData.length;
    CGFloat standard_length = Video_Chunk_Max_size;
    if (length <= standard_length) {
        [multipartData addObject:videoData];
        NSLog(@"need not separate as chunk, data size -> %ld bytes", (long)videoData.length);
    } else {
        NSUInteger count = ceil(length/standard_length);
        for (int i = 0; i < count; i++) {
            NSRange range;
            if (i == count - 1) {
                range = NSMakeRange(i * standard_length, length - i * standard_length);
            } else {
                range = NSMakeRange(i * standard_length, standard_length);
            }
            NSData *part_data = [videoData subdataWithRange:range];
            [multipartData addObject:part_data];
            NSLog(@"chunk index -> %d, data size -> %ld bytes", (i+1), (long)part_data.length);
        }
    }
    return multipartData.copy;
}

@end
