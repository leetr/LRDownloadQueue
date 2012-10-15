//
//  LRDownloadQueue.m
//
//  Created by Denis Smirnov on 12-06-09.
//  Copyright (c) 2012 Leetr Inc. All rights reserved.
//

#import "LRDownloadQueue.h"

@interface LRDownloadQueue () {
    NSMutableArray *_queue;
    NSLock *_queueLock;
}

- (void)initializeQueue;
- (void)bump;
- (NSBlockOperation *)operationWithUrl:(NSURL *)url 
                          successBlock:(void(^)(NSData *))success 
                          failureBlock:(void(^)(NSError *error))failure;

@end


@implementation LRDownloadQueue

//
+ (LRDownloadQueue *)sharedQueue
{
    static LRDownloadQueue *_sharedQueue = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedQueue = [[self alloc] init];
        [_sharedQueue setMaxConcurrentOperationCount:5];
    });
    
    return _sharedQueue;
}

//
+ (void)download:(NSString *)uri 
         success:(void(^)(NSData *data))success
         failure:(void(^)(NSError *error))failure
{
    NSURL *url = [NSURL URLWithString:uri];
    
    [[self sharedQueue] add:url success:success failure:failure];
}

//
- (void)dealloc
{
    [_queue release];
    [_queueLock release];
    
    [super dealloc];
}

//
- (id)init
{
    self = [super init];
    
    if (self) {
        [self initializeQueue];
    }
    
    return self;
}

//
- (void)initializeQueue
{
    _queue = [[NSMutableArray alloc] init];
    _queueLock = [[NSLock alloc] init];
}

//
- (void)addFirst:(NSURL *)url 
    success:(void(^)(NSData *))success
    failure:(void(^)(NSError *error))failure
{   
    [_queueLock lock];
    [_queue insertObject:[self operationWithUrl:url successBlock:success failureBlock:failure] atIndex:0];
    [_queueLock unlock];
    
    [self bump];
}

//
- (void)add:(NSURL *)url 
    success:(void(^)(NSData *data))success
    failure:(void(^)(NSError *error))failure
{   
    [_queueLock lock];
    [_queue addObject:[self operationWithUrl:url successBlock:success failureBlock:failure]];
    [_queueLock unlock];
    
    [self bump];
}

- (void)addURL:(NSURL *)url
       success:(void(^)(NSData *data, NSURL *url))success
       failure:(void(^)(NSError *error, NSURL *url))failure

{
    [_queueLock lock];
    [_queue addObject:[self operationWithUrl:url success:success failure:failure]];
    [_queueLock unlock];
    
    [self bump];
}

- (void)addURLFirst:(NSURL *)url
            success:(void(^)(NSData *data, NSURL *url))success
            failure:(void(^)(NSError *error, NSURL *url))failure
{
    [_queueLock lock];
    [_queue insertObject:[self operationWithUrl:url success:success failure:failure] atIndex:0];
    [_queueLock unlock];
    
    [self bump];
}


//
- (void)bump
{
    if (self.operationCount < self.maxConcurrentOperationCount) {
        [_queueLock lock];
        if (_queue.count > 0) {
            
            NSOperation *op = [_queue objectAtIndex:0];
            [[op retain] autorelease];
            [_queue removeObjectAtIndex:0];
            
            [self addOperation:op];
        }
        [_queueLock unlock];
    }
}

//
- (NSBlockOperation *)operationWithUrl:(NSURL *)url 
                          successBlock:(void(^)(NSData *))success 
                          failureBlock:(void(^)(NSError *error))failure
{
    return [NSBlockOperation blockOperationWithBlock:^{
        NSURLRequest *request = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                             timeoutInterval:20.0];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (error) {
            
            if (failure != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
        } else {
            
            if (success != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(data);
                });
            }
        }
        
        [self bump];
    }];
}

//
- (NSBlockOperation *)operationWithUrl:(NSURL *)url
                          success:(void(^)(NSData *data, NSURL *url))success
                          failure:(void(^)(NSError *error, NSURL *url))failure
{
    return [NSBlockOperation blockOperationWithBlock:^{
        NSURLRequest *request = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                             timeoutInterval:20.0];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (error) {
            
            if (failure != nil) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error, url);
                });
            }
        }
        else {
            
            if (success != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(data, url);
                });
            }
        }
        
        [self bump];
    }];
}


@end