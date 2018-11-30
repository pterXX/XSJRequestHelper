//
//  XSJNetWorkHelper.m
//  HuiBao
//
//  Created by 玛丽 on 2017/11/22.
//  Copyright © 2017年 玛丽. All rights reserved.
//

#import "XSJNetWorkHelper.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OpenUDID.h"
#import <YYKit.h>


#define kAcceptableContentTypes [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil]

@implementation XSJNetWorkHelper

static BOOL _isOpenLog;   // 是否已开启日志打印
static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;
static NSString *_proxyHost;  //  代理服务器的host
static NSString *_proxyHostBaseUrl; //  代理服务器的基础连接
static int _proxyPort;  //  代理服务器端口号

#pragma mark - 开始监听网络
+ (void)networkStatusWithBlock:(XSJNetworkStatus)networkStatus {
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
            networkStatus ? networkStatus(XSJNetworkStatusUnknown) : nil;
            if (_isOpenLog) NSLog(@"未知网络");
            break;
            case AFNetworkReachabilityStatusNotReachable:
            networkStatus ? networkStatus(XSJNetworkStatusNotReachable) : nil;
            if (_isOpenLog) NSLog(@"无网络");
            break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
            networkStatus ? networkStatus(XSJNetworkStatusReachableViaWWAN) : nil;
            if (_isOpenLog) NSLog(@"手机自带网络");
            break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
            networkStatus ? networkStatus(XSJNetworkStatusReachableViaWiFi) : nil;
            if (_isOpenLog) NSLog(@"WIFI");
            break;
        }
    }];
}

+ (BOOL)isNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

+ (void)openLog {
    _isOpenLog = YES;
}

+ (void)closeLog {
    _isOpenLog = NO;
}

+ (void)cancelAllRequest {
    // 锁操作
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL) { return; }
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

//  跳转到数据设置页面
+ (void)showRequestNetworkingSetting{
    NSString *name = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

    NSString *title = [NSString stringWithFormat:@"允许\"%@\"使用数据?",name];
    NSString *message =@"当前网络连接失败，请跳转到设置页面，设置当前网络环境,可能同时包含无线局域网和蜂窝移动数据。";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"不允许" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"允许" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:@"App-Prefs:root"];
        if([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{UIApplicationOpenURLOptionsSourceApplicationKey : @YES} completionHandler:^(BOOL success) {
                
            }];
        }
    }]];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - GET请求无缓存
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(id)parameters
                  success:(XSJHttpRequestSuccess)success
                  failure:(XSJHttpRequestFailed)failure {
    return [self GET:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - POST请求无缓存
+ (NSURLSessionTask *)POST:(NSString *)URL
                parameters:(id)parameters
                   success:(XSJHttpRequestSuccess)success
                   failure:(XSJHttpRequestFailed)failure {
    return [self POST:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - GET请求自动缓存
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(id)parameters
            responseCache:(XSJHttpRequestCache)responseCache
                  success:(XSJHttpRequestSuccess)success
                  failure:(XSJHttpRequestFailed)failure {
    NSMutableDictionary *param = parameters;
    //  如果参数中包含页码就不使用缓存
    if ([[param objectForKey:@"page"] integerValue] <= 1)
    {
        //读取缓存
        responseCache!=nil ? responseCache([XSJNetworkCache httpCacheForURL:URL parameters:parameters]) : nil;
    }
    NSURLSessionTask *sessionTask = [_sessionManager GET:URL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        if (_isOpenLog) {
//            NSLog(@"header = %@",task.currentRequest.allHTTPHeaderFields);
//            NSLog(@"responseObject = %@",responseObject);
        }
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        //对数据进行异步缓存
        responseCache!=nil ? [XSJNetworkCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isOpenLog) {NSLog(@"error = %@",error);}
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
    }];

    // 添加sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
    
    return sessionTask;
}

#pragma mark - POST请求自动缓存
+ (NSURLSessionTask *)POST:(NSString *)URL
                parameters:(id)parameters
             responseCache:(XSJHttpRequestCache)responseCache
                   success:(XSJHttpRequestSuccess)success
                   failure:(XSJHttpRequestFailed)failure {

    [self openLog];

    NSMutableDictionary *param = parameters;
    //  如果参数中包含页码就不使用缓存
    if ([[param objectForKey:@"page"] integerValue] <= 1)
    {
        //读取缓存
        responseCache!=nil ? responseCache([XSJNetworkCache httpCacheForURL:URL parameters:parameters]) : nil;
    }
    if (_isOpenLog) {NSLog(@"url = %@,param = %@",URL,parameters);}
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        if (_isOpenLog) {NSLog(@"responseObject = %@",responseObject);}
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        //对数据进行异步缓存
        responseCache!=nil ? [XSJNetworkCache setHttpCache:responseObject URL:URL parameters:parameters] : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) {NSLog(@"error = %@",error);}
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
        
    }];
    
    // 添加最新的sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
    return sessionTask;
}

#pragma mark - 上传文件
+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                             parameters:(id)parameters
                                   name:(NSString *)name
                               filePath:(NSString *)filePath
                               progress:(XSJHttpProgress)progress
                                success:(XSJHttpRequestSuccess)success
                                failure:(XSJHttpRequestFailed)failure {
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:name error:&error];
        (failure && error) ? failure(error) : nil;
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) {NSLog(@"responseObject = %@",responseObject);}
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) {NSLog(@"error = %@",error);}
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
    }];
    
    // 添加sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
    
    return sessionTask;
}

#pragma mark - 上传多张图片
+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                               parameters:(id)parameters
                                     name:(NSString *)name
                                   images:(NSArray<UIImage *> *)images
                                fileNames:(NSArray<NSString *> *)fileNames
                               imageScale:(CGFloat)imageScale
                                imageType:(NSString *)imageType
                                 progress:(XSJHttpProgress)progress
                                  success:(XSJHttpRequestSuccess)success
                                  failure:(XSJHttpRequestFailed)failure {
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (NSUInteger i = 0; i < images.count; i++) {
            // 图片经过等比压缩后得到的二进制文件
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            // 默认图片的文件名, 若fileNames为nil就使用
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *imageFileName =  [NSString stringWithFormat:@"%@%ld.%@",str,i,imageType?:@"jpg"];
            
            [formData appendPartWithFileData:imageData
                                        name:name
                                    fileName:fileNames ? [NSString stringWithFormat:@"%@.%@",fileNames[i],imageType?:@"jpg"] : imageFileName
                                    mimeType:[NSString stringWithFormat:@"image/%@",imageType ?: @"jpg"]];
        }


    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(uploadProgress) : nil;
        });
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) {NSLog(@"responseObject = %@",responseObject);}
        [[self allSessionTask] removeObject:task];
        success ? success(responseObject) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) {NSLog(@"error = %@",error);}
        [[self allSessionTask] removeObject:task];
        failure ? failure(error) : nil;
    }];
    
    // 添加sessionTask到数组
    sessionTask ? [[self allSessionTask] addObject:sessionTask] : nil ;
    
    return sessionTask;
}

#pragma mark - 下载文件
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(XSJHttpProgress)progress
                              success:(void(^)(NSString *))success
                              failure:(XSJHttpRequestFailed)failure {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        //下载进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            progress ? progress(downloadProgress) : nil;
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //拼接缓存目录
        NSString *downloadDir = DOWN_DEFAULT_PATH(fileDir);
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[self allSessionTask] removeObject:downloadTask];
        if(failure && error) {failure(error) ; return ;};
        success ? success(filePath.absoluteString /** NSURL->NSString*/) : nil;
        
    }];
    //开始下载
    [downloadTask resume];
    // 添加sessionTask到数组
    downloadTask ? [[self allSessionTask] addObject:downloadTask] : nil ;
    
    return downloadTask;
}

/**
 存储着所有的请求task数组
 */
+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}

#pragma mark - 初始化AFHTTPSessionManager相关属性
/**
 开始监测网络状态
 */
+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/**
 *  所有的HTTP请求共享一个AFHTTPSessionManager
 *  原理参考地址:http://www.jianshu.com/p/5969bbb4af9f
 */
+ (void)initialize {
    _sessionManager =  [self manger];
}

+ (AFHTTPSessionManager *)manger{
    AFHTTPSessionManager * m = [AFHTTPSessionManager manager];
    m.requestSerializer.timeoutInterval = 30.f;
    //传入json格式数据，不写则普通post
    m.requestSerializer = [AFHTTPRequestSerializer serializer];
    m.responseSerializer.acceptableContentTypes = kAcceptableContentTypes;
    // 打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    return m;
}

+ (AFHTTPSessionManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sessionManager =  [self manger];
    });
    return _sessionManager;
}

//  其他参数
+ (NSString *)otherParam{
//    NSString *param  = [NSString stringWithFormat:@"agent=1&screen_w=%@&screen_h=%@&versionname=%@&sys_ver=%@imei=%@",@(KWIDTH),@(KHEIGHT),[UIDevice appCurVersion],[UIDevice phoneVersion],[OpenUDID value]];
//    if ([XQLoginExample exampleIsLogined])
//    {
//        NSLog(@"userInfo %@",[XQLoginExample lastUserInfo]);
//        //  如果登录了就传登录信息
//        param = [NSString stringWithFormat:@"%@&logintoken=%@&uid=%@&gid=%@",param,[XQLoginExample login_token],[XQLoginExample uid],[XQLoginExample gid]];
//    }
//    return param;
    return @"";
}

#pragma mark - 重置AFHTTPSessionManager相关属性

+ (void)setAFHTTPSessionManagerProperty:(void (^)(AFHTTPSessionManager *))sessionManager {
    sessionManager ? sessionManager(_sessionManager) : nil;
}

+ (void)setRequestSerializer:(XSJRequestSerializer)requestSerializer {
    _sessionManager.requestSerializer = requestSerializer==XSJRequestSerializerHTTP ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
    _sessionManager.responseSerializer.acceptableContentTypes = kAcceptableContentTypes;
}

+ (void)setResponseSerializer:(XSJResponseSerializer)responseSerializer {
    _sessionManager.responseSerializer = responseSerializer==XSJResponseSerializerHTTP ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time {
    _sessionManager.requestSerializer.timeoutInterval = time;
}

+ (void)setDebugProxyHost:(NSString *)proxyHost proxyPort:(int)proxyPort baseUrl:(NSString *)baseUrl {
    _proxyHost = proxyHost;
    _proxyHostBaseUrl = baseUrl;
    _proxyPort = proxyPort;
    AFHTTPSessionManager *m = _sessionManager;
#ifdef DEBUG   //  只有在DEBUG模式下才会实现这个功能，Release 下自动访问外网服务器
    if (_proxyHost.length > 0 && _proxyHostBaseUrl.length > 0) {
        // 创建一个代理服务器，包括HTTP或HTTPS代理，当然还可以添加SOCKS,FTP,RTSP等
        NSDictionary *proxyDict = @{
                                    (NSString *)kCFNetworkProxiesHTTPEnable  : [NSNumber numberWithInt:1],
                                    (NSString *)kCFNetworkProxiesHTTPProxy: _proxyHost,
                                    (NSString *)kCFNetworkProxiesHTTPPort:[NSNumber numberWithInt: _proxyPort],
                                    };
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        configuration.connectionProxyDictionary = proxyDict;
        //创建AFHTTPSessionManager 对象
        m = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:_proxyHostBaseUrl]
                                     sessionConfiguration:(NSURLSessionConfiguration *)configuration];
    }else{
        !_proxyHost.length?:NSLog(@"代理服务器连接地址不存在");
        !_proxyHostBaseUrl.length?:NSLog(@"代理服务器连接地址不存在");
    }
#endif
    _sessionManager = m;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

+ (void)openNetworkActivityIndicator:(BOOL)open {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}

+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 如果需要验证自建证书(无效证书)，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    
    [_sessionManager setSecurityPolicy:securityPolicy];
}

@end

#pragma mark - NSDictionary,NSArray的分类
/*
ß ************************************************************************************
 *新建NSDictionary与NSArray的分类, 控制台打印json数据中的中文
 ************************************************************************************
 */

#ifdef DEBUG
@implementation NSArray (XSJ)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"(\n"];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [strM appendFormat:@"\t%@,\n", obj];
    }];
    [strM appendString:@")"];

    return strM;
}

@end

@implementation NSDictionary (XSJ)

- (NSString *)descriptionWithLocale:(id)locale {
    NSMutableString *strM = [NSMutableString stringWithString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [strM appendFormat:@"\t%@ = %@;\n", key, obj];
    }];

    [strM appendString:@"}\n"];

    return strM;
}
@end
#endif
