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

#import "TimelineScrubberView.h"

@interface TimelineScrubberView ()
- (void)_init;
- (void)_setKnobPosition:(CGFloat)newPosition notifyDelegate:(BOOL)notifyDelegate;
- (NSRect)_rectForKnobAtPosition:(CGFloat)position;
@end



@implementation TimelineScrubberView

@synthesize delegate=_delegate, 
			index=_index, 
			unitWidth=_unitWidth, 
			maxIndex=_maxIndex;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithFrame:(NSRect)frameRect{
	if (self = [super initWithFrame:frameRect]){
		[self _init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
	if (self = [super initWithCoder:aDecoder]){
		[self _init];
	}
	return self;
}

- (void)dealloc{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self 
		forKeyPath:@"values.STETimeScrubberShowsTimePreference"];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (CGFloat)knobPosition{
	return _index * _unitWidth + floorf(_unitWidth / 2.0f);
}

- (void)setKnobPosition:(CGFloat)position{
	[self _setKnobPosition:position notifyDelegate:NO];
}

- (void)setIndex:(NSUInteger)anIndex{
	[self _setKnobPosition:(_unitWidth * anIndex) notifyDelegate:NO];
}

- (void)setUnitWidth:(CGFloat)aWidth{
	_unitWidth = aWidth;
	[self setNeedsDisplay:YES];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

#pragma mark -
#pragma mark NSView methods

- (void)drawRect:(NSRect)aRect{
	[[NSImage imageNamed:@"scrubber-background.png"] drawInRect:aRect fromRect:NSZeroRect 
		operation:NSCompositeSourceOver fraction:1.0f];
	
	NSInteger i = 5;
	NSShadow *shadow = [[NSShadow alloc] init];
//	[shadow setShadowOffset:(NSSize){0.0f, -1.0f}];
//	[shadow setShadowBlurRadius:1.0f];
//	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0f alpha:0.5f]];
	NSDictionary *attribs = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.4 alpha:1.0], NSForegroundColorAttributeName, 
		[NSFont systemFontOfSize:9.0f], NSFontAttributeName, 
		nil];
		
	NSImage *scrubberScaleImg = [NSImage imageNamed:@"scrubber-scale.png"];
	CGFloat expectedLabelMaxWidth = 70.0f;
	
	for (CGFloat x = _unitWidth * 5.0f; x < NSWidth([self bounds]); x += _unitWidth * 5.0f){
		NSRect imgRect = (NSRect){x - 2.0f, 1.0f, [scrubberScaleImg size]};
		if (NSMaxX(imgRect) >= NSMinX(aRect) && NSMinX(imgRect) <= NSMaxX(aRect)){
			[scrubberScaleImg drawAtPoint:imgRect.origin 
				fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
		}
		if (i % 10 == 0){
			NSString *label;
			BOOL showsTime = [[[NSUserDefaults standardUserDefaults] 
				valueForKey:kSTETimeScrubberShowsTimePreference] boolValue];
			float fps = [[[NSUserDefaults standardUserDefaults] 
							   valueForKey:kSTEFramesPerSecond] floatValue];
			
			NSSize labelSize = (NSSize){expectedLabelMaxWidth, 0.0f};
			NSRect labelRect = (NSRect){x - floorf(labelSize.width / 2.0f) - 1.0f, 8.0f, labelSize};
			
			// sizeWithAttributes is pretty expensive so we check first by an approximation if we 
			// need this at all 
			if (NSMaxX(labelRect) >= NSMinX(aRect) && NSMinX(labelRect) <= NSMaxX(aRect)){
				if (showsTime){
					label = [NSString stringWithFormat:@"%0.1fs", i, (i / fps)];
				}else{
					label = [[NSNumber numberWithInt:i] stringValue];
				}
				NSSize labelSize = [label sizeWithAttributes:attribs];
				labelRect = (NSRect){x - floorf(labelSize.width / 2.0f) - 1.0f, 8.0f, labelSize};
				if (NSMaxX(labelRect) >= NSMinX(aRect) && NSMinX(labelRect) <= NSMaxX(aRect)){
					[label drawAtPoint:labelRect.origin withAttributes:attribs];
				}
			}
		}
		i += 5;
	}
	[shadow release];
	[attribs release];
	
	NSImage *knobImg = _isDragging 
		? [NSImage imageNamed:@"scrubber-knob-down.png"] 
		: [NSImage imageNamed:@"scrubber-knob-up.png"];
	NSRect knobRect = [self _rectForKnobAtPosition:self.knobPosition];
	[knobImg drawAtPoint:knobRect.origin fromRect:NSZeroRect operation:NSCompositeSourceOver 
		fraction:1.0f];
}

- (void)mouseDown:(NSEvent *)theEvent{
	if ([theEvent modifierFlags] & NSAlternateKeyMask){
		BOOL showsTime = [[[NSUserDefaults standardUserDefaults] 
			valueForKey:kSTETimeScrubberShowsTimePreference] boolValue];
		[[[NSUserDefaultsController sharedUserDefaultsController] defaults] 
			setValue:[NSNumber numberWithBool:!showsTime] 
			forKey:kSTETimeScrubberShowsTimePreference];
		[self setNeedsDisplay:YES];
		return;
	}

	[self performSelector:@selector(_beginScrubbing:) withObject:theEvent afterDelay:0.0];
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context{
	[self setNeedsDisplay:YES];
}



#pragma mark -
#pragma mark Private methods

- (void)_init{
	_knobSize = (NSSize){20.0f, 20.0f};
	_isDragging = NO;
	_unitWidth = 9.0f;
	_delegate = nil;
	_maxIndex = NSNotFound;
	[self _setKnobPosition:0.0f notifyDelegate:NO];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
		forKeyPath:@"values.STETimeScrubberShowsTimePreference" options:0 context:NULL];
}

- (void)_setKnobPosition:(CGFloat)newPosition notifyDelegate:(BOOL)notifyDelegate{
	CGFloat value = roundf(newPosition / _unitWidth);
	CGFloat maxValue = _maxIndex == NSNotFound 
		? roundf(NSWidth([self bounds]) / _unitWidth) 
		: (CGFloat)_maxIndex;
	value = MAX(value, 0);
	value = MIN(value, maxValue);
	if (value == _index)
		return;
	[self setNeedsDisplayInRect:[self _rectForKnobAtPosition:self.knobPosition]];
	_index = value;
	[self setNeedsDisplayInRect:[self _rectForKnobAtPosition:self.knobPosition]];
	if (notifyDelegate){
		[_delegate performSelector:@selector(scrubberDidChangeKnobPosition:) withObject:self];
	}
}

- (NSRect)_rectForKnobAtPosition:(CGFloat)position{
	NSImage *knobImg = [NSImage imageNamed:@"scrubber-knob-up.png"];
	NSPoint knobPos = (NSPoint){floorf(position - [knobImg size].width / 2.0f), 1.0f};
	knobPos.x = MAX(0, knobPos.x);
	knobPos.x = MIN(NSWidth([self bounds]) - [knobImg size].width, knobPos.x);
	return (NSRect){knobPos, [knobImg size]};
}

- (void)_beginScrubbing:(NSEvent *)theEvent{
	NSPoint startPoint = [self convertPoint:[theEvent locationInWindow] 
		fromView:nil];
	CGFloat formerKnobPosition = self.knobPosition;
	_isDragging = NSPointInRect(startPoint, (NSRect){formerKnobPosition - _knobSize.width / 2.0f, 
		0.0f, _knobSize.width, _knobSize.height});
	
	if (!_isDragging){
		[self _setKnobPosition:startPoint.x notifyDelegate:YES];
	}else{
		[self setNeedsDisplayInRect:[self _rectForKnobAtPosition:formerKnobPosition]];
	}
	
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;		
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
		inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
			fromView:nil]);
		
		if (!_isDragging){
			[self _setKnobPosition:point.x notifyDelegate:YES];
		}else{
			CGSize dragDist = (CGSize){point.x - startPoint.x, point.y - startPoint.y};
			[self _setKnobPosition:(formerKnobPosition + dragDist.width) notifyDelegate:YES];
		}
		[pool release];
	}
	
	if (_isDragging){
		_isDragging = NO;
		[self setNeedsDisplayInRect:[self _rectForKnobAtPosition:self.knobPosition]];
	}
}
@end
