//
//  UIDevice+Category.h
//  proj
//
//  Created by asdasd on 2017/12/21.
//  Copyright © 2017年 asdasd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (XSJRequest)

+ (NSString *)identifierNumber;

+ (NSString *)userPhoneName;

+ (NSString *)deviceName;

+ (NSString *)phoneVersion;

+ (NSString *)phoneModel;

+ (NSString *)localPhoneModel;


+ (NSString *)appCurName;


+ (NSString *)appCurVersion;

+ (NSString *)appCurVersionNum;

//  判断是否是iPhoneX以后有刘海的机型
+(BOOL)isPhoneXLater;

@end
