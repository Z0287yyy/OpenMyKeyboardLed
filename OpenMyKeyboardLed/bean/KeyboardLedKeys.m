//
//  KeyboardLedKeys.m
//  OpenMyKeyboardLed
//
//  Created by Chris Wang on 2016/12/8.
//  Copyright © 2016年 Chris. All rights reserved.
//

#import "KeyboardLedKeys.h"

@implementation KeyboardLedKeys

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.ledKeys = [NSMutableArray array];
        self.ledPairsKeys = [NSMutableArray array];
    }
    return self;
}

- (void)addLedKey:(KeyboardLedKey *)ledKey withLedKeyName:(NSString *)ledKeyName {
    [self.ledKeys addObject:ledKey];

    BOOL hasAdded = NO;
    for (KeyboardLedKeyPairs *keyPairs in self.ledPairsKeys) {
        if (ledKey.tCFIndex == 1) {
            if (keyPairs.offKey.ledKeyIndex == ledKey.ledKeyIndex) {
                keyPairs.onKey = ledKey;
                hasAdded = YES;
                break;
            }
        } else {
            if (keyPairs.onKey.ledKeyIndex == ledKey.ledKeyIndex) {
                keyPairs.offKey = ledKey;
                hasAdded = YES;
                break;
            }
        }
        
    }
    if (!hasAdded) {
        KeyboardLedKeyPairs *keyPairs = [[KeyboardLedKeyPairs alloc] init];
        keyPairs.ledKeyName = ledKeyName;
        if (ledKey.tCFIndex == 1) {
            keyPairs.onKey = ledKey;
        } else {
            keyPairs.offKey = ledKey;
        }
        [self.ledPairsKeys addObject:keyPairs];
    }
    
}


- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (other == nil || ![other isKindOfClass:self.class]) {
        return NO;
    } else {
        KeyboardLedKeys *otherKeys = other;
        return (otherKeys.deviceKey != nil && [otherKeys.deviceKey isEqual:self.deviceKey]);
    }
}

- (NSUInteger)hash
{
    return self.deviceKey.hash + 10 * 3 + 5 +1;
}

@end
