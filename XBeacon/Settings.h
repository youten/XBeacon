//
//  Settings.h
//  XBeacon
//
//  Created by youten on 2013/10/13.
//  Copyright (c) 2013年 youten. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject

@property (nonatomic, copy) NSString *proximityUUID;
@property (nonatomic, assign) NSInteger major;
@property (nonatomic, assign) NSInteger minor;
@property (nonatomic, assign) NSInteger measuredPower;

- (void)saveToUserDefaults;
- (void)loadFromUserDefaults;

@end
