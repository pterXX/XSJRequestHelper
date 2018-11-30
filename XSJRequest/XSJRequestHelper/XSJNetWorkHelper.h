//
//  XSJNetWorkHelper.h
//  HuiBao
//
//  Created by 玛丽 on 2017/11/22.
//  Copyright © 2017年 玛丽. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XSJNetworkCache.h"
#import "XSJHTTPRequest.h"

//  下载文件的默认地址
#define DOWN_DEFAULT_PATH(fileDir)  [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"]
@class AFHTTPSessionManager,XSJHTTPRequestResult;
typedef NS_ENUM(NSUInteger, XSJNetworkStatusType) {
    /// 未知网络
    XSJNetworkStatusUnknown,
    /// 无网络
    XSJNetworkStatusNotReachable,
    /// 手机网络
    XSJNetworkStatusReachableViaWWAN,
    /// WIFI网络
    XSJNetworkStatusReachableViaWiFi
};

typedef NS_ENUM(NSUInteger, XSJRequestSerializer) {
    /// 设置请求数据为JSON格式
    XSJRequestSerializerJSON,
    /// 设置请求数据为二进制格式
    XSJRequestSerializerHTTP,
};

typedef NS_ENUM(NSUInteger, XSJResponseSerializer) {
    /// 设置响应数据为JSON格式
    XSJResponseSerializerJSON,
    /// 设置响应数据为二进制格式
    XSJResponseSerializerHTTP,
};

/// 请求成功的Block
typedef void(^XSJHttpRequestSuccess)(id responseObject);
/// 请求失败的Block
typedef void(^XSJHttpRequestFailed)(NSError *error);
/// 缓存的Block
typedef void(^XSJHttpRequestCache)(id responseObject);
/// 上传或者下载的进度, Progress.completedUnitCount:当前大小 - Progress.totalUnitCount:总大小
typedef void (^XSJHttpProgress)(NSProgress *progress);
/// 网络状态的Block
typedef void(^XSJNetworkStatus)(XSJNetworkStatusType status);




@interface XSJNetWorkHelper : NSObject

/// 有网YES, 无网:NO
+ (BOOL)isNetwork;
/// 手机网络:YES, 反之:NO
+ (BOOL)isWWANNetwork;
/// WiFi网络:YES, 反之:NO
+ (BOOL)isWiFiNetwork;
/// 取消所有HTTP请求
+ (void)cancelAllRequest;
/// 实时获取网络状态,通过Block回调实时获取(此方法可多次调用)
+ (void)networkStatusWithBlock:(XSJNetworkStatus)networkStatus;
/// 取消指定URL的HTTP请求
+ (void)cancelRequestWithURL:(NSString *)URL;
/// 开启日志打印 (Debug级别)
+ (void)openLog;
/// 关闭日志打印,默认关闭
+ (void)closeLog;
///  跳转到数据设置页面
+ (void)showRequestNetworkingSetting;


/**
 *  GET请求,无缓存
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                           success:(XSJHttpRequestSuccess)success
                           failure:(XSJHttpRequestFailed)failure;

/**
 *  GET请求,自动缓存
 *
 *  @param URL           请求地址
 *  @param parameters    请求参数
 *  @param responseCache 缓存数据的回调
 *  @param success       请求成功的回调
 *  @param failure       请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(id)parameters
                     responseCache:(XSJHttpRequestCache)responseCache
                           success:(XSJHttpRequestSuccess)success
                           failure:(XSJHttpRequestFailed)failure;

/**
 *  POST请求,无缓存
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                            success:(XSJHttpRequestSuccess)success
                            failure:(XSJHttpRequestFailed)failure;

/**
 *  POST请求,自动缓存
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(id)parameters
                      responseCache:(XSJHttpRequestCache)responseCache
                            success:(XSJHttpRequestSuccess)success
                            failure:(XSJHttpRequestFailed)failure;

/**
 *  上传文件
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                                      parameters:(id)parameters
                                            name:(NSString *)name
                                        filePath:(NSString *)filePath
                                        progress:(XSJHttpProgress)progress
                                         success:(XSJHttpRequestSuccess)success
                                         failure:(XSJHttpRequestFailed)failure;

/**
 *  上传单/多张图片
 *
 *  @param URL        请求地址
 *  @param parameters 请求参数
 *  @param name       图片对应服务器上的字段
 *  @param images     图片数组
 *  @param fileNames  图片文件名数组, 可以为nil, 数组内的文件名默认为当前日期时间"yyyyMMddHHmmss"
 *  @param imageScale 图片文件压缩比 范围 (0.f ~ 1.f)
 *  @param imageType  图片文件的类型,例:png、jpg(默认类型)....
 *  @param progress   上传进度信息
 *  @param success    请求成功的回调
 *  @param failure    请求失败的回调
 *
 *  @return 返回的对象可取消请求,调用cancel方法
 */
+ (__kindof NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                                        parameters:(id)parameters
                                              name:(NSString *)name
                                            images:(NSArray<UIImage *> *)images
                                         fileNames:(NSArray<NSString *> *)fileNames
                                        imageScale:(CGFloat)imageScale
                                         imageType:(NSString *)imageType
                                          progress:(XSJHttpProgress)progress
                                           success:(XSJHttpRequestSuccess)success
                                           failure:(XSJHttpRequestFailed)failure;

/**
 *  下载文件
 *
 *  @param URL      请求地址
 *  @param fileDir  文件存储目录(默认存储目录为Download)
 *  @param progress 文件下载的进度信息
 *  @param success  下载成功的回调(回调参数filePath:文件的路径)
 *  @param failure  下载失败的回调
 *
 *  @return 返回NSURLSessionDownloadTask实例，可用于暂停继续，暂停调用suspend方法，开始下载调用resume方法
 */
+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)URL
                                       fileDir:(NSString *)fileDir
                                      progress:(XSJHttpProgress)progress
                                       success:(void(^)(NSString *filePath))success
                                       failure:(XSJHttpRequestFailed)failure;


/*
 **************************************  说明  **********************************************
 *
 * 在一开始设计接口的时候就想着方法接口越少越好,越简单越好,只有GET,POST,上传,下载,监测网络状态就够了.
 *
 * 无奈的是在实际开发中,每个APP与后台服务器的数据交互都有不同的请求格式,如果要修改请求格式,就要在此封装
 * 内修改,再加上此封装在支持CocoaPods后,如果使用者pod update最新XSJNetworkHelper,那又要重新修改此
 * 封装内的相关参数.
 *
 * 依个人经验,在项目的开发中,一般都会将网络请求部分封装 2~3 层,第2层配置好网络请求工具的在本项目中的各项
 * 参数,其暴露出的方法接口只需留出请求URL与参数的入口就行,第3层就是对整个项目请求API的封装,其对外暴露出的
 * 的方法接口只留出请求参数的入口.这样如果以后项目要更换网络请求库或者修改请求URL,在单个文件内完成配置就好
 * 了,大大降低了项目的后期维护难度
 *
 * 综上所述,最终还是将设置参数的接口暴露出来,如果通过CocoaPods方式使用XSJNetworkHelper,在设置项目网络
 * 请求参数的时候,强烈建议开发者在此基础上再封装一层,通过以下方法配置好各种参数与请求的URL,便于维护
 *
 **************************************  说明  **********************************************
 */

#pragma mark - 设置AFHTTPSessionManager相关属性
#pragma mark 注意: 因为全局只有一个AFHTTPSessionManager实例,所以以下设置方式全局生效
/**
 在开发中,如果以下的设置方式不满足项目的需求,就调用此方法获取AFHTTPSessionManager实例进行自定义设置
 (注意: 调用此方法时在要导入AFNetworking.h头文件,否则可能会报找不到AFHTTPSessionManager的❌)
 @param sessionManager AFHTTPSessionManager的实例
 */
+ (void)setAFHTTPSessionManagerProperty:(void(^)(AFHTTPSessionManager *sessionManager))sessionManager;

/**
 *  设置网络请求参数的格式:默认为二进制格式
 *
 *  @param requestSerializer XSJRequestSerializerJSON(JSON格式),XSJRequestSerializerHTTP(二进制格式),
 */
+ (void)setRequestSerializer:(XSJRequestSerializer)requestSerializer;

/**
 *  设置服务器响应数据格式:默认为JSON格式
 *
 *  @param responseSerializer XSJResponseSerializerJSON(JSON格式),XSJResponseSerializerHTTP(二进制格式)
 */
+ (void)setResponseSerializer:(XSJResponseSerializer)responseSerializer;

/**
 *  设置请求超时时间:默认为30S
 *
 *  @param time 时长
 */
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;

/**
 *  设置代理服务器，用于访问内网服务器，如果存在host 和url 就证明需要连接代理服务器
 *  只有在DEBUG模式下才会实现这个功能，Release 下自动访问外网服务器
 *  @param proxyHost host
 *  @param proxyPort 端口号
 *  @param baseUrl 基础链接
 */
+ (void)setDebugProxyHost:(NSString *)proxyHost proxyPort:(int)proxyPort baseUrl:(NSString *)baseUrl;

/// 设置请求头
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 *  是否打开网络状态转圈菊花:默认打开
 *
 *  @param open YES(打开), NO(关闭)
 */
+ (void)openNetworkActivityIndicator:(BOOL)open;

/**
 配置自建证书的Https请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103
 
 @param cerPath 自建Https证书的路径
 @param validatesDomainName 是否需要验证域名，默认为YES. 如果证书的域名与请求的域名不一致，需设置为NO; 即服务器使用其他可信任机构颁发
 的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName=NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外
 一个域名。因为SSL证书上的域名是独立的,假如证书上注册的域名是www.google.com, 那么mail.google.com是无法验证通过的.
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;

@end
