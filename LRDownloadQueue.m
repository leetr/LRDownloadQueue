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
    
    [[LRDownloadQueue sharedQueue] add:url success:success failure:failure];
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

//
- (void)bump
{
    if (self.operationCount < self.maxConcurrentOperationCount && _queue.count > 0) {
        [_queueLock lock];
        NSOperation *op = [_queue objectAtIndex:0];
        [[op retain] autorelease];
        [_queue removeObjectAtIndex:0];
        [_queueLock unlock];
        
        [self addOperation:op];
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
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        
        if (data == nil) {
            
            if (failure != nil) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:33 userInfo:nil];
                
                failure(error);
            }
        } else {
            
            if (success != nil) {
                success(data);
            }
        }
        
        [self bump];
    }];
}


@end