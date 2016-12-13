//
//  SUObjectCategory.m
//  SharedUtils
//
//  Created by Chris Wang on 7/29/15.
//  Copyright (c) 2015 SharedUtils. All rights reserved.
//

#import "SUObjectCategory.h"
#import <objc/runtime.h>

static const void *suObjectDumpObjKey1 = &suObjectDumpObjKey1;
static const void *suObjectDumpObjKey2 = &suObjectDumpObjKey2;

@implementation NSObject (SUObjectCategory)

- (void)setDumpObject1:(id)dumpObject1
{
    objc_setAssociatedObject(self, suObjectDumpObjKey1, dumpObject1, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)dumpObject1
{
    return objc_getAssociatedObject(self, suObjectDumpObjKey1);
}

- (void)setDumpObject2:(id)dumpObject2
{
    objc_setAssociatedObject(self, suObjectDumpObjKey2, dumpObject2, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)dumpObject2
{
    return objc_getAssociatedObject(self, suObjectDumpObjKey2);
}

@end
