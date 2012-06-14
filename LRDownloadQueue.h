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
         failure:(void(^)(NSError *error))failure;

- (void)addFirst:(NSURL *)url 
         success:(void(^)(NSData *))success
         failure:(void(^)(NSError *error))failure;

- (void)add:(NSURL *)url 
    success:(void(^)(NSData *))success
    failure:(void(^)(NSError *error))failure;


@end