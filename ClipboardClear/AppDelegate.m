//
//  AppDelegate.m
//  ClipboardClear
//
//  Created by Numeric on 12/7/17.
//  Copyright © 2017 Numeric. All rights reserved.
//

#import "AppDelegate.h"
#import "ISStatusItemView.h"
#import <ServiceManagement/ServiceManagement.h>

@interface AppDelegate ()
@property (nonatomic, strong) NSMenu *rightClickMenu;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMenuItem *toggleLaunchItem;
@property (strong, nonatomic) ISStatusItemView *statusItemView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    

    self.statusItemView = [[ISStatusItemView alloc] init];
    self.statusItemView.image = [NSImage imageNamed:@"clipboard"];
    self.statusItemView.target = self;
    self.statusItemView.action = @selector(clearFormat:);
    self.statusItemView.rightAction = @selector(showMenu);
    
    self.rightClickMenu = [[NSMenu alloc] init];
    NSMenuItem *clearitem = [[NSMenuItem alloc] initWithTitle:@"Clear Format" action:@selector(clearFormat:) keyEquivalent:@""];
    self.toggleLaunchItem = [[NSMenuItem alloc] initWithTitle:@"Launch at Login" action:@selector(toggleAutoLoginEnabledDisabled) keyEquivalent:@""];
    [self.toggleLaunchItem setState:[self launchOnLogin]];

    NSMenuItem *quititem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quit) keyEquivalent:@""];
    [self.rightClickMenu addItem:clearitem];
    [self.rightClickMenu addItem:self.toggleLaunchItem];
    [self.rightClickMenu addItem:quititem];
    [self.rightClickMenu setDelegate:self];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [self.statusItem setView:self.statusItemView];
}

- (void)toggleAutoLoginEnabledDisabled {
    if ([self launchOnLogin] == YES) {
        if (!SMLoginItemSetEnabled((__bridge CFStringRef)@"com.kay.ClipboardClear-Helper", NO)) {
            NSLog(@"Login Item Was Not Successfully disabled");
        } else {
            NSLog(@"Login Item Was Successfully disabled");
        }
        [self.toggleLaunchItem setState:[self launchOnLogin]];
    } else {
        if (!SMLoginItemSetEnabled((__bridge CFStringRef)@"com.kay.ClipboardClear-Helper", YES)) {
            NSLog(@"Login Item Was Not Successfully enabled");
        } else {
            NSLog(@"Login Item Was Successfully enabled");
        }
        [self.toggleLaunchItem setState:[self launchOnLogin]];
    }
}

- (BOOL)launchOnLogin
{
    NSArray *jobs = (__bridge NSArray *)SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    if (jobs == nil) {
        return NO;
    }
    
    if ([jobs count] == 0) {
        CFRelease((CFArrayRef)jobs);
        return NO;
    }
    
    BOOL onDemand = NO;
    for (NSDictionary *job in jobs) {
        if ([@"com.kay.ClipboardClear-Helper" isEqualToString:[job objectForKey:@"Label"]]) {
            onDemand = [[job objectForKey:@"OnDemand"] boolValue];
            break;
        }
    }
    
    CFRelease((CFArrayRef)jobs);
    return onDemand;
}


- (void)showMenu{
    if(self.statusItemView.clicked){
        [self.statusItem popUpStatusItemMenu:self.rightClickMenu];
        [self.statusItemView setHighlightState:NO];
    }
    [self.statusItemView setHighlightState:NO];
}

- (void)menuDidClose:(NSMenu *)menu{
    [self.statusItemView setHighlightState:NO];
}

- (void)clearFormat:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    if (copiedItems != nil) {
        NSLog(@"%@", copiedItems);
        NSString *str = copiedItems[0];
        if (str != nil && [str isKindOfClass:[NSString class]]) {
            [pasteboard clearContents];
            [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            [pasteboard setString:str forType:NSStringPboardType];
        }
    }
    [self.statusItemView setHighlightState:NO];
}

- (void)quit {
    [NSApp terminate:nil];
}
@end
