//
//  KeyboardLedKeyPairs.h
//  OpenMyKeyboardLed
//
//  Created by Chris Wang on 2016/12/9.
//  Copyright © 2016年 Chris. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeyboardLedKey.h"

@interface KeyboardLedKeyPairs : NSObject

@property (nonatomic, strong) NSString *ledKeyName;
@property (nonatomic, strong) KeyboardLedKey *onKey;
@property (nonatomic, strong) KeyboardLedKey *offKey;

@end
