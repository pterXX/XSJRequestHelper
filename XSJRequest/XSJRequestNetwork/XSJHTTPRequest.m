//
//  XSJHTTPRequest.m
//  HuiBao
//
//  Created by 玛丽 on 2017/11/22.
//  Copyright © 2017年 玛丽. All rights reserved.
//

#import "XSJHTTPRequest.h"
#import "OpenUDID.h"

@implementation XSJHTTPRequestResult

- (id)initWithJSON:(id)json{
    self = [super init];
    if (self) {
        NSDictionary *dicJson = [json isKindOfClass:[NSDictionary class]]?json:[self returnDictionaryWithData:json];
        self.msg     = [dicJson objectForKey:@"msg"];
        self.status  = [[dicJson objectForKey:@"status"] integerValue];
        self.data    = [dicJson objectForKey:@"data"];
        self.json    = dicJson;
    }
    return self;
}

- (id)objectForKey:(NSString *)key{
    return [self.json objectForKey:key];
}


// NSData转dictonary
-(NSDictionary*)returnDictionaryWithData:(NSData*)data{
    if (data == nil) {
        return @{};
    }
    NSDictionary* myDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    return myDictionary;
}

@end

@implementation XSJHTTPRequest
+ (void)initialize{
#if DEBUG
    //  只有在DEBUG下才会访问内网服务器
   
#endif
}

+ (id)cacheWithURL:(NSString *)URL parameters:(NSDictionary *)parameter{
    [self setRequestHeader:parameter];
    return  [XSJNetworkCache httpCacheForURL:URL parameters:parameter];
}
//  屏幕宽度
+ (NSString *)width{
    static NSString *width = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        width = [NSString stringWithFormat:@"%@",@([UIScreen mainScreen].bounds.size.width)];
    });
    return width;
}

///  屏幕高度
+ (NSString *)height{
    static NSString *height = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        height = [NSString stringWithFormat:@"%@",@([UIScreen mainScreen].bounds.size.height)];
    });
    return height;
}

#pragma mark - 请求的公共方法
+ (void)setRequestHeader:(NSDictionary *)param {
    [XSJNetWorkHelper setValue:[UIDevice appCurVersion] forHTTPHeaderField:@"versionname"];
    [XSJNetWorkHelper setValue:[NSString stringWithFormat:@"%@",[[self class] width]] forHTTPHeaderField:@"screen_w"];
    [XSJNetWorkHelper setValue:[NSString stringWithFormat:@"%@",[[self class] height]] forHTTPHeaderField:@"screen_h"];
    [XSJNetWorkHelper setValue:@"1" forHTTPHeaderField:@"agent"];
    [XSJNetWorkHelper setValue:[UIDevice phoneVersion] forHTTPHeaderField:@"sys_ver"];
    [XSJNetWorkHelper setValue:[OpenUDID value] forHTTPHeaderField:@"imei"];
}



+ (NSURLSessionTask *)POSTWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(XSJRequestSuccessAndCache)success failure:(XSJRequestFailure)failure isResponseCache:(BOOL)isResponseCache {
    // 发起请求
    return [self POSTWithURL:URL  parameters:parameter responseCache:^(XSJHTTPRequestResult *result) {
        isResponseCache?success(result,YES):nil;
    } success:^(XSJHTTPRequestResult *result) {
        success?success(result,NO):nil;
    } failure:^(NSError *error) {
        failure?failure(error):nil;
    }];
}

+ (NSURLSessionTask *)POSTWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(XSJRequestSuccess)success failure:(XSJRequestFailure)failure {
    // 发起请求
    return [self POSTWithURL:URL parameters:parameter responseCache:nil success:success failure:^(NSError *error) {
        failure?failure(error):nil;
    }];
}


+ (NSURLSessionTask *)POSTWithURL:(NSString *)URL parameters:(NSDictionary *)parameter responseCache:(XSJRequestSuccess)responseCache success:(XSJRequestSuccess)success failure:(XSJRequestFailure)failure {
    // 在请求之前你可以统一配置你请求的相关参数 ,设置请求头, 请求参数的格式, 返回数据的格式....这样你就不需要每次请求都要设置一遍相关参数
    [XSJNetWorkHelper setRequestTimeoutInterval:8.0];
    [XSJNetWorkHelper openNetworkActivityIndicator:YES];
    [XSJNetWorkHelper setRequestSerializer:XSJRequestSerializerHTTP];
    [XSJNetWorkHelper setResponseSerializer:XSJResponseSerializerHTTP];
    [self setRequestHeader:parameter];
    // 发起请求
    return [XSJNetWorkHelper POST:URL parameters:parameter responseCache:^(id responseObject) {
        [XSJNetWorkHelper openNetworkActivityIndicator:NO];
        if ([[parameter allKeys] containsObject:@"page"]) {
            NSInteger page = [parameter[@"page"] integerValue];
            if (page <= 1) {
                responseCache ? responseCache([[XSJHTTPRequestResult alloc] initWithJSON:responseObject]):nil;
            }
        }else{
            responseCache ? responseCache([[XSJHTTPRequestResult alloc] initWithJSON:responseObject]):nil;
        }
    } success:^(id responseObject) {
        // 在这里你可以根据项目自定义其他一些重复操作,比如加载页面时候的等待效果, 提醒弹窗....
        [XSJNetWorkHelper openNetworkActivityIndicator:NO];
        XSJHTTPRequestResult *result = [[XSJHTTPRequestResult alloc] initWithJSON:responseObject];
        success? success(result):nil;
    } failure:^(NSError *error) {
        [self parseError:error];
        // 同上
        [XSJNetWorkHelper openNetworkActivityIndicator:NO];
        failure?failure(error):nil;
    }];
}

+ (NSURLSessionTask *)GETWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(XSJRequestSuccessAndCache)success failure:(XSJRequestFailure)failure isResponseCache:(BOOL)isResponseCache {

    // 发起请求
    return [self GETWithURL:URL parameters:parameter responseCache:^(XSJHTTPRequestResult *result) {
        isResponseCache?success(result,YES):nil;
    } success:^(XSJHTTPRequestResult *result) {
        success?success(result,NO):nil;
    } failure:failure];
}

+ (NSURLSessionTask *)GETWithURL:(NSString *)URL parameters:(NSDictionary *)parameter success:(XSJRequestSuccess)success failure:(XSJRequestFailure)failure {

    // 发起请求
    return [self GETWithURL:URL parameters:parameter responseCache:nil success:success failure:failure];
}


+ (NSURLSessionTask *)GETWithURL:(NSString *)URL parameters:(NSDictionary *)parameter responseCache:(XSJRequestSuccess)responseCache success:(XSJRequestSuccess)success failure:(XSJRequestFailure)failure {
    
    // 在请求之前你可以统一配置你请求的相关参数 ,设置请求头, 请求参数的格式, 返回数据的格式....这样你就不需要每次请求都要设置一遍相关参数
    [XSJNetWorkHelper setRequestTimeoutInterval:8.0];
    [XSJNetWorkHelper openNetworkActivityIndicator:YES];
    [XSJNetWorkHelper setRequestSerializer:XSJRequestSerializerHTTP];
    [XSJNetWorkHelper setResponseSerializer:XSJResponseSerializerHTTP];
    [XSJNetWorkHelper openLog];
    [self setRequestHeader:parameter];

    // 发起请求
    return [XSJNetWorkHelper GET:URL parameters:parameter responseCache:^(id responseObject) {
        [XSJNetWorkHelper openNetworkActivityIndicator:NO];
        if ([[parameter allKeys] containsObject:@"page"]) {
            NSInteger page = [parameter[@"page"] integerValue];
            if (page <= 1) {
                responseCache ? responseCache([[XSJHTTPRequestResult alloc] initWithJSON:responseObject]):nil;
            }
        }else{
            responseCache ? responseCache([[XSJHTTPRequestResult alloc] initWithJSON:responseObject]):nil;
        }
        
    } success:^(id responseObject) {
        //请求的头部信息；（我们执行网络请求的时候给服务器发送的包头信息）
        // 在这里你可以根据项目自定义其他一些重复操作,比如加载页面时候的等待效果, 提醒弹窗....
        [XSJNetWorkHelper openNetworkActivityIndicator:NO];
        XSJHTTPRequestResult *result = [[XSJHTTPRequestResult alloc] initWithJSON:responseObject];
       
            success? success(result):nil;
    } failure:^(NSError *error) {
        // 同上
        [XSJNetWorkHelper openNetworkActivityIndicator:NO];
        [self parseError:error];
         failure?failure(error):nil;
    }];
}

/**
 上传图片
 
 @param module 模块儿（装修圈：forum，效果图：effect ，头像：avatar， 活动：user_active）
 @param imageArray 图片数组
 @param progressBlock 加载进度的回调
 @param success 成功的回调
 @param failure 失败的回调
 */
+ (void )uploadWithModule:(NSString *)module
                            imageArray:(NSArray<UIImage *> *)imageArray
                              progress:(void (^)(NSProgress *progress,UIImage *image))progressBlock
                               success:(void (^)(NSArray *urls,NSArray *imgs))success
                               failure:(XSJRequestFailure)failure{
    [XSJNetWorkHelper openNetworkActivityIndicator:YES];
    [self setRequestHeader:nil];
    NSMutableDictionary *dict = @{@"module":module?:@"forum",@"maxSize":@(10485760)}.mutableCopy;

    NSMutableArray *temArray = [NSMutableArray array];
    NSMutableArray *temImgArray = [NSMutableArray array];
     for (NSInteger i = 0; i < imageArray.count; i ++) {
        [XSJNetWorkHelper uploadImagesWithURL:module
                                  parameters:dict name:module
                                      images:@[imageArray[i]]
                                   fileNames:nil
                                  imageScale:0.5
                                   imageType:@"png"
                                    progress:^(NSProgress *progress) {
                                       
                                    } success:^(id responseObject) {
                                        XSJHTTPRequestResult *result = [[XSJHTTPRequestResult alloc] initWithJSON:responseObject];
                                        if (result.status == 200) {
                                            NSArray *url = result.data[@"url"];
                                            if (url) {
                                                [temArray addObject:url.firstObject];
                                                [temImgArray addObject:imageArray[i]];
                                                //当所有图片上传成功后再将结果进行回调
                                                if (temArray.count == imageArray.count) {
                                                    success(temArray,temImgArray);
                                                    [XSJNetWorkHelper openNetworkActivityIndicator:NO];
                                                }
                                            }else{
                                                success(temArray,temImgArray);
                                                [XSJNetWorkHelper openNetworkActivityIndicator:NO];
                                            }
                                        }
                                    } failure:^(NSError *error) {
                                        // 同上
                                        [XSJNetWorkHelper openNetworkActivityIndicator:NO];
//                                        [self parseError:error];
                                        failure(error);
                                    }];
    }
}



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
                failure:(XSJRequestFailure)failure{
    [XSJNetWorkHelper downloadWithURL:url fileDir:fileDir progress:progressBlock success:success failure:failure];
}

+ (void)parseError:(NSError *)error{
#ifdef DEBUG
    /*
    NSData * data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
    if (data)
    {
        NSString * str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        TGWebViewController *web = [[TGWebViewController alloc] init];
        web.attributeStr = str;
        web.webTitle = XSJLocalizedString(@"服务器的错误原因");
        web.progressColor = COLOR_MAIN;
        [([UIApplication sharedApplication].keyWindow.rootViewController) showViewController:web sender:nil];
    }
     */
#else
#endif
}



@end
