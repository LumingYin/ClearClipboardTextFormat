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
@property (nonatomic) BOOL animating;
@property (nonatomic) BOOL leftRightSwapped;
@property (nonatomic, strong) NSMenu *rightClickMenu;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMenuItem *toggleLaunchItem;
@property (strong, nonatomic) NSMenuItem *quickClearItem;
@property (strong, nonatomic) ISStatusItemView *statusItemView;
@property (weak) IBOutlet NSWindow *toastWindow;
@property (weak) IBOutlet NSView *toastView;
@property (weak) IBOutlet NSTextField *toastMessageTextField;
@property (weak) IBOutlet NSVisualEffectView *toastBlurView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    [self.toastWindow setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
    self.leftRightSwapped = NO;

    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (standardUserDefaults && [standardUserDefaults objectForKey:@"leftRightSwapped"] != nil) {
        if ([[standardUserDefaults objectForKey:@"leftRightSwapped"] isEqualToValue:@YES]) {
            self.leftRightSwapped = YES;
        } else {
            self.leftRightSwapped = NO;
        }
    }

    self.statusItemView = [[ISStatusItemView alloc] init];
    self.statusItemView.image = [NSImage imageNamed:@"clipboard"];
    self.statusItemView.alternateImage = [NSImage imageNamed:@"clipboard_dark"];

    self.statusItemView.target = self;
    self.statusItemView.action = @selector(leftClick);
    self.statusItemView.rightAction = @selector(rightClick);
    
    self.rightClickMenu = [[NSMenu alloc] init];
    
    NSMenuItem *clearitem = [[NSMenuItem alloc] initWithTitle:@"Clear Clipboard Text Format" action:@selector(clearFormat:) keyEquivalent:@""];
    self.quickClearItem = [[NSMenuItem alloc] initWithTitle:@"Clear With Left Click" action:@selector(toggleLeftRightClick:) keyEquivalent:@""];
    [self.quickClearItem setState:self.leftRightSwapped];

    self.toggleLaunchItem = [[NSMenuItem alloc] initWithTitle:@"Launch at Login" action:@selector(toggleAutoLoginEnabledDisabled) keyEquivalent:@""];
    [self.toggleLaunchItem setState:[self launchOnLogin]];

    
    NSMenuItem *quititem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(quit) keyEquivalent:@""];
    [self.rightClickMenu addItem:clearitem];
    [self.rightClickMenu addItem:[NSMenuItem separatorItem]];

    [self.rightClickMenu addItem:self.toggleLaunchItem];
    [self.rightClickMenu addItem:self.quickClearItem];
    [self.rightClickMenu addItem:[NSMenuItem separatorItem]];

    [self.rightClickMenu addItem:quititem];
    
    [self.rightClickMenu setDelegate:self];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [self.statusItem setView:self.statusItemView];
}

- (BOOL)darkModeIsOn {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    id style = [dict objectForKey:@"AppleInterfaceStyle"];
    BOOL darkModeOn = ( style && [style isKindOfClass:[NSString class]] && NSOrderedSame == [style caseInsensitiveCompare:@"dark"] );
    return darkModeOn;
}

- (void)showToast:(NSString *)message {
    if ([self darkModeIsOn]) {
        [self.toastBlurView setMaterial:NSVisualEffectMaterialDark];
        [self.toastMessageTextField setTextColor:[NSColor whiteColor]];
    } else {
        if (@available(macOS 10.11, *)) {
            [self.toastBlurView setMaterial:NSVisualEffectMaterialMediumLight];
        } else {
            [self.toastBlurView setMaterial:NSVisualEffectMaterialLight];
        }
        [self.toastMessageTextField setTextColor:[NSColor blackColor]];
    }
    if (!self.animating) {
        self.animating = YES;
        NSRect frameRelativeToWindow = [self.statusItemView convertRect:self.statusItemView.bounds toView:nil];
        NSRect frameRelativeToScreen = [self.statusItemView.window convertRectToScreen:frameRelativeToWindow];
        
        NSRect windowRect = self.toastWindow.frame;
        windowRect.origin.x = frameRelativeToScreen.origin.x;
        windowRect.origin.y = frameRelativeToScreen.origin.y;
        [self.toastWindow setFrame:windowRect display:YES];
        
        [NSApp activateIgnoringOtherApps:YES];
        self.toastMessageTextField.stringValue = message;
        self.toastWindow.alphaValue = 0;
        [self.toastWindow setIsVisible:YES];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            context.duration = 0.2;
            [self.toastWindow animator].alphaValue = 1;
        } completionHandler:^{
            [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(nestedAnimation) userInfo:nil repeats:NO];
        }];
    }
}

- (void)nestedAnimation {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = 1;
        [self.toastWindow animator].alphaValue = 0;
    } completionHandler:^{
        [self.toastWindow setIsVisible:NO];
        self.animating = NO;
    }];
}

- (void)toggleLeftRightClick:(id)sender {
    self.leftRightSwapped = !self.leftRightSwapped;
    [self.quickClearItem setState:self.leftRightSwapped];

    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (standardUserDefaults) {
        [standardUserDefaults setObject:[NSNumber numberWithBool:self.leftRightSwapped] forKey:@"leftRightSwapped"];
        [standardUserDefaults synchronize];
    }

    if (self.leftRightSwapped) {
        [self showToast:@"Clear format with left click enabled. To access app menu and options, secondary click on the menu bar icon."];
    } else {
        [self showToast:@"Clear format with left click disabled. To access app menu and options, primary click on the menu bar icon."];
    }
}

- (void)leftClick {
    if (self.leftRightSwapped) {
        [self clearFormat:nil];
    } else {
        [self showMenu];
    }
}

- (void)rightClick {
    if (!self.leftRightSwapped) {
        [self clearFormat:nil];
    } else {
        [self showMenu];
    }
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
    }
    [self.statusItemView setHighlightState:NO];
}

- (void)menuDidClose:(NSMenu *)menu{
    [self.statusItemView setHighlightState:NO];
}

- (void)clearFormat:(id)sender {
    [self.statusItemView setHighlightState:NO];
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    if (copiedItems != nil) {
//        NSLog(@"%@", copiedItems);
        NSString *str = copiedItems[0];
        if (str != nil && [str isKindOfClass:[NSString class]]) {
            [pasteboard clearContents];
            [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            [pasteboard setString:str forType:NSStringPboardType];
        }
    }
}

- (void)quit {
    [NSApp terminate:nil];
}
@end
