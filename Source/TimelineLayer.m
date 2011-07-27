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

#import "TimelineLayer.h"
#import "TimelineGridView.h"
#import "TimelineView.h"


@implementation TimelineLayer

@synthesize delegate=_delegate, 
			index=_index, 
			frameRange=_frameRange, 
			temporaryFrameOffset=_temporaryFrameOffset, 
			selectedFrames=_selectionIndexes, 
			frame=_frame;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithFrame:(NSRect)frame enclosingTimelineView:(TimelineGridView *)timelineView 
	index:(NSUInteger)index{
	if (self = [super init]){
		_frame = frame;
		_selectionIndexes = [[NSMutableIndexSet alloc] init];
		_enclosingTimelineView = timelineView;
		_index = index;
		_temporaryFrameOffset = NSNotFound;
	}
	return self;
}

- (void)dealloc{
	[_selectionIndexes release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)selectFrame:(NSUInteger)frame byExtendingSelection:(BOOL)byExtending{
	if (!byExtending){
		[_selectionIndexes removeAllIndexes];
	}
	[_selectionIndexes addIndex:frame];
}

- (void)deselectFrame:(NSUInteger)frame{
	[_selectionIndexes removeIndex:frame];
}

- (void)deselectAll{
	[_selectionIndexes removeAllIndexes];
}

- (BOOL)isFrameSelected:(NSUInteger)frame{
	return [_selectionIndexes containsIndex:frame];
}



#pragma mark -
#pragma mark NSView methods

- (void)drawInView:(NSView *)aView rect:(NSRect)dirtyRect{
	NSSize cellSize = (NSSize){_enclosingTimelineView.frameWidth, 
		_enclosingTimelineView.layerHeight};
	NSInteger location = _temporaryFrameOffset == NSNotFound 
		? _frameRange.location 
		: _temporaryFrameOffset;
	NSRect cellFrame = (NSRect){NSMinX(_frame) + (cellSize.width + 
			_enclosingTimelineView.frameSpacing) * location - 
			_enclosingTimelineView.frameSpacing, 
		NSMinY(_frame), cellSize};
	TimelineFrameCell *cell = [[TimelineFrameCell alloc] init];
	BOOL delegateRespondsToDrawCell = [_enclosingTimelineView.delegate 
		respondsToSelector:@selector(timeline:willDisplayCell:inLayer:frame:)];
		
	for (NSUInteger i = 0; i < _frameRange.length; i++){
		if (NSMaxX(cellFrame) < NSMinX(dirtyRect) || NSMinX(cellFrame) > NSMaxX(dirtyRect))
			goto increase;
	
		[cell setHighlighted:[_selectionIndexes containsIndex:i]];
		if (delegateRespondsToDrawCell){
			objc_msgSend(_enclosingTimelineView.delegate, 
				@selector(timeline:willDisplayCell:inLayer:frame:), _enclosingTimelineView, 
				cell, _index, i + _frameRange.location);
		}
		[cell drawWithFrame:cellFrame inView:aView];
		increase:
			cellFrame.origin.x += cellSize.width + _enclosingTimelineView.frameSpacing;
	}
	[cell release];
}
@end
