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

@interface AppDelegate () <CBPeripheralManagerDelegate>
@property (nonatomic,strong) CBPeripheralManager *manager;

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

    _manager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                       queue:nil];
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
    if (_manager.isAdvertising) {
        // ignore
    } else {
        NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:_settings.proximityUUID];
        
        BLCBeaconAdvertisementData *beaconData =
            [[BLCBeaconAdvertisementData alloc] initWithProximityUUID:proximityUUID
                                                                major:_settings.major
                                                                minor:_settings.minor
                                                        measuredPower:_settings.measuredPower];
        [_manager startAdvertising:beaconData.beaconAdvertisement];
        
        [_startItem setEnabled:NO];
        [_stopItem setEnabled:YES];
    }
}

- (void)stopBeacon:(id)sender
{
    LOG_METHOD;
    if (_manager.isAdvertising) {
        [_manager stopAdvertising];
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
    _startItem = [_menu addItemWithTitle:@"Start Beacon" action:@selector(startBeacon:) keyEquivalent:@"r"];
    [_startItem setKeyEquivalentModifierMask:NSCommandKeyMask]; // Command+r
    [_startItem setEnabled:NO];
    _stopItem = [_menu addItemWithTitle:@"Stop Beacon" action:@selector(stopBeacon:) keyEquivalent:@"."];
    [_stopItem setKeyEquivalentModifierMask:NSCommandKeyMask]; // Command+.
    [_stopItem setEnabled:NO];
    
    [_menu addItem:[NSMenuItem separatorItem]];
    [_menu addItemWithTitle:@"Edit Tag" action:@selector(editTag:) keyEquivalent:@""];
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
@end
