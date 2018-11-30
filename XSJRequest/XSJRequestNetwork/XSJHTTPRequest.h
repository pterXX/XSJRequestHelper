//
//  XSJHTTPRequest.h
//  HuiBao
//
//  Created by 玛丽 on 2017/11/22.
//  Copyright © 2017年 玛丽. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XSJNetWorkHelper.h"
#import "UIDevice+XSJRequest.h"
@class XSJHTTPRequestResult;
/**
 请求成功的block
 */
typedef void(^XSJRequestSuccess)(XSJHTTPRequestResult *result);
typedef void(^XSJRequestSuccessAndCache)(XSJHTTPRequestResult *result,BOOL isCache);
/**
 请求失败的block
 */
typedef void(^XSJRequestFailure)(NSError *error);


@interface XSJHTTPRequestResult : NSObject

@property (strong, nonatomic) NSString  *msg;
@property (assign, nonatomic) NSInteger     status;
@property (strong, nonatomic) id       data;
@property (strong, nonatomic) id       json;
- (id)objectForKey:(NSString *)key;
- (id)initWithJSON:(id)json;
@end


@interface XSJHTTPRequest : NSObject
/**
 获取缓存
 */
+ (id)cacheWithURL:(NSString *)URL parameters:(NSDictionary *)parameter;

/*
 配置好XSJNetworkHelper各项请求参数,封装成一个公共方法,给以上方法调用,
 相比在项目中单个分散的使用XSJNetworkHelper/其他网络框架请求,可大大降低耦合度,方便维护
 在项目的后期, 你可以在公共请求方法内任意更换其他的网络请求工具,切换成本小
 以下是无缓存的公共方法,可自己再定制有缓存的
 */
+ (NSURLSessionTask *)POSTWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(XSJRequestSuccessAndCache)success failure:(XSJRequestFailure)failure isResponseCache:(BOOL)isResponseCache;
+ (NSURLSessionTask *)GETWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(XSJRequestSuccessAndCache)success failure:(XSJRequestFailure)failure isResponseCache:(BOOL)isResponseCache ;


+ (NSURLSessionTask *)POSTWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(XSJRequestSuccess)success failure:(XSJRequestFailure)failure;
+ (NSURLSessionTask *)GETWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(XSJRequestSuccess)success failure:(XSJRequestFailure)failure;

+ (NSURLSessionTask *)POSTWithURL:(NSString *)URL parameters:(NSDictionary *)parameter responseCache:(XSJRequestSuccess)responseCache success:(XSJRequestSuccess)success failure:(XSJRequestFailure)failure;
+ (NSURLSessionTask *)GETWithURL:(NSString *)URL parameters:(NSDictionary *)parameter responseCache:(XSJRequestSuccess)responseCache success:(XSJRequestSuccess)success failure:(XSJRequestFailure)failure;

/**
 下载文件
 
 @param url 下载链接
 @param fileDir 保存在缓存目录下
 @param progressBlock 下载进度
 @param success 成功后的回调
 @param failure 失败的回调
 */
+ (void)downFileWithUrl:(NSString *)url
                filrDir:(NSString *)fileDir
               progress:(void (^)(NSProgress *progress))progressBlock
                success:(void (^)(NSString *filePath))success
                failure:(XSJRequestFailure)failure;
@end
