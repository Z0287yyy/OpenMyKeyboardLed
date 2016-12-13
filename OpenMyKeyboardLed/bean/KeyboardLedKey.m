//
//  KeyboardLedKey.m
//  OpenMyKeyboardLed
//
//  Created by Chris Wang on 2016/12/8.
//  Copyright © 2016年 Chris. All rights reserved.
//

#import "KeyboardLedKey.h"

@implementation KeyboardLedKey

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (other == nil || ![other isKindOfClass:self.class]) {
        return NO;
    } else {
        KeyboardLedKey *oKey = other;
        return oKey.ledKeyIndex == self.ledKeyIndex && oKey.tCFIndex == self.tCFIndex;
    }
}

- (NSUInteger)hash
{
    return self.ledKeyIndex + self.tCFIndex + 39;
}

@end
