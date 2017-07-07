//
//  RCTWeiboAPI.h
//  RCTWeiboAPI
//
//  Created by LvBingru on 1/6/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTLog.h>
#import "LLPaySdk.h"

@interface RCTLianLianAPI : NSObject<RCTBridgeModule, LLPaySdkDelegate>

@end
