//
//  LRDownloadQueue.h
//
//  Created by Denis Smirnov on 12-06-09.
//  Copyright (c) 2012 Leetr Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LRDownloadQueue : NSOperationQueue

+ (LRDownloadQueue *)sharedQueue;
+ (void)download:(NSString *)uri 
         success:(void(^)(NSData *data))success
         failure:(void(^)(NSError *error))failure __attribute__((deprecated));

- (void)addFirst:(NSURL *)url
         success:(void(^)(NSData *data))success
         failure:(void(^)(NSError *error))failure __attribute__((deprecated));

- (void)add:(NSURL *)url 
    success:(void(^)(NSData *data))success
    failure:(void(^)(NSError *error))failure __attribute__((deprecated));

- (void)addURL:(NSURL *)url
    success:(void(^)(NSData *data, NSURL *url))success
    failure:(void(^)(NSError *error, NSURL *url))failure;

- (void)addURLFirst:(NSURL *)url
       success:(void(^)(NSData *data, NSURL *url))success
       failure:(void(^)(NSError *error, NSURL *url))failure;

@end