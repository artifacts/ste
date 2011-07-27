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

#import "STEScrollView.h"

@interface STEScrollView ()
- (void)_initScrollers;
@end


@implementation STEScrollView

#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(NSRect)frameRect{
	if (self = [super initWithFrame:frameRect]){
		[self performSelector:@selector(_initScrollers) withObject:nil afterDelay:0.0f];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
	if (self = [super initWithCoder:aDecoder]){
		[self _initScrollers];
	}
	return self;
}



#pragma mark -
#pragma mark NSView methods

- (void)drawRect:(NSRect)dirtyRect{
	[super drawRect:dirtyRect];
	if (![self hasVerticalScroller] && ![self hasHorizontalScroller]) return;
	NSRect rect = (NSRect){NSWidth(self.frame) - 15.0f, NSHeight(self.frame) - 15.0f, 15.0f, 15.0f};
	NSImage *img = [NSImage imageNamed:@"scrollbar-placard-view.png"];
	[img setFlipped:[self isFlipped]];
	[img drawInRect:rect fromRect:NSZeroRect 
		operation:NSCompositeSourceOver fraction:1.0f];
}



#pragma mark -
#pragma mark Private methods

- (void)_initScrollers{
	NSRect rect = [[self horizontalScroller] frame];
	[self setHorizontalScroller:[[[STEScroller alloc] initWithFrame:rect] autorelease]];
	rect = [[self verticalScroller] frame];
	[self setVerticalScroller:[[[STEScroller alloc] initWithFrame:rect] autorelease]];
	[self reflectScrolledClipView:[self contentView]];
}
@end
