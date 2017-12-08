//
//  ISStatusItemView.h
//  ClipboardClear
//
//  Created by Numeric on 12/7/17.
//  Copyright © 2017 Numeric. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ISStatusItemView : NSView
@property (nonatomic, strong) NSImage * _Nullable image;
@property (nonatomic, strong) NSImage * _Nullable alternateImage;
@property (nonatomic) BOOL clicked;
@property (nonatomic) SEL _Nullable action;
@property (nonatomic) SEL _Nullable rightAction;
@property (nonatomic, strong) id _Nullable target;

- (void)setHighlightState:(BOOL)state;

@end
