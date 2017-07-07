//
//  RCTWeiboAPI.m
//  RCTWeiboAPI
//
//  Created by LvBingru on 1/6/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import "RCTLianLianAPI.h"
#import "LLPaySdk.h"
#import "LLPayUtil.h"
#import "LLOrder.h"

#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTImageLoader.h>
#import <React/RCTConvert.h>


static LLPayType payType = LLPayTypeVerify;

@interface RCTLianLianAPI ()

@property (nonatomic, retain) NSMutableDictionary *orderDic;
@property (nonatomic, strong) NSString *resultTitle;
@property (nonatomic, strong) NSString *kLLOidPartner;// 商户号
@property (nonatomic, strong) NSString *kLLPartnerKey;// 密钥
@property (nonatomic, strong) NSString *signType; //签名方式
@property (nonatomic) BOOL isTest; //签名方式
@property (nonatomic, strong) RCTResponseSenderBlock callback; //签名方式
@end

@implementation RCTLianLianAPI

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(initSdk:(NSString *)partner partnerKey:(NSString *)partnerKey isTest:(BOOL)isTest)
{
    RCTLogInfo(
               @"\nLLPaySDK--Version\nSDKVersion:\t\t\t%@\nSDKBuildVersion:\t%@\n",
               kLLPaySDKVersion,kLLPaySDKBuildVersion
               );
    
    
    self.resultTitle = nil;
    self.kLLOidPartner = partner;
    self.kLLPartnerKey = partnerKey;
    self.signType = @"MD5"; //签名方式
    self.isTest = isTest;
    
}

RCT_EXPORT_METHOD(pay:(NSString *)details callback:(RCTResponseSenderBlock)callback)
{
    RCTLogInfo(@"pay details %@", details);
    self.callback =callback;

    self.resultTitle = @"签约结果";

    //NSString *reqData = [RCTConvert NSString:details];
    
    [LLPaySdk sharedSdk].sdkDelegate = self;
    
    NSDictionary *signedOrder = [self dictionaryWithJsonString:details];

//    RCTLogInfo(@"pay signedOrder %@", signedOrder);

    
//    LLOrder* _order = [self create:details];
//    
//    
//    self.orderDic = [[_order tradeInfoForPayment] mutableCopy];
//    
//    LLPayUtil *payUtil = [[LLPayUtil alloc] init];
//    
//    
//    NSDictionary *signedOrder =
//    [payUtil signedOrderDic:self.orderDic andSignKey:self.kLLPartnerKey];
//    [LLPaySdk sharedSdk].sdkDelegate = self;
//    RCTLogInfo(@"pay signedOrder %@", signedOrder);

    UIViewController *controller = UIApplication.sharedApplication.delegate.window.rootViewController;
    
    [[LLPaySdk sharedSdk] presentLLPaySDKInViewController:controller
                                               withPayType:payType
                                             andTraderInfo:signedOrder];
}


//josnString2NSDictionary
-(NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

#pragma mark - 创建订单

- (LLOrder*)create:(NSDictionary *)details{
    
    LLOrder* _order = [[LLOrder alloc] initWithLLPayType:payType];
    NSString *timeStamp = [LLOrder timeStamp];
    _order.oid_partner = self.kLLOidPartner;
    _order.sign_type = self.signType;
    
    _order.busi_partner = [RCTConvert NSString:details[@"busi_partner"]];
    
    _order.no_order = [RCTConvert NSString:details[@"no_order"]];
    _order.dt_order = timeStamp;
    _order.money_order = [RCTConvert NSString:details[@"money_order"]];
    _order.notify_url = [RCTConvert NSString:details[@"notify_url"]];
    
    _order.valid_order = [RCTConvert NSString:details[@"valid_order"]];
    
    _order.acct_name = [RCTConvert NSString:details[@"acct_name"]];
    _order.card_no = [RCTConvert NSString:details[@"card_no"]];
    _order.id_no = [RCTConvert NSString:details[@"id_no"]];
    
    _order.no_agree = [RCTConvert NSString:details[@"no_agree"]];
    
    _order.risk_item = [LLOrder llJsonStringOfObj:@{
                                                    @"user_info_bind_phone" : [RCTConvert NSString:details[@"user_info_bind_phone"]],
                                                    @"user_info_dt_register" : [RCTConvert NSString:details[@"user_info_dt_register"]],
                                                    @"frms_ware_category" : [RCTConvert NSString:details[@"frms_ware_category"]],
                                                    @"request_imei" : [RCTConvert NSString:details[@"request_imei"]]
                                                    }];
    _order.user_id = [RCTConvert NSString:details[@"user_id"]];
    _order.name_goods = [RCTConvert NSString:details[@"name_goods"]];
    
    _order.flag_modify = [RCTConvert NSString:details[@"flag_modify"]];
    return _order;
}

#pragma - mark 支付结果 LLPaySdkDelegate
// 订单支付结果返回，主要是异常和成功的不同状态
// TODO: 开发人员需要根据实际业务调整逻辑
- (void)paymentEnd:(LLPayResult)resultCode withResultDic:(NSDictionary *)dic {
    
    NSString *msg = @"异常";
    switch (resultCode) {
        case kLLPayResultSuccess: {
            msg = @"成功";
        } break;
        case kLLPayResultFail: {
            msg = @"失败";
        } break;
        case kLLPayResultCancel: {
            msg = @"取消";
        } break;
        case kLLPayResultInitError: {
            msg = @"sdk初始化异常";
        } break;
        case kLLPayResultInitParamError: {
            msg = dic[@"ret_msg"];
        } break;
        default:
            break;
    }
    
    NSString *showMsg =
    [msg stringByAppendingString:[LLPayUtil jsonStringOfObj:dic]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.resultTitle
                                                                   message:showMsg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确认"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    self.callback(@[msg, dic]);
    //    callback.invoke(false, null, retCode, strRet);
    //    [self presentViewController:alert animated:YES completion:nil];
}

@end
