//
//  ISStatusItemView.m
//  ClipboardClear
//
//  Created by Numeric on 12/7/17.
//  Copyright © 2017 Numeric. All rights reserved.
//

#import "ISStatusItemView.h"

@implementation ISStatusItemView

@synthesize image = _image;
@synthesize alternateImage = _alternateImage;
@synthesize clicked = _clicked;
@synthesize action = _action;
@synthesize rightAction = _rightAction;
@synthesize target = _target;

- (void)setHighlightState:(BOOL)state{
    if(self.clicked != state){
        self.clicked = state;
        [self setNeedsDisplay:YES];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(darkModeChanged:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    }
    return self;
}

- (void)darkModeChanged:(id)sender {
//    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
//    id style = [dict objectForKey:@"AppleInterfaceStyle"];
//    BOOL darkModeOn = ( style && [style isKindOfClass:[NSString class]] && NSOrderedSame == [style caseInsensitiveCompare:@"dark"] );
//    NSLog(@"observed dark mode %d", darkModeOn);
    [self setNeedsDisplay:YES];
}

- (void)drawImage:(NSImage *)aImage centeredInRect:(NSRect)aRect{
    NSRect imageRect = NSMakeRect((CGFloat)round(aRect.size.width*0.5f-aImage.size.width*0.5f),
                                  (CGFloat)round(aRect.size.height*0.5f-aImage.size.height*0.5f),
                                  aImage.size.width,
                                  aImage.size.height);
    [aImage drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
}

- (BOOL)darkModeIsOn {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    id style = [dict objectForKey:@"AppleInterfaceStyle"];
    BOOL darkModeOn = ( style && [style isKindOfClass:[NSString class]] && NSOrderedSame == [style caseInsensitiveCompare:@"dark"] );
    return darkModeOn;
}

- (void)drawRect:(NSRect)rect{
    if(self.clicked){
        if (@available(macOS 10.14, *)) {
            [[NSColor controlAccentColor] set];
        } else {
            [[NSColor selectedMenuItemColor] set];
        }
        NSRectFill(rect);
    }
    if ([self darkModeIsOn] && self.alternateImage) {
        [self drawImage:self.alternateImage centeredInRect:rect];
    } else if (![self darkModeIsOn] && self.image) {
        [self drawImage:self.image centeredInRect:rect];
    }
}

- (void)mouseDown:(NSEvent *)theEvent{
    [super mouseDown:theEvent];
    [self setHighlightState:!self.clicked];
    if ([theEvent modifierFlags] & NSCommandKeyMask){
        [self.target performSelectorOnMainThread:self.rightAction withObject:nil waitUntilDone:NO];
    }else{
        [self.target performSelectorOnMainThread:self.action withObject:nil waitUntilDone:NO];
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent{
    [super rightMouseDown:theEvent];
    [self setHighlightState:!self.clicked];
    [self.target performSelectorOnMainThread:self.rightAction withObject:nil waitUntilDone:NO];
}

//- (void)dealloc{
//    self.target = nil;
//    self.action = nil;
//    self.rightAction = nil;
//}

@end

