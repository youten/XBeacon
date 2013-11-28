//
//  Settings.m
//  XBeacon
//
//  Created by youten on 2013/10/13.
//  Copyright (c) 2013年 youten. All rights reserved.
//

#import "Settings.h"

@implementation Settings

static NSString * const KEY_PROXIMITY_UUID = @"proximityUUID";
static NSString * const KEY_MAJOR = @"major";
static NSString * const KEY_MINOR = @"minor";
static NSString * const KEY_MEASURED_POWER = @"measuredPower";

- (void)saveToUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_proximityUUID forKey:KEY_PROXIMITY_UUID];
    [defaults setInteger:_major forKey:KEY_MAJOR];
    [defaults setInteger:_minor forKey:KEY_MINOR];
    [defaults setInteger:_measuredPower forKey:KEY_MEASURED_POWER];
    [defaults synchronize];
}

- (void)loadFromUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _proximityUUID = [defaults objectForKey:KEY_PROXIMITY_UUID];
    if (!_proximityUUID) {
        _proximityUUID = @"895B905A-074B-440A-8CA5-C6D855ED4A42";
    }
    _major = [defaults integerForKey:KEY_MAJOR];
    if ((_major <= 0) || (32768 <= _major)) {
        _major = 1;
    }
    _minor = [defaults integerForKey:KEY_MINOR];
    if ((_minor <= 0) || (32768 <= _minor)) {
        _minor = 3;
    }
    _measuredPower = [defaults integerForKey:KEY_MEASURED_POWER];
    if ( (_measuredPower <= -128) || (0 <= _measuredPower)) {
        _measuredPower = -59;
    }
}

@end
