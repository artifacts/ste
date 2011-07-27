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

#import "STEScroller.h"

enum{
	kSTEScrollerVariantSingle, 
	kSTEScrollerVariantDoubleMax
};


@interface STEScroller ()
- (BOOL)_isVertical;
- (NSImage *)_imageNamed:(NSString *)imgName;
- (NSInteger)_scrollbarVariant;
- (void)_drawSocketForArrow:(NSScrollerArrow)arrow highlight:(BOOL)flag;
@end


@implementation STEScroller

#pragma mark -
#pragma mark NSScroller methods

- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag{
	NSImage *img = [self _imageNamed:@"track"];
	[img setFlipped:[self isFlipped]];
	[img drawInRect:slotRect fromRect:NSZeroRect 
		operation:NSCompositeSourceOver fraction:1.0f];
}

- (void)drawKnob{
	NSRect rect = [self rectForPart:NSScrollerKnob];
	NSDrawThreePartImage(
		rect, 
		[self _imageNamed:@"knob-cap-left"], 
		[self _imageNamed:@"knob-middle"], 
		[self _imageNamed:@"knob-cap-right"], 
		[self _isVertical], 
		NSCompositeSourceOver, 
		1.0f, 
		[self isFlipped]);
}

- (void)drawArrow:(NSScrollerArrow)arrow highlight:(BOOL)flag{
	NSRect rect;
	NSString *direction;
	if (arrow == NSScrollerDecrementArrow){
		rect = [self rectForPart:NSScrollerDecrementLine];
		direction = @"left";
	}else{
		rect = [self rectForPart:NSScrollerIncrementLine];
		direction = @"right";
	}
	NSString *imageName = [NSString stringWithFormat:@"button-%@-%@-%@", 
		([self _scrollbarVariant] == kSTEScrollerVariantSingle ? @"single" : @"dblmax"), 
		direction, 
		(flag ? @"down" : @"up")];
	NSImage *img = [self _imageNamed:imageName];
	[img setFlipped:[self isFlipped]];
	[img drawInRect:rect fromRect:NSZeroRect 
		operation:NSCompositeSourceOver fraction:1.0f];
		
	[self _drawSocketForArrow:arrow highlight:flag];
}

- (void)drawRect:(NSRect)frame{
	// always draw slot
	[self drawKnobSlotInRect:[self rectForPart:NSScrollerKnobSlot] highlight:NO];
	
	// if the window is to small for the arrows and knob then return
	if ([self usableParts] == NSNoScrollerParts)
		return;

	NSScrollerPart hitPart = [self hitPart]; // hit parts are highlighted
	[self drawArrow:NSScrollerIncrementArrow highlight:(hitPart == NSScrollerIncrementLine)];
	[self drawArrow:NSScrollerDecrementArrow highlight:(hitPart == NSScrollerDecrementLine)];
	if ([self usableParts] == NSAllScrollerParts){
		[self drawKnob];
	}
}



#pragma mark -
#pragma mark Private methods

- (void)_drawSocketForArrow:(NSScrollerArrow)arrow highlight:(BOOL)flag{
	NSString *imgName = [NSString stringWithFormat:@"button-%@-%@-socket-%@", 
		([self _scrollbarVariant] == kSTEScrollerVariantSingle ? @"single" : @"dblmax"), 
		(arrow == NSScrollerIncrementArrow ? @"right" : @"left"), 
		(flag ? @"down" : @"up")];
	NSImage *img = [self _imageNamed:imgName];
	[img setFlipped:[self isFlipped]];
	
	if (!img) return;
	
	NSRect arrowRect = [self rectForPart:(arrow == NSScrollerIncrementArrow ? 
		NSScrollerIncrementLine : NSScrollerDecrementLine)];
	NSRect rect = (NSRect){NSZeroPoint, [img size]};
	
	if ([self _scrollbarVariant] == kSTEScrollerVariantSingle){
		if (arrow == NSScrollerDecrementArrow){ // left
			if ([self _isVertical]){
				rect.origin = (NSPoint){0.0f, NSMaxY(arrowRect) - 1.0f};
			}else{
				rect.origin = (NSPoint){NSMaxX(arrowRect) - 1.0f, 0.0f};
			}
		}else{ // right
			if ([self _isVertical]){
				rect.origin = (NSPoint){0.0f, NSMinY(arrowRect) - NSHeight(rect) + 1.0f};
			}else{
				rect.origin = (NSPoint){NSMinX(arrowRect) - NSWidth(rect) + 1.0f, 0.0f};
			}
		}
	}else{
		if (arrow == NSScrollerDecrementArrow){ // left
			if ([self _isVertical]){
				rect.origin = (NSPoint){0.0f, NSMinY(arrowRect) - NSHeight(rect)};
			}else{
				rect.origin = (NSPoint){NSMinX(arrowRect) - NSWidth(rect), 0.0f};
			}
		}else{ // right
			rect.origin = NSZeroPoint;
		}
	}
	[img drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
}

- (BOOL)_isVertical{
	return [self frame].size.width < [self frame].size.height;
}

- (NSImage *)_imageNamed:(NSString *)imgName{
	NSString *directionName = [self _isVertical] ? @"vertical" : @"horizontal";
	return [NSImage imageNamed:[NSString stringWithFormat:@"scrollbar-%@-%@.png", 
		directionName, imgName]];
}

- (NSInteger)_scrollbarVariant{
	NSString *setting = [[[NSUserDefaults standardUserDefaults] 
		persistentDomainForName:NSGlobalDomain] valueForKey:@"AppleScrollBarVariant"];
	if ([setting isEqualToString:@"Single"]){
		return kSTEScrollerVariantSingle;
	}
	return kSTEScrollerVariantDoubleMax;
}
@end
