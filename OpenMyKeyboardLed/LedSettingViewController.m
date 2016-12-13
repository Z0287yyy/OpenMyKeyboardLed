//
//  LedSettingViewController.m
//  OpenMyKeyboardLed
//
//  Created by Chris Wang on 2016/12/8.
//  Copyright © 2016年 Chris. All rights reserved.
//

#import "LedSettingViewController.h"
#import "SUObjectCategory.h"
#import "KeyboardLedKeys.h"



// ****************************************************
#pragma mark -
#pragma mark * complation directives *
// ----------------------------------------------------

#ifndef FALSE
#define FALSE 0
#define TRUE !FALSE
#endif

// ****************************************************
#pragma mark -
#pragma mark * includes & imports *
// ----------------------------------------------------

#include <CoreFoundation/CoreFoundation.h>
#include <Carbon/Carbon.h>
#include <IOKit/hid/IOHIDLib.h>

// ****************************************************
#pragma mark -
#pragma mark * typedef's, struct's, enums, defines, etc. *
// ----------------------------------------------------
// function to create a matching dictionary for usage page & usage
static CFMutableDictionaryRef hu_CreateMatchingDictionaryUsagePageUsage( Boolean isDeviceNotElement,
                                                                        UInt32 inUsagePage,
                                                                        UInt32 inUsage )
{
    // create a dictionary to add usage page / usages to
    CFMutableDictionaryRef result = CFDictionaryCreateMutable( kCFAllocatorDefault,
                                                              0,
                                                              &kCFTypeDictionaryKeyCallBacks,
                                                              &kCFTypeDictionaryValueCallBacks );
    
    if ( result ) {
        if ( inUsagePage ) {
            // Add key for device type to refine the matching dictionary.
            CFNumberRef pageCFNumberRef = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &inUsagePage );
            
            if ( pageCFNumberRef ) {
                if ( isDeviceNotElement ) {
                    CFDictionarySetValue( result, CFSTR( kIOHIDDeviceUsagePageKey ), pageCFNumberRef );
                } else {
                    CFDictionarySetValue( result, CFSTR( kIOHIDElementUsagePageKey ), pageCFNumberRef );
                }
                CFRelease( pageCFNumberRef );
                
                // note: the usage is only valid if the usage page is also defined
                if ( inUsage ) {
                    CFNumberRef usageCFNumberRef = CFNumberCreate( kCFAllocatorDefault, kCFNumberIntType, &inUsage );
                    
                    if ( usageCFNumberRef ) {
                        if ( isDeviceNotElement ) {
                            CFDictionarySetValue( result, CFSTR( kIOHIDDeviceUsageKey ), usageCFNumberRef );
                        } else {
                            CFDictionarySetValue( result, CFSTR( kIOHIDElementUsageKey ), usageCFNumberRef );
                        }
                        CFRelease( usageCFNumberRef );
                    } else {
                        fprintf( stderr, "%s: CFNumberCreate( usage ) failed.", __PRETTY_FUNCTION__ );
                    }
                }
            } else {
                fprintf( stderr, "%s: CFNumberCreate( usage page ) failed.", __PRETTY_FUNCTION__ );
            }
        }
    } else {
        fprintf( stderr, "%s: CFDictionaryCreateMutable failed.", __PRETTY_FUNCTION__ );
    }
    return result;
}	// hu_CreateMatchingDictionaryUsagePageUsage


@interface LedSettingViewController () <NSTableViewDelegate, NSTableViewDataSource>
{
    NSInteger selKeyboard;
}
@property (weak) IBOutlet NSButton *btnScan;
@property (weak) IBOutlet NSTableView *tvLedKeyboards;
@property (weak) IBOutlet NSTableView *tvLedKeys;



@property (nonatomic, strong) NSMutableArray *allKBLedKeys;

@end


@implementation LedSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    selKeyboard = 0;
    self.allKBLedKeys = [NSMutableArray array];
    
    self.tvLedKeyboards.delegate = self;
    self.tvLedKeyboards.dataSource = self;
    
    self.tvLedKeys.delegate = self;
    self.tvLedKeys.dataSource = self;
}


- (IBAction)onScanLedKeyClicked:(id)sender {
    [self.allKBLedKeys removeAllObjects];
    [self.tvLedKeyboards reloadData];
    [self.tvLedKeys reloadData];
    
    [self scanLedKey];
    [self intLedKeyControllerUi];
}


- (void)intLedKeyControllerUi {
    [self.tvLedKeyboards reloadData];
    [self.tvLedKeys reloadData];
}

- (void)onLedKeyClicked:(NSButton *)ledBtn {
    
}

- (void)scanLedKey {
#pragma unused ( argc, argv )
    IOHIDDeviceRef * tIOHIDDeviceRefs = nil;
    
    // create a IO HID Manager reference
    IOHIDManagerRef tIOHIDManagerRef = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone );
    require( tIOHIDManagerRef, Oops );
    
    // Create a device matching dictionary
    CFDictionaryRef matchingCFDictRef = hu_CreateMatchingDictionaryUsagePageUsage( TRUE,
                                                                                  kHIDPage_GenericDesktop,
                                                                                  kHIDUsage_GD_Keyboard );
    require( matchingCFDictRef, Oops );
    
    // set the HID device matching dictionary
    IOHIDManagerSetDeviceMatching( tIOHIDManagerRef, matchingCFDictRef );
    
    if ( matchingCFDictRef ) {
        CFRelease( matchingCFDictRef );
    }
    
    // Now open the IO HID Manager reference
    IOReturn tIOReturn = IOHIDManagerOpen( tIOHIDManagerRef, kIOHIDOptionsTypeNone );
    require_noerr( tIOReturn, Oops );
    
    // and copy out its devices
    CFSetRef deviceCFSetRef = IOHIDManagerCopyDevices( tIOHIDManagerRef );
    require( deviceCFSetRef, Oops );
    
    // how many devices in the set?
    CFIndex deviceIndex, deviceCount = CFSetGetCount( deviceCFSetRef );
    
    // allocate a block of memory to extact the device ref's from the set into
    tIOHIDDeviceRefs = malloc( sizeof( IOHIDDeviceRef ) * deviceCount );
    if (!tIOHIDDeviceRefs) {
        CFRelease(deviceCFSetRef);
        deviceCFSetRef = NULL;
        goto Oops;
    }
    
    // now extract the device ref's from the set
    CFSetGetValues( deviceCFSetRef, (const void **) tIOHIDDeviceRefs );
    CFRelease(deviceCFSetRef);
    deviceCFSetRef = NULL;
    
    // before we get into the device loop we'll setup our element matching dictionary
    matchingCFDictRef = hu_CreateMatchingDictionaryUsagePageUsage( FALSE, kHIDPage_LEDs, 0 );
    require( matchingCFDictRef, Oops );
    
    
    int pass;	// do 256 passes
    for ( pass = 0; pass < 256; pass++ ) {
        
        if (pass > 1) {
            BOOL allLedKeysGot = YES;
            for (KeyboardLedKeys *hKeys in self.allKBLedKeys) {
                if (hKeys.expectedLedKeysCount != hKeys.ledKeys.count) {
                    allLedKeysGot = NO;
                    break;
                }
            }
            if (allLedKeysGot) {
                break;
            }
        }
        
        
        Boolean delayFlag = FALSE;	// if we find an LED element we'll set this to TRUE
        
        //printf( "pass = %d.\n", pass );
        for ( deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++ ) {
            
            // if this isn't a keyboard device...
            if ( !IOHIDDeviceConformsTo( tIOHIDDeviceRefs[deviceIndex], kHIDPage_GenericDesktop, kHIDUsage_GD_Keyboard ) ) {
                continue;	// ...skip it
            }
            
            //printf( "	 device = %p.\n", tIOHIDDeviceRefs[deviceIndex] );
            
            NSString *deviceKey = [NSString stringWithFormat:@"%p-%zi", tIOHIDDeviceRefs[deviceIndex], deviceIndex];
            KeyboardLedKeys *ledKeys = [[KeyboardLedKeys alloc] init];
            ledKeys.deviceKey = deviceKey;
            ledKeys.deviceIndex = deviceIndex;
            if ([self.allKBLedKeys containsObject:ledKeys]) {
                for (KeyboardLedKeys *hKeys in self.allKBLedKeys) {
                    if ([hKeys isEqual:ledKeys]) {
                        ledKeys = hKeys;
                        if (pass == 1) {
                            ledKeys.expectedLedKeysCount = ledKeys.ledKeys.count * 2;
                        } else if (pass > 1) {
                            if (ledKeys.expectedLedKeysCount == ledKeys.ledKeys.count) {
                                continue;
                            }
                        }
                        break;
                    }
                }
            } else {
                [self.allKBLedKeys addObject:ledKeys];
            }
            
            
            // copy all the elements
            CFArrayRef elementCFArrayRef = IOHIDDeviceCopyMatchingElements( tIOHIDDeviceRefs[deviceIndex],
                                                                           matchingCFDictRef,
                                                                           kIOHIDOptionsTypeNone );
            require( elementCFArrayRef, next_device );
            
            // for each device on the system these values are divided by the value ranges of all LED elements found
            // for example, if the first four LED element have a range of 0-1 then the four least significant bits of
            // this value will be sent to these first four LED elements, etc.
            int device_value = pass;
            
            // iterate over all the elements
            CFIndex elementIndex, elementCount = CFArrayGetCount( elementCFArrayRef );
            for ( elementIndex = 0; elementIndex < elementCount; elementIndex++ ) {
                IOHIDElementRef tIOHIDElementRef = ( IOHIDElementRef ) CFArrayGetValueAtIndex( elementCFArrayRef, elementIndex );
                require( tIOHIDElementRef, next_element );
                
                uint32_t usagePage = IOHIDElementGetUsagePage( tIOHIDElementRef );
                
                // if this isn't an LED element...
                if ( kHIDPage_LEDs != usagePage ) {
                    continue;	// ...skip it
                }
                
                uint32_t usage = IOHIDElementGetUsage( tIOHIDElementRef );
                IOHIDElementType tIOHIDElementType = IOHIDElementGetType( tIOHIDElementRef );
                //129 : kIOHIDElementTypeOutput
                
                //printf( "		 element = %p (page: %d, usage: %d, type: %d ).\n", tIOHIDElementRef, usagePage, usage, tIOHIDElementType );
                
                // get the logical mix/max for this LED element
                CFIndex minCFIndex = IOHIDElementGetLogicalMin( tIOHIDElementRef );
                CFIndex maxCFIndex = IOHIDElementGetLogicalMax( tIOHIDElementRef );
                
                // calculate the range
                CFIndex modCFIndex = maxCFIndex - minCFIndex + 1;
                
                // compute the value for this LED element
                CFIndex tCFIndex = minCFIndex + ( device_value % modCFIndex );
                device_value /= modCFIndex;
                
                //printf( "			 value = 0x%08lX.\n", tCFIndex );
                
                uint64_t timestamp = 0; // create the IO HID Value to be sent to this LED element
                IOHIDValueRef tIOHIDValueRef = IOHIDValueCreateWithIntegerValue( kCFAllocatorDefault, tIOHIDElementRef, timestamp, tCFIndex );
                if ( tIOHIDValueRef ) {
                    // now set it on the device
                    //tIOReturn = IOHIDDeviceSetValue( tIOHIDDeviceRefs[deviceIndex], tIOHIDElementRef, tIOHIDValueRef );
                    CFRelease( tIOHIDValueRef );
                    
                    NSString *ledKeyName = [NSString stringWithFormat:@"Key-%zi", elementIndex];
                    KeyboardLedKey *ledKey = [[KeyboardLedKey alloc] init];
                    ledKey.tCFIndex = tCFIndex;
                    ledKey.ledKeyIndex = elementIndex;
                    
                    
                    if (![ledKeys.ledKeys containsObject:ledKey]) {
                        [ledKeys addLedKey:ledKey withLedKeyName:ledKeyName];
                    }
                    
                    //require_noerr( tIOReturn, next_element );
                    delayFlag = TRUE;	// set this TRUE so we'll delay before changing our LED values again
                }
            next_element:	;
                continue;
            }
            CFRelease( elementCFArrayRef );
        next_device: ;
            continue;
        }
        
        // if we found an LED we'll delay before continuing
        if ( delayFlag ) {
            //usleep( 500000 ); // sleep one half second
        }
        
        // if the mouse is down…
        if (GetCurrentButtonState()) {
            break;	// abort pass loop
        }
    }						  // next pass
    
    if ( matchingCFDictRef ) {
        CFRelease( matchingCFDictRef );
    }
Oops:	;
    if ( tIOHIDDeviceRefs ) {
        free(tIOHIDDeviceRefs);
    }
    
    if ( tIOHIDManagerRef ) {
        CFRelease( tIOHIDManagerRef );
    }
}


- (void)lightLedKey:(KeyboardLedKey *)ledKey inLedKeys:(KeyboardLedKeys *)ledKeys {
    NSLog(@"xxxxxxx");
    
    IOHIDDeviceRef * tIOHIDDeviceRefs = nil;
    
    // create a IO HID Manager reference
    IOHIDManagerRef tIOHIDManagerRef = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone );
    
    // Create a device matching dictionary
    CFDictionaryRef matchingCFDictRef = hu_CreateMatchingDictionaryUsagePageUsage( TRUE,
                                                                                  kHIDPage_GenericDesktop,
                                                                                  kHIDUsage_GD_Keyboard );
    
    
    // set the HID device matching dictionary
    IOHIDManagerSetDeviceMatching( tIOHIDManagerRef, matchingCFDictRef );
    
    if ( matchingCFDictRef ) {
        CFRelease( matchingCFDictRef );
    }
    
    // Now open the IO HID Manager reference
    IOReturn tIOReturn = IOHIDManagerOpen( tIOHIDManagerRef, kIOHIDOptionsTypeNone );
    
    
    // and copy out its devices
    CFSetRef deviceCFSetRef = IOHIDManagerCopyDevices( tIOHIDManagerRef );
    
    // how many devices in the set?
    CFIndex deviceCount = CFSetGetCount( deviceCFSetRef );
    
    // allocate a block of memory to extact the device ref's from the set into
    tIOHIDDeviceRefs = malloc( sizeof( IOHIDDeviceRef ) * deviceCount );
    if (!tIOHIDDeviceRefs) {
        CFRelease(deviceCFSetRef);
        deviceCFSetRef = NULL;
        printf("error");
    }
    
    CFSetGetValues( deviceCFSetRef, (const void **) tIOHIDDeviceRefs );
    CFRelease(deviceCFSetRef);
    deviceCFSetRef = NULL;
    
    matchingCFDictRef = hu_CreateMatchingDictionaryUsagePageUsage( FALSE, kHIDPage_LEDs, 0 );
    
    
    
    
    CFArrayRef elementCFArrayRef = IOHIDDeviceCopyMatchingElements( tIOHIDDeviceRefs[ledKeys.deviceIndex],
                                                                   matchingCFDictRef,
                                                                   kIOHIDOptionsTypeNone );
    
    
    IOHIDElementRef tIOHIDElementRef = ( IOHIDElementRef ) CFArrayGetValueAtIndex( elementCFArrayRef, ledKey.ledKeyIndex );

    
    uint32_t usagePage = IOHIDElementGetUsagePage( tIOHIDElementRef );
    
    // if this isn't an LED element...
    if ( kHIDPage_LEDs != usagePage ) {
        return;	// ...skip it
    }
    
    uint32_t usage = IOHIDElementGetUsage( tIOHIDElementRef );
    IOHIDElementType tIOHIDElementType = IOHIDElementGetType( tIOHIDElementRef );
    
    //printf( "		 element = %p (page: %d, usage: %d, type: %d ).\n", tIOHIDElementRef, usagePage, usage, tIOHIDElementType );
    
    // get the logical mix/max for this LED element
    CFIndex minCFIndex = IOHIDElementGetLogicalMin( tIOHIDElementRef );
    CFIndex maxCFIndex = IOHIDElementGetLogicalMax( tIOHIDElementRef );
    
    // calculate the range
    CFIndex modCFIndex = maxCFIndex - minCFIndex + 1;
    
    // compute the value for this LED element
    CFIndex tCFIndex = ledKey.tCFIndex;
    
    //printf( "			 value = 0x%08lX.\n", tCFIndex );
    
    uint64_t timestamp = 0; // create the IO HID Value to be sent to this LED element
    IOHIDValueRef tIOHIDValueRef = IOHIDValueCreateWithIntegerValue( kCFAllocatorDefault, tIOHIDElementRef, timestamp, tCFIndex );
    if ( tIOHIDValueRef ) {
        // now set it on the device
        tIOReturn = IOHIDDeviceSetValue( tIOHIDDeviceRefs[ledKeys.deviceIndex], tIOHIDElementRef, tIOHIDValueRef );
        CFRelease( tIOHIDValueRef );
        
    }
    
    
    CFRelease( elementCFArrayRef );
    
    if ( matchingCFDictRef ) {
        CFRelease( matchingCFDictRef );
    }
    
    if ( tIOHIDDeviceRefs ) {
        free(tIOHIDDeviceRefs);
    }
    
    if ( tIOHIDManagerRef ) {
        CFRelease( tIOHIDManagerRef );
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - button action
- (void)onLedKeyOnClicked:(NSButton *)sender {
    [self lightLedKey:sender.dumpObject1 inLedKeys:sender.dumpObject2];
}

- (void)onLedKeyOffClicked:(NSButton *)sender {
    [self lightLedKey:sender.dumpObject1 inLedKeys:sender.dumpObject2];
}


#pragma mark - tableview delegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.tvLedKeyboards) {
        return self.allKBLedKeys.count;
    } else {
        if (self.allKBLedKeys.count == 0) {
            return 0;
        }
        KeyboardLedKeys *ledKeys = [self.allKBLedKeys objectAtIndex:selKeyboard];
        return ledKeys.ledPairsKeys.count;
    }
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSView *view = nil;
    if (tableView == self.tvLedKeyboards) {
        view = [tableView makeViewWithIdentifier:@"tvc_kb" owner:self];
        
        KeyboardLedKeys *ledKeys = [self.allKBLedKeys objectAtIndex:row];
        
        NSTextField *cell = [view viewWithTag:201];
        cell.stringValue = ledKeys.deviceKey;
        
    } else {
        KeyboardLedKeys *ledKeys = [self.allKBLedKeys objectAtIndex:selKeyboard];
        KeyboardLedKeyPairs *keyPairs = [ledKeys.ledPairsKeys objectAtIndex:row];

        if ([tableColumn.identifier isEqual:@"tc_lk_name"]) {
            [tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
            [tableColumn setResizingMask:NSTableColumnAutoresizingMask];
            
            view = [tableView makeViewWithIdentifier:@"tvc_lk_name" owner:self];
            
            NSTextField *cell = [view viewWithTag:202];
            cell.stringValue = keyPairs.ledKeyName;
            
        } else if ([tableColumn.identifier isEqual:@"tc_lk_on"]) {
            view = [tableView makeViewWithIdentifier:@"tvc_lk_on" owner:self];
            
            NSButton *onBtn = [view viewWithTag:203];
            onBtn.dumpObject2 = ledKeys;
            onBtn.dumpObject1 = keyPairs.onKey;
            onBtn.action = @selector(onLedKeyOnClicked:);
        } else if ([tableColumn.identifier isEqual:@"tc_lk_off"]) {
            view = [tableView makeViewWithIdentifier:@"tvc_lk_off" owner:self];
            
            NSButton *offBtn = [view viewWithTag:204];
            offBtn.dumpObject2 = ledKeys;
            offBtn.dumpObject1 = keyPairs.offKey;
            offBtn.action = @selector(onLedKeyOffClicked:);
        }
    }
    
    return view;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    // We don't want to change the selection if the user clicked in the fill color area
    NSInteger row = [tableView clickedRow];
    if (row > -1) {
        if (tableView == self.tvLedKeyboards) {
            selKeyboard = row;
            [self.tvLedKeys reloadData];
        } else {
            //KeyboardLedKeys *ledKeys = [self.allKBLedKeys objectAtIndex:selKeyboard];
            //KeyboardLedKeyPairs *keyPairs = [ledKeys.ledPairsKeys objectAtIndex:row];
            
            //NSLog(@"xxx:%@", proposedSelectionIndexes);
            
            //[self lightLedKey:ledKey inLedKeys:ledKeys];
        }
    }
    return proposedSelectionIndexes;
}


@end
