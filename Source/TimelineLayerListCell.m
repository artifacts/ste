/*
 Copyright (c) 2010-2011, BILD digital GmbH & Co. KG
 All rights reserved.

 BSD License

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of BILD digital GmbH & Co. KG nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY BILD digital GmbH & Co. KG ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL BILD digital GmbH & Co. KG BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "TimelineLayerListCell.h"

@interface TimelineLayerListCell ()
- (NSRect)_imageRectForBounds:(NSRect)theRect;
@end


@implementation TimelineLayerListCell

@synthesize layerIsVisible=_layerIsVisible;
@synthesize representedObject=_representedObject;

+ (BOOL)prefersTrackingUntilMouseUp{
	return YES;
}

- (id)init{
	if (self = [super init]){
		[self setTextColor:[NSColor whiteColor]];
		[self setFont:[NSFont systemFontOfSize:11.0f]];
	}
	return self;
}

- (void) dealloc {
	[_representedObject release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone{
	TimelineLayerListCell *copy = (TimelineLayerListCell *)[super copyWithZone:zone];
	copy.layerIsVisible = _layerIsVisible;
	copy.representedObject = [_representedObject copy];
	return copy;
}

- (NSRect)drawingRectForBounds:(NSRect)theRect{
	// Get the parent's idea of where we should draw
	NSRect newRect = [super drawingRectForBounds:theRect];

	// When the text field is being 
	// edited or selected, we have to turn off the magic because it screws up 
	// the configuration of the field editor.  We sneak around this by 
	// intercepting selectWithFrame and editWithFrame and sneaking a 
	// reduced, centered rect in at the last minute.
	if (_isEditingOrSelecting == NO){
		// Get our ideal size for current text
		NSSize textSize = [self cellSizeForBounds:theRect];

		// Center that in the proposed rect
		float heightDelta = newRect.size.height - textSize.height;	
		if (heightDelta > 0){
			newRect.size.height -= heightDelta;
			newRect.origin.y += (heightDelta / 2);
		}
	}
	newRect.origin.x += 30.0f;
	newRect.size.width -= 30.0f;
	return newRect;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj 
	delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength{
	aRect = [self drawingRectForBounds:aRect];
	_isEditingOrSelecting = YES;	
	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart 
		length:selLength];
	_isEditingOrSelecting = NO;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj 
	delegate:(id)anObject event:(NSEvent *)theEvent{
	aRect = [self drawingRectForBounds:aRect];
	_isEditingOrSelecting = YES;
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
	_isEditingOrSelecting = NO;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	NSImage *img = [NSImage imageNamed:(_layerIsVisible  
		? @"layerlist-layer-on.png" 
		: @"layerlist-layer-off.png")];
	[img setFlipped:[controlView isFlipped]];
	[img drawInRect:[self _imageRectForBounds:cellFrame] fromRect:NSZeroRect 
		operation:NSCompositeSourceOver fraction:1.0f];
    [super drawWithFrame:cellFrame inView:controlView];
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView{
    NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];
	if (NSPointInRect(point, [self _imageRectForBounds:cellFrame])){
		return NSCellHitTrackableArea;
	}else if (NSPointInRect(point, [self drawingRectForBounds:cellFrame])){
		return NSCellHitEditableTextArea;
	}
	return NSCellHitContentArea;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp{
    NSPoint point = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
	if (!NSPointInRect(point, [self _imageRectForBounds:cellFrame])){
		return [super trackMouse:theEvent inRect:cellFrame ofView:controlView 
			untilMouseUp:untilMouseUp];
	}
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
		inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[pool release];
	}
	NSPoint locationInWindow = (theEvent!=nil)
		? [theEvent locationInWindow] 
		: NSZeroPoint;
	point = [controlView convertPoint:locationInWindow fromView:nil];
	if (NSPointInRect(point, [self _imageRectForBounds:cellFrame])){
		_layerIsVisible = !_layerIsVisible;
		[[self target] performSelector:[self action] withObject:self];
	}
	return YES;
}

- (NSRect)_imageRectForBounds:(NSRect)theRect{
	NSSize imgSize = (NSSize){11.0f, 11.0f};
	return (NSRect){NSMinX(theRect) + 12.0f, 
		NSMinY(theRect) + floorf((NSHeight(theRect) - imgSize.height) / 2.0f), 
		imgSize};
}
/*
- (NSDictionary *)_textAttributes{
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0f alpha:0.8f]];
	[shadow setShadowOffset:(NSSize){0.0f, -1.0f}];
	[shadow setShadowBlurRadius:2.0f];
	NSMutableDictionary *attributes = [[[NSMutableDictionary alloc] init] autorelease];
	[attributes addEntriesFromDictionary:[super _textAttributes]];
	[attributes setObject:shadow forKey:NSShadowAttributeName];
	[shadow release];
	return attributes;
}*/
@end
