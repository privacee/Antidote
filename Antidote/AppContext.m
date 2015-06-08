//
//  AppContext.m
//  Antidote
//
//  Created by Dmytro Vorobiov on 19.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "AppContext.h"
#import "AppearanceManager.h"
#import "EventsManager.h"
#import "ProfileManager.h"
#import "UserDefaultsManager.h"

@interface AppContext()

@property (strong, nonatomic, readwrite) AppearanceManager *appearance;
@property (strong, nonatomic, readwrite) EventsManager *events;
@property (strong, nonatomic, readwrite) ProfileManager *profileManager;
@property (strong, nonatomic, readwrite) UserDefaultsManager *userDefaults;

@end

@implementation AppContext

#pragma mark -  Lifecycle

- (id)init
{
    return nil;
}

- (id)initPrivate
{
    self = [super init];

    if (! self) {
        return nil;
    }

    return self;
}

+ (instancetype)sharedContext
{
    static AppContext *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[AppContext alloc] initPrivate];
    });

    return instance;
}

#pragma mark -  Properties

- (AppearanceManager *)appearance
{
    if (_appearance) {
        return _appearance;
    }

    AppearanceManagerColorscheme colorscheme = self.userDefaults.uCurrentColorscheme.unsignedIntegerValue;
    _appearance = [[AppearanceManager alloc] initWithColorscheme:colorscheme];

    return _appearance;
}

- (EventsManager *)events
{
    if (_events) {
        return _events;
    }

    _events = [EventsManager new];
    return _events;
}

- (ProfileManager *)profileManager
{
    if (_profileManager) {
        return _profileManager;
    }

    _profileManager = [ProfileManager new];
    return _profileManager;
}

- (UserDefaultsManager *)userDefaults
{
    if (_userDefaults) {
        return _userDefaults;
    }

    _userDefaults = [UserDefaultsManager new];
    [self createUserDefaultsValuesAndRewrite:NO];

    return _userDefaults;
}

#pragma mark -  Public

- (void)restoreDefaultSettings
{
    [self createUserDefaultsValuesAndRewrite:YES];
}

- (void)recreateAppearance
{
    self.appearance = nil;
}

#pragma mark -  Private

- (void)createUserDefaultsValuesAndRewrite:(BOOL)rewrite
{
    if (rewrite || ! self.userDefaults.uShowMessageInLocalNotification) {
        self.userDefaults.uShowMessageInLocalNotification = @(YES);
    }

    if (rewrite || ! self.userDefaults.uIpv6Enabled) {
        self.userDefaults.uIpv6Enabled = @(1);
    }

    if (rewrite || ! self.userDefaults.uUDPEnabled) {
        self.userDefaults.uUDPEnabled = @(0);
    }

    if (rewrite || ! self.userDefaults.uCurrentColorscheme) {
        self.userDefaults.uCurrentColorscheme = @(AppearanceManagerColorschemeRed);
    }
}

@end