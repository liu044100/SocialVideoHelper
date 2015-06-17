# SocialVideoHelper
A Class help to share video to Facebook &amp; Twitter easily.

## Share Video to Twitter

##### Share Video to Twitter is relatively easy than to facebook. Thanks to the uploading media [new API](https://dev.twitter.com/rest/reference/post/media/upload-chunked).

Just use this class method, and pass your videoData `NSData`, and Twitter account `ACAccount`, and completion block for handling the upload complete.

```
+(void)uploadTwitterVideo:(NSData*)videoData account:(ACAccount*)account withCompletion:(dispatch_block_t)completion;

```
If you are not familiar with how to use or get `ACAccount`,  you can refer to this [tutorial about the Social Framework](http://code.tutsplus.com/tutorials/ios-6-and-the-social-framework-twitter-requests--mobile-14840).

You can use this class method to detect whether the use has logged in Twitter account in iOS Settings.

```
+(BOOL)userHasAccessToTwitter;
```

## Share Video to Facebook

Share Video to Facebook is a little bit complicated, because you have to get `publish_actions` permission first, and have to submit your app to Facebook for [Login Review](https://developers.facebook.com/docs/facebook-login/review).

`SocialVideoHelper` class did not contain anything about how to get permission. You have to do it by yourself. You can see the detail about how to get permission in [Facebook Docs](https://developers.facebook.com/docs/facebook-login/ios/permissions).

Similar to sharing video to Twitter, use this class method.

```
+(void)uploadFacebookVideo:(NSData*)videoData account:(ACAccount*)account withCompletion:(dispatch_block_t)completion;
```

You can use this class method to detect whether the use has logged in Facebook account in iOS Settings.

```
+(BOOL)userHasAccessToFacebook;
```
