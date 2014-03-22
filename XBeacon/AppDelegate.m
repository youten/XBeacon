//
//  AppDelegate.m
//  XBeacon
//
//  Created by youten on 2013/11/28.
//  Copyright (c) 2013年 youten. All rights reserved.
//

#import "AppDelegate.h"
#import <IOBluetooth/IOBluetooth.h>
#import "BLCBeaconAdvertisementData.h"
#import "Settings.h"

#define KC_SPACE 49
#define KC_COMMAND 55
#define KC_OPTION 58
#define KC_P 35
#define KC_ESC 53
#define KC_LEFT 123
#define KC_RIGHT 124
#define KC_UP 126
#define KC_DOWN 125

// 1802 Immediate Alert
static NSString * SERVICE_IMMEDIATE_ALERT = @"00001802-0000-1000-8000-00805f9b34fb";
static NSString * CHAR_ALERT_LEVEL = @"00002a06-0000-1000-8000-00805f9b34fb";

@interface AppDelegate () <CBPeripheralManagerDelegate>

@property (weak) IBOutlet NSButton  *saveButton;
@property (weak) IBOutlet NSTextField *uuidTextField;
@property (weak) IBOutlet NSTextField *majorValueTextField;
@property (weak) IBOutlet NSTextField *minorValueTextField;
@property (weak) IBOutlet NSTextField *measuredPowerTextField;

- (IBAction)saveButtonTapped:(id)sender;

@end

@implementation AppDelegate {
    Settings *_settings;
    NSStatusItem *_statusItem;
    NSMenu *_menu;
    NSMenuItem *_startItem;
    NSMenuItem *_stopItem;
    
    CBPeripheralManager *_peripheralManager;
    CBMutableService *_immediateAlertService;
    CBMutableCharacteristic *_alertLevelChar;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self updateMenu];
    _settings = [[Settings alloc] init];
    [_settings loadFromUserDefaults];
    [_uuidTextField setStringValue:_settings.proximityUUID];
    [_majorValueTextField setIntegerValue:_settings.major];
    [_minorValueTextField setIntegerValue:_settings.minor];
    [_measuredPowerTextField setIntegerValue:_settings.measuredPower];

    if (!_peripheralManager) {
        [self initService];
    }
}

// God is there.
// Use a Bluetooth 4 enabled Mac running Mavericks as an iBeacon
// https://github.com/mttrb/BeaconOSX/

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [_startItem setEnabled:YES];
    }
}

- (void)startBeacon:(id)sender
{
    LOG_METHOD;
    if (_peripheralManager.isAdvertising) {
        // ignore
    } else {
        [_peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:
                                         @[_immediateAlertService.UUID],
                                     CBAdvertisementDataLocalNameKey:@"Masakari"}];
        
        [_startItem setEnabled:NO];
        [_stopItem setEnabled:YES];
    }
}

- (void)stopBeacon:(id)sender
{
    LOG_METHOD;
    if (_peripheralManager.isAdvertising) {
        [_peripheralManager stopAdvertising];
        [_startItem setEnabled:YES];
        [_stopItem setEnabled:NO];
    } else {
        // ignore
    }
}

- (void)editTag:(id)sender
{
    LOG_METHOD;
    // ウィンドウを前へ、前へ、一番前へ
    // http://xcatsan.blogspot.jp/2009/02/blog-post_12.html
    [NSApp activateIgnoringOtherApps:YES];
    [_window makeKeyAndOrderFront:self];
}

- (void)saveButtonTapped:(id)sender
{
    LOG_METHOD;
    _settings.proximityUUID = [_uuidTextField stringValue];
    _settings.major = [_majorValueTextField integerValue];
    _settings.minor = [_minorValueTextField integerValue];
    _settings.measuredPower = [_measuredPowerTextField integerValue];
    [_settings saveToUserDefaults];
}

#pragma menu

// [UI]
// Start Beacon
// Stop Beacon
// ----
// Edit Tag
// ----
// Quit
- (void)updateMenu
{
    LOG_METHOD;

    if (_menu == nil) {
        _menu = [[NSMenu alloc] init];
    } else {
        [_menu removeAllItems];
    }
    [_menu setAutoenablesItems:NO];
    _startItem = [_menu addItemWithTitle:@"Start Masakari" action:@selector(startBeacon:) keyEquivalent:@"r"];
    [_startItem setKeyEquivalentModifierMask:NSCommandKeyMask]; // Command+r
    [_startItem setEnabled:NO];
    _stopItem = [_menu addItemWithTitle:@"Stop Masakari" action:@selector(stopBeacon:) keyEquivalent:@"."];
    [_stopItem setKeyEquivalentModifierMask:NSCommandKeyMask]; // Command+.
    [_stopItem setEnabled:NO];
    
    // [_menu addItem:[NSMenuItem separatorItem]];
    // [_menu addItemWithTitle:@"Edit Tag" action:@selector(editTag:) keyEquivalent:@""];
    [_menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quitItem = [_menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    [quitItem setKeyEquivalentModifierMask:NSCommandKeyMask]; // Command+q
    
    // create menu
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    _statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setImage:[NSImage imageNamed:@"bt-icon"]];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:_menu];
}

#pragma mark BLE service and characteristic


- (void)initService {
    // init Peripheral Manager
    if (!_peripheralManager) {
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
    
    // init BLE Characteristic for Alert Level
    _alertLevelChar = [[CBMutableCharacteristic alloc]
                       initWithType:[CBUUID UUIDWithString:CHAR_ALERT_LEVEL]
                       properties:CBCharacteristicPropertyWrite
                       value:nil
                       permissions:CBAttributePermissionsWriteable];
    
    // init BLE Immediate Alert Service
    _immediateAlertService = [[CBMutableService alloc]
                              initWithType:[CBUUID UUIDWithString:SERVICE_IMMEDIATE_ALERT]
                              primary:YES];
    _immediateAlertService.characteristics = @[_alertLevelChar];
    
    @try {
        [_peripheralManager addService:_immediateAlertService];
    }
    @catch (NSException *exception) {
        LOG(@"Peripheral addService Error name=%@, reason=%@", exception.name, exception.reason);
        _peripheralManager = nil;
    }
    @finally {
    }
}

#pragma mark WriteRequest

- (void)peripheralManager:(CBPeripheralManager *)peripheral
  didReceiveWriteRequests:(NSArray *)requests
{
    
    for (CBATTRequest *request in requests) {
        if ([request.characteristic.UUID isEqual:_alertLevelChar.UUID]) {
            NSString *stringValue = [self toHex:request.value];
            LOG(@"written:%@", stringValue);
            [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
            
            if( [@"00" isEqualToString:stringValue] ) {
                [self sendKey:KC_UP];
            } else if( [@"01" isEqualToString:stringValue] ){
                [self sendKey:KC_DOWN];
            } else if( [@"02" isEqualToString:stringValue] ){
                [self sendKey:KC_ESC];
            } else if( [@"03" isEqualToString:stringValue] ){
                [self sendKey:KC_P];
            }
        } else {
            [_peripheralManager respondToRequest:request withResult:CBATTErrorAttributeNotFound];
        }
    }
}

#pragma mark util

- (void) sendKey:(int) keycode
{
    // http://stackoverflow.com/questions/3202629/where-can-i-find-a-list-of-mac-virtual-key-codes
    // http://stackoverflow.com/questions/21878987/mac-send-key-event-to-background-window
    CGEventRef commandDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)KC_COMMAND, true);
    CGEventRef commandUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)KC_COMMAND, false);
    CGEventRef optionDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)KC_OPTION, true);
    CGEventRef optionUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)KC_OPTION, false);
    
    CGEventRef keyDown = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)keycode, true);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)keycode, false);
    
    if ( keycode == KC_P) {
        // http://stackoverflow.com/questions/15206825/cmdoptiond-simulation-in-cocoa
        CGEventSetFlags(keyDown, kCGEventFlagMaskCommand ^ kCGEventFlagMaskAlternate);
        CGEventSetFlags(keyUp, kCGEventFlagMaskCommand ^ kCGEventFlagMaskAlternate);
        CGEventPost(0, commandDown);
        CGEventPost(0, optionDown);
    }
    CGEventPost(0, keyDown);
    CGEventPost(0, keyUp);
    if ( keycode == KC_P) {
        CGEventPost(0, commandUp);
        CGEventPost(0, optionUp);
    }
    
    CFRelease(commandDown);
    CFRelease(commandUp);
    CFRelease(optionDown);
    CFRelease(optionUp);
    CFRelease(keyDown);
    CFRelease(keyUp);
}


- (NSString *) toHex:(NSData *) data
{
    NSMutableString *str = [NSMutableString stringWithCapacity:64];
    NSInteger length = [data length];
    char *bytes = malloc(sizeof(char) * length);
    
    [data getBytes:bytes length:length];
    
    for (int i = 0; i < length; i++)
    {
        [str appendFormat:@"%02.2hhx", bytes[i]];
    }
    free(bytes);
    
    return str;
}

- (NSData *) toDataFromHex:(NSString *) hex
{
    NSString *trim = [hex stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    NSMutableData *data= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i = 0; i < [trim length] / 2; i++) {
        byte_chars[0] = [trim characterAtIndex:i * 2];
        byte_chars[1] = [trim characterAtIndex:i * 2 + 1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    
    return [data copy];
}


@end
