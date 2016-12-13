//
//  KeyboardLedKeys.h
//  OpenMyKeyboardLed
//
//  Created by Chris Wang on 2016/12/8.
//  Copyright © 2016年 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeyboardLedKey.h"
#import "KeyboardLedKeyPairs.h"

@interface KeyboardLedKeys : NSObject

@property (nonatomic) NSInteger expectedLedKeysCount;

@property (nonatomic, strong) NSString *deviceKey;
@property (nonatomic) CFIndex deviceIndex;
@property (nonatomic, strong) NSMutableArray *ledKeys;
@property (nonatomic, strong) NSMutableArray *ledPairsKeys;

- (void)addLedKey:(KeyboardLedKey *)ledKey withLedKeyName:(NSString *)ledKeyName;

@end
