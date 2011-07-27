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

#import "TimelineGridView.h"
#import "TimelineView.h"
#import "SceneMO.h"
#import "BKColor.h"

@interface TimelineGridView ()
- (void)_init;
- (void)_createLayers;
- (void)_updateBounds;
- (NSIndexPath *)_indexPathAtPoint:(NSPoint)aPoint 
	allowOutOfBoundsFrameIndex:(BOOL)allowOutOfBoundsFrameIndex;
- (NSPoint)_pointForIndexPath:(NSIndexPath *)indexPath;
- (void)_updateScrollPositionIfNeeded;
- (void)_setPlayheadPosition:(NSUInteger)position notifyDelegate:(BOOL)notifyDelegate;
- (void)_deselectAll;
- (NSRect)_visibleLayersRect;
@end


const CGFloat kTimeScrubberHeight = 25.0f;

@implementation TimelineGridView

@synthesize dataSource=_dataSource, 
			delegate=_delegate, 
			layerHeight=_layerHeight, 
			frameWidth=_frameWidth, 
			layerSpacing=_layerSpacing, 
			frameSpacing=_frameSpacing, 
			timelineView=_timelineView, 
			allowsDraggingOfMultipleFrames=_allowsDraggingOfMultipleFrames, 
			isDraggingLayers=_isDraggingLayers, 
			isDraggingFrames=_isDraggingFrames, 
			draggedLayers=_draggedLayers, 
			enabled=_enabled,
			highlightedLayers=_highlightedLayers;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithFrame:(NSRect)aRect{
	if (self = [super initWithFrame:aRect]){
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
	[_layers release];
	[_outOfBoundsSelections release];
	[super dealloc];
}

#pragma mark -
#pragma mark Public methods

- (void)setDataSource:(id <NSObject,TimelineViewDataSource>)aDataSource{
	_dataSource = aDataSource;
	[self reloadData];
}

- (void)reloadData{
	[self _createLayers];
	
	_maxFrames = 0;
	for (TimelineLayer *layer in _layers){
		_maxFrames = MAX(_maxFrames, NSMaxRange(layer.frameRange));
	}
	_scrubberView.maxIndex = MAX(0, _maxFrames - 1);
	_maxFrames += 500;
	[self _updateBounds];
	[self setNeedsDisplay:YES];
}

- (void)selectFrameAtIndexPath:(NSIndexPath *)indexPath byExtendingSelection:(BOOL)byExtending{
	[self willChangeValueForKey:@"selectionIndexPaths"];
	if (!byExtending){
		[self _deselectAll];
	}
	TimelineLayer *layer = [_layers objectAtIndex:[indexPath layer]];
	[layer selectFrame:[indexPath frame] byExtendingSelection:byExtending];
	[self setNeedsDisplayInRect:[self _visibleLayersRect]];
	[self didChangeValueForKey:@"selectionIndexPaths"];
}

- (void)selectFramesInRect:(NSRect)aRect byExtendingSelection:(BOOL)byExtending{
	[self willChangeValueForKey:@"selectionIndexPaths"];
	if (!byExtending){
		[self _deselectAll];
	}
	
	NSRect bounds = [self bounds];
	bounds.size.height -= kTimeScrubberHeight;
	bounds.origin.y += kTimeScrubberHeight;
	
	aRect = NSIntersectionRect(bounds, aRect);
	NSIndexPath *startIndexPath = [self _indexPathAtPoint:aRect.origin 
		allowOutOfBoundsFrameIndex:YES];
	if (!startIndexPath){
		return;
	}
	
	NSUInteger row = [startIndexPath layer];
	NSUInteger col = [startIndexPath frame];
	NSPoint normalizedPoint = [self _pointForIndexPath:startIndexPath];
	NSSize offset = (NSSize){aRect.origin.x - normalizedPoint.x, 
		aRect.origin.y - normalizedPoint.y};
	aRect.size.width += offset.width;
	aRect.size.height += offset.height;
	NSUInteger numRows = (NSUInteger)ceilf(aRect.size.height / (_layerHeight + _layerSpacing));
	NSUInteger numCols = (NSUInteger)ceilf(aRect.size.width / (_frameWidth + _frameSpacing));
	NSUInteger maxRow = MIN([_layers count], row + numRows);
	NSUInteger maxCol = col + numCols;
	
	for (; row < maxRow; row++){
		for (col = [startIndexPath frame]; col < maxCol; col++){
			TimelineLayer *layer = [_layers objectAtIndex:row];
			NSUInteger localCol = col - layer.frameRange.location;
			if (NSLocationInRange(col, layer.frameRange)){
				[layer selectFrame:localCol byExtendingSelection:YES];
			}
		}
	}
	
	[self setNeedsDisplayInRect:[self _visibleLayersRect]];
	[self didChangeValueForKey:@"selectionIndexPaths"];
}

- (void)deselectAll{
	[self willChangeValueForKey:@"selectionIndexPaths"];
	[self _deselectAll];
	[self didChangeValueForKey:@"selectionIndexPaths"];
}

- (NSUInteger)playHeadPosition{
	return _scrubberView.index;
}

- (void)setPlayHeadPosition:(NSUInteger)position{
	[self _setPlayheadPosition:position notifyDelegate:NO];
}

- (NSArray *)selectionIndexPaths{
	NSMutableArray *selectedFrames = [NSMutableArray array];
	for (TimelineLayer *layer in _layers){
		NSIndexSet *selection = layer.selectedFrames;
		if (![selection count]) continue;
		NSUInteger frame = [layer.selectedFrames firstIndex];
		while (frame != NSNotFound){
			[selectedFrames addObject:[NSIndexPath 
				indexPathForFrame:(frame + layer.frameRange.location) 
				inLayer:layer.index]];
			frame = [selection indexGreaterThanIndex:frame];
		}
	}
	return [[selectedFrames copy] autorelease];
}

- (void)setSelectionIndexPaths:(NSArray *)indexPaths{
	[self willChangeValueForKey:@"selectionIndexPaths"];
	[self _deselectAll];
	for (NSIndexPath *indexPath in indexPaths){
		TimelineLayer *layer = [_layers objectAtIndex:[indexPath layer]];
		[layer selectFrame:([indexPath frame] - layer.frameRange.location) 
			byExtendingSelection:YES];
	}
	[self setNeedsDisplayInRect:[self _visibleLayersRect]];
	[self didChangeValueForKey:@"selectionIndexPaths"];
}

- (void)setHighlightedLayers:(NSIndexSet *)theLayerIndexes{
	[theLayerIndexes retain];
	[_highlightedLayers release];
	_highlightedLayers = theLayerIndexes;
	[self setNeedsDisplayInRect:[self _visibleLayersRect]];
}

- (void)setEnabled:(BOOL)value {
	_enabled = value;
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark NSView methods

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	// datasource cannot act on drag & drop, so we do nothing
	if (![_dataSource respondsToSelector:@selector(timeline:performLayerDropAtIndex:toFrameIndex:)])
		return nil;
	
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSIndexPath *clickedIndexPath = [self _indexPathAtPoint:point allowOutOfBoundsFrameIndex:NO];
	if (!clickedIndexPath){
		return nil;
	}
	NSUInteger idx = [clickedIndexPath layer];

	TimelineLayer *clickedLayer = [_layers objectAtIndex:idx];
	
	[[clickedLayer retain] autorelease];
	if (clickedLayer == nil) return nil;
	
	
	// create context menu
	NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Animation"] autorelease];
	[theMenu setAutoenablesItems:NO];
	NSMenuItem* menuItem;
	
	int loopValue = [_dataSource timeline:[self timelineView] loopValueForLayerAtIndex:idx];
	// group item
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Kein Loop" action:@selector(loopAction:) keyEquivalent:@""];
	[theMenu insertItem:menuItem atIndex:0];
	menuItem.tag = LoopNone;
	[menuItem setRepresentedObject:[NSNumber numberWithUnsignedInt:idx]];
	[menuItem setState:(loopValue == LoopNone)?NSOnState:NSOffState];
	
	
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Endlos" action:@selector(loopAction:) keyEquivalent:@""];
	[theMenu insertItem:menuItem atIndex:1];
	[menuItem setState:(loopValue == LoopEndless)?NSOnState:NSOffState];
	[menuItem setRepresentedObject:[NSNumber numberWithUnsignedInt:idx]];
	menuItem.tag = LoopEndless;
	
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Autoreverse" action:@selector(loopAction:) keyEquivalent:@""];
	[theMenu insertItem:menuItem atIndex:2];
	[menuItem setState:(loopValue == LoopPingPong)?NSOnState:NSOffState];
	[menuItem setRepresentedObject:[NSNumber numberWithUnsignedInt:idx]];
	menuItem.tag = LoopPingPong;
	
	[menuItem release];	
	
	return theMenu;
}

- (IBAction)loopAction:(id)sender {
	NSMenuItem *menuItem = sender;
	NSUInteger index = [(NSNumber*)menuItem.representedObject unsignedIntValue];
	NSUInteger loopValue = menuItem.tag;
	[_delegate timeline:[self timelineView] didChangeLoopValue:loopValue forLayerAtIndex:index];
}

- (void)updateTrackingAreas{
	[_trackingArea release];
	NSTrackingAreaOptions trackingOptions = NSTrackingCursorUpdate | 
	NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited |
	NSTrackingActiveInActiveApp | NSTrackingMouseMoved;
	_trackingArea = [[NSTrackingArea alloc]
					  initWithRect:[self bounds] options:trackingOptions owner:self userInfo:nil];
	[self addTrackingArea:_trackingArea];
}

- (BOOL)isFlipped{
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect{
	CGRect rect = NSRectToCGRect(dirtyRect);
	
	CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(ctx);
	
	// draw background
	CGColorRef bgColor = CGColorCreateGenericGray(0.95, 1.0f);
	CGColorRef lineColor = CGColorCreateGenericGray(0.93, 1.0f);
	CGContextSetFillColorWithColor(ctx, bgColor);
	CGContextFillRect(ctx, rect);
	
	if (_enabled == NO) {		
		CGColorRelease(bgColor);
		CGColorRelease(lineColor);
		CGContextRestoreGState(ctx);		
		return;
	}
	
	// draw vertical lines
	CGFloat x = ceilf(CGRectGetMinX(rect) / (_frameWidth + _frameSpacing)) * 
		(_frameWidth + _frameSpacing) - (_frameSpacing / 2.0f);
	CGContextSetStrokeColorWithColor(ctx, lineColor);
	CGContextBeginPath(ctx);
	CGContextMoveToPoint(ctx, x, CGRectGetMinY(rect));
	while (x < CGRectGetMaxX(rect)){
		CGContextAddLineToPoint(ctx, x, CGRectGetMaxY(rect));
		x += _frameWidth + _frameSpacing;
		CGContextMoveToPoint(ctx, x, CGRectGetMinY(rect));
	}
	CGContextStrokePath(ctx);
	
	// draw horizontal lines
	CGFloat y = kTimeScrubberHeight - 0.5f;
	CGContextBeginPath(ctx);
	for (NSInteger i = 0; i <= [_layers count]; i++){
		if (y + 1.0f >= NSMinY(dirtyRect)){
			CGContextMoveToPoint(ctx, CGRectGetMinX(rect), y);
			CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), y);
		}
		y += _layerHeight + _layerSpacing;
	}
	CGContextStrokePath(ctx);
	
	CGColorRelease(bgColor);
	CGColorRelease(lineColor);
	CGContextRestoreGState(ctx);
	
	// draw layers
	for (TimelineLayer *layer in _layers){
		if (NSMaxY(layer.frame) >= NSMinY(dirtyRect) && NSMinY(layer.frame) <= NSMaxY(dirtyRect))
			[layer drawInView:self rect:dirtyRect];
	}
	
	// draw currently dragged frames' borders
	CGContextSaveGState(ctx);
	x = floorf(_scrubberView.knobPosition) - 0.5f;
	lineColor = CGColorCreateGenericRGB(1.000, 0.482, 0.169, 1.0);
	CGContextSetStrokeColorWithColor(ctx, lineColor);
	CGContextSetLineWidth(ctx, 2.0f);
	
	CGRect currentRect;
	NSIndexPath *lastIndexPath = nil;
	for (NSIndexPath *indexPath in _dropTargetIndexSets){
		// coalesce frame borders into bigger rectangles
		if (lastIndexPath && ([lastIndexPath layer] == [indexPath layer] && 
			[lastIndexPath frame] + 1 == [indexPath frame])){
			currentRect.size.width += _frameWidth + 1.0f;
		}else{
			if (lastIndexPath != nil){
				CGContextStrokeRect(ctx, currentRect);
			}
			NSPoint origin = [self _pointForIndexPath:indexPath];
			currentRect = (CGRect){origin.x + 1.0f, origin.y + 1.0f, _frameWidth, 
				_layerHeight - 2.0f};
		}
		lastIndexPath = indexPath;
	}
	if (lastIndexPath){
		CGContextStrokeRect(ctx, currentRect);
	}
	
	// draw out-of-bounds selections
	CGColorRef fillColor = CGColorCreateGenericRGB(0.365f, 0.408f, 0.443f, 1.0f);
	CGContextSetFillColorWithColor(ctx, fillColor);
	for (NSIndexPath *indexPath in _outOfBoundsSelections){
		CGContextFillRect(ctx, (CGRect){NSPointToCGPoint([self _pointForIndexPath:indexPath]), 
			_frameWidth, _layerHeight});
	}
	
	// draw highlighted rows
	if (_highlightedLayers){
		NSInteger index = [_highlightedLayers firstIndex];

		[[[NSColor selectedControlColor] colorWithAlphaComponent: 0.4] setFill];

		while (index != NSNotFound){
			CGFloat y = kTimeScrubberHeight + index * _layerHeight;
			if (index > 0) y += (index - 1) * _layerSpacing;
			CGContextFillRect(ctx, (CGRect){CGRectGetMinX(rect), y, 
				CGRectGetWidth(rect), _layerHeight + _layerSpacing * 2.0f});
			index = [_highlightedLayers indexGreaterThanIndex:index];
		}
	}
	
	// draw selection rect
	if (!NSIsEmptyRect(_selectionRect)){
		CGRect rect = NSRectToCGRect(_selectionRect);
		rect.origin.x -= .5f;
		rect.origin.y -= .5f;
		CGColorRef selectionBorderColor = CGColorCreateGenericRGB(0.31f, 0.5f, 1.0f, 1.0f);
		CGColorRef selectionFillColor = CGColorCreateGenericRGB(0.31f, 0.5f, 1.0f, 0.2f);
		CGContextSetFillColorWithColor(ctx, selectionFillColor);
		CGContextSetStrokeColorWithColor(ctx, selectionBorderColor);
		CGContextSetLineWidth(ctx, 1.0f);
		CGContextBeginPath(ctx);
		CGContextAddRect(ctx, rect);
		CGContextDrawPath(ctx, kCGPathFillStroke);
		CGColorRelease(selectionBorderColor);
		CGColorRelease(selectionFillColor);
	}

	// draw playhead position
	CGContextBeginPath(ctx);
	CGContextSetStrokeColorWithColor(ctx, lineColor);
	CGContextSetLineWidth(ctx, 1.0f);
	CGContextMoveToPoint(ctx, x, CGRectGetMinY(rect));
	CGContextAddLineToPoint(ctx, x, CGRectGetMaxY(rect));
	CGContextStrokePath(ctx);
	
	CGColorRelease(lineColor);
	CGColorRelease(fillColor);
	
	CGContextRestoreGState(ctx);
}

- (void)mouseDown:(NSEvent *)theEvent{
	if (_enabled == NO) return;
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	[_outOfBoundsSelections removeAllObjects];
	
	if (![self isFlipped]){
		point.y = NSHeight(self.bounds) - point.y;
	}
	
	NSIndexPath *indexPath = [self _indexPathAtPoint:point allowOutOfBoundsFrameIndex:YES];
	
	if (!indexPath){
		if (!([NSEvent modifierFlags] & NSCommandKeyMask))
			[self deselectAll];
		return;
	}
	
	if ([theEvent clickCount] == 2){
		SEL selector = @selector(timeline:didDoubleClickFrame:inLayer:);
		if ([_delegate respondsToSelector:selector]){
			objc_msgSend(_delegate, selector, _timelineView, [indexPath frame], [indexPath layer]);
			[_outOfBoundsSelections removeAllObjects];
		}
		return;
	}
	
	TimelineLayer *layer = [_layers objectAtIndex:[indexPath layer]];
	NSUInteger clickedFrame = [indexPath frame];
	
	// start rectangular selection
	if ([theEvent modifierFlags] & NSAlternateKeyMask){
		[self deselectAll];
	// click in nirvana, but on an existing layer
	}else if (!NSLocationInRange(clickedFrame, layer.frameRange)){
		if (!([NSEvent modifierFlags] & NSCommandKeyMask)){
			[self deselectAll];
		}
		[_outOfBoundsSelections addObject:indexPath];
		[self setNeedsDisplayInRect:[self _visibleLayersRect]];
		return;
	}else if (_spaceKeyDown){
		// if spacebar is pressed, the user wants to drag the complete layer
		// in this case we deselect all frames
		[self deselectAll];
	}else if ([theEvent modifierFlags] & NSShiftKeyMask){
		NSIndexPath *startIndexPath = nil;
		NSInteger i = 0;
		// find top left selected frame (nearest)
		for (TimelineLayer *layer in _layers){
			if ([layer.selectedFrames count] > 0){
				startIndexPath = [NSIndexPath indexPathForFrame:([layer.selectedFrames firstIndex] + 
					layer.frameRange.location) inLayer:i];
				break;
			}
			i++;
		}
		// clicked frame is lower, so find bottom right frame (farthest)
		if (startIndexPath != nil && [indexPath layer] <= [startIndexPath layer] && 
			[indexPath frame] < [startIndexPath frame]){
			for (i = [_layers count] - 1; i >= 0; i--){
				TimelineLayer *layer = [_layers objectAtIndex:i];
				if ([layer.selectedFrames count] > 0){
					startIndexPath = [NSIndexPath indexPathForFrame:([layer.selectedFrames lastIndex] + 
						layer.frameRange.location) inLayer:i];
					break;
				}
			}
		}
		// no selected frame found, find first frame
		if (!startIndexPath){
			i = 0;
			for (TimelineLayer *layer in _layers){
				if (layer.frameRange.length > 0){ // a layer actually must have frames, doesn't it?
					startIndexPath = [NSIndexPath indexPathForFrame:layer.frameRange.location 
						inLayer:i];
					break;
				}
				i++;
			}
		}
		// no frame found to relate to, bail out
		if (!startIndexPath){
			return;
		}
		NSIndexPath *lowerIndexPath = nil;
		NSIndexPath *higherIndexPath = nil;
		// the clicked frame is lower than the frame we've found (eg. the first selected frame)
		if ([indexPath layer] <= [startIndexPath layer] && [indexPath frame] < [startIndexPath frame]){
			lowerIndexPath = indexPath;
			higherIndexPath = startIndexPath;
		}else if ([indexPath layer] >= [startIndexPath layer] && 
			[indexPath frame] > [startIndexPath frame]){
			lowerIndexPath = startIndexPath;
			higherIndexPath = indexPath;
		}else{
			// the user might have clicked the same frame in the same layer, so we do nothing
			return;
		}
		
		NSPoint lowerPoint = [self _pointForIndexPath:lowerIndexPath];
		NSPoint higherPoint = [self _pointForIndexPath:
			[NSIndexPath indexPathForFrame:([higherIndexPath frame] + 1) 
				inLayer:([higherIndexPath layer] + 1)]];
		NSRect rect = (NSRect){lowerPoint, higherPoint.x - lowerPoint.x, 
			higherPoint.y - lowerPoint.y};
		[self selectFramesInRect:rect byExtendingSelection:NO];
		return;
	}else{
		[self _setPlayheadPosition:clickedFrame notifyDelegate:YES];
		clickedFrame -= layer.frameRange.location;
		BOOL isFrameSelected = [layer isFrameSelected:clickedFrame];
		BOOL earlyReturn = NO;
		
		[self willChangeValueForKey:@"selectionIndexPaths"];
		if ([NSEvent modifierFlags] & NSCommandKeyMask){
			if (!isFrameSelected){
				[layer selectFrame:clickedFrame byExtendingSelection:YES];
			}else{
				[layer deselectFrame:clickedFrame];
			}
			[self setNeedsDisplayInRect:[self _visibleLayersRect]];
			earlyReturn = YES;
		}else{
			// before we rush and change the selection, let's just wait if the user
			// will drag or not
		}
		[self didChangeValueForKey:@"selectionIndexPaths"];
		if( earlyReturn ) {
			return;
		}
	}
	
	[self setNeedsDisplayInRect:[self _visibleLayersRect]];
	
	if (_spaceKeyDown){
		[self performSelector:@selector(_performLayerDragging:) withObject:theEvent afterDelay:0.0];
	}else if ([theEvent modifierFlags] & NSAlternateKeyMask){
		[self performSelector:@selector(_performRectangularSelection:) withObject:theEvent 
			afterDelay:0.0];
	}else{
		[self performSelector:@selector(_performFrameDragging:) withObject:theEvent afterDelay:0.0];
	}
}

- (void)keyDown:(NSEvent *)theEvent{
	if ([theEvent keyCode] == 51){ // backspace
		if ([_delegate respondsToSelector:@selector(timeline:shouldDeleteFramesWithIndexPaths:)]){
			if ([_delegate timeline:_timelineView 
					shouldDeleteFramesWithIndexPaths:self.selectionIndexPaths]){
				[self willChangeValueForKey:@"selectionIndexPaths"];
				[self didChangeValueForKey:@"selectionIndexPaths"];
				return;
			}
		}
	}else if ([theEvent keyCode] == 49){ // space
		_spaceKeyDown = YES;
		[[NSCursor openHandCursor] set];
		return;
	}
	
	[self interpretKeyEvents: [NSArray arrayWithObject: theEvent]];
	//[super keyDown: theEvent];
	//[[self nextResponder] tryToPerform: cmd with: theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent{
	if (_spaceKeyDown)
		return;
	if ([theEvent modifierFlags] & NSAlternateKeyMask){
		[[NSCursor crosshairCursor] set];
	}else{
		[[NSCursor arrowCursor] set];
	}
}

- (void)keyUp:(NSEvent *)theEvent{
	if ([theEvent keyCode] == 49){
		_spaceKeyDown = NO;
		[[NSCursor arrowCursor] set];
	}
	[super keyUp:theEvent];
}

- (void)mouseEntered:(NSEvent *)theEvent{
	[[self window] makeFirstResponder:self];
}

- (void)mouseExited:(NSEvent *)theEvent{
	[[NSCursor arrowCursor] set];
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidMoveToSuperview{
	if (![self enclosingScrollView])
		return;
	[self updateTrackingAreas];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewDidChange:) 
		name:NSViewFrameDidChangeNotification object:[self enclosingScrollView]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewDidScroll:) 
		name:NSViewBoundsDidChangeNotification object:[[self enclosingScrollView] contentView]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) 
		name:NSWindowDidResignKeyNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) 
		name:NSWindowDidBecomeKeyNotification object:[self window]];
}

- (BOOL)canBecomeKeyView{
	return YES;
}

- (BOOL)acceptsFirstResponder{
	return YES;
}

- (BOOL)becomeFirstResponder{
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)resignFirstResponder{
	[self setNeedsDisplay:YES];
	return YES;
}



#pragma mark -
#pragma mark Private methods

- (void)_init{
	_enabled = YES;
	_layerHeight = 18.0f;
	_frameWidth = 9.0f;
	_layerSpacing = 1.0f;
	_frameSpacing = 1.0f;
	_layers = nil;
//#ifdef MULTIPLE_FRAME_DRAG
	_allowsDraggingOfMultipleFrames = YES;
//#else
//	_allowsDraggingOfMultipleFrames = NO;
//#endif
	_dropTargetIndexSets = nil;
	_outOfBoundsSelections = [[NSMutableArray alloc] init];
	_isDraggingLayers = NO;
	_isDraggingFrames = NO;
	_draggedLayers = nil;
	_selectionRect = NSZeroRect;
	_trackingArea = nil;
	
	_scrubberView = [[TimelineScrubberView alloc] initWithFrame:(NSRect){
		NSZeroPoint, NSWidth([self bounds]), kTimeScrubberHeight}];
	_scrubberView.unitWidth = _frameWidth + _frameSpacing;
	_scrubberView.delegate = self;
	[self addSubview:_scrubberView];
	[_scrubberView release];
	
	[self updateTrackingAreas];
}

- (void)_createLayers{
	[_layers release];
	
	NSMutableArray *layers = [[NSMutableArray alloc] init];
	NSUInteger numLayers = [_dataSource numberOfLayersInTimeline:_timelineView];
	
	CGFloat y = kTimeScrubberHeight;
	for (NSUInteger i = 0; i < numLayers; i++){
		NSUInteger numFrames = [_dataSource timeline:_timelineView 
			numberOfFramesInLayerWithIndex:i];
		NSUInteger startIndex = [_dataSource timeline:_timelineView 
			firstFrameIndexInLayerWithIndex:i];
		NSRect frame = (NSRect){0.0f, y, 
			numFrames * (_frameWidth + _frameSpacing) - _frameSpacing, _layerHeight};
		TimelineLayer *layer = [[TimelineLayer alloc] initWithFrame:frame 
			enclosingTimelineView:self index:i];
		layer.frameRange = (NSRange){startIndex, numFrames};
		[layers addObject:layer];
		[layer release];
		y += _layerHeight + _layerSpacing;
	}
	_layers = [layers copy];
	[layers release];
}

- (void)_updateBounds{
	CGFloat width = MAX(_maxFrames * (_frameWidth + _frameSpacing) - _frameSpacing, 
		[[self enclosingScrollView] contentSize].width);
	CGFloat height = MAX([_layers count] * (_layerHeight + _layerSpacing) - _layerSpacing + 
		kTimeScrubberHeight, [[self enclosingScrollView] contentSize].height);
	NSRect frame = [self frame];
	frame.size.width = width;
	frame.size.height = height;
	[self setFrame:frame];
	
	frame.size.height = kTimeScrubberHeight;
	frame.origin.y = NSMinY([[[self enclosingScrollView] contentView] documentVisibleRect]);
	[_scrubberView setFrame:frame];
}

- (NSIndexPath *)_indexPathAtPoint:(NSPoint)aPoint 
	allowOutOfBoundsFrameIndex:(BOOL)allowOutOfBoundsFrameIndex{
	NSUInteger clickedLayer = (NSUInteger)floorf((aPoint.y - kTimeScrubberHeight) / 
		(CGFloat)(_layerHeight + _layerSpacing));
	if ([_layers count] <= clickedLayer){
		return nil;
	}
	
	NSUInteger clickedFrame = (NSUInteger)floorf(aPoint.x / (CGFloat)(_frameWidth + _frameSpacing));
	TimelineLayer *layer = [_layers objectAtIndex:clickedLayer];
	if (!allowOutOfBoundsFrameIndex && !NSLocationInRange(clickedFrame, layer.frameRange)){
		return nil;
	}
	
	return [NSIndexPath indexPathForFrame:clickedFrame inLayer:clickedLayer];
}

- (NSPoint)_pointForIndexPath:(NSIndexPath *)indexPath{
	return (NSPoint){[indexPath frame] * (_frameWidth + _frameSpacing), 
		[indexPath layer] * (_layerHeight + _layerSpacing) + kTimeScrubberHeight};
}

- (void)_performFrameDragging:(NSEvent *)theEvent{
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSIndexPath *clickedIndexPath = [self _indexPathAtPoint:point allowOutOfBoundsFrameIndex:NO];
	
	if (!clickedIndexPath){
		return;
	}
	
	TimelineLayer *layer = [_layers objectAtIndex:[clickedIndexPath layer]];
	NSIndexPath *relativeIndexPath = [NSIndexPath 
		indexPathForFrame:[clickedIndexPath frame] - layer.frameRange.location 
		inLayer:[clickedIndexPath layer]];
	
	if ([[[NSApplication sharedApplication] currentEvent] type] == NSLeftMouseUp){
		[self selectFrameAtIndexPath:relativeIndexPath byExtendingSelection:NO];
		return;
	}
	
	// datasource cannot act on drag & drop, so we just select the clicked frame
	if (![_dataSource respondsToSelector:@selector(timeline:performFrameDrop:sourcePosition:)]){
		[self selectFrameAtIndexPath:relativeIndexPath byExtendingSelection:NO];
		return;
	}
	
	TimelineLayer *clickedLayer = [_layers objectAtIndex:[clickedIndexPath layer]];
	// dragged frame must be selected, otherwise we don't start dragging
	if (![clickedLayer.selectedFrames containsIndex:[clickedIndexPath frame] - 
		clickedLayer.frameRange.location]){
		[self selectFrameAtIndexPath:relativeIndexPath byExtendingSelection:NO];
		return;
	}
	
	NSMutableArray *selectedFrames = [[NSMutableArray alloc] init];
	if (!_allowsDraggingOfMultipleFrames){
		[selectedFrames addObject:clickedIndexPath];
	}else{
		[selectedFrames addObjectsFromArray:self.selectionIndexPaths];
	}
	
	if ([_delegate respondsToSelector:@selector(timeline:draggableFramesAtIndexPaths:)]){
		NSArray *draggableFrames = [_delegate timeline:_timelineView 
			draggableFramesAtIndexPaths:selectedFrames];
		// the delegate doesn't want us to drag
		if (draggableFrames == nil || [draggableFrames count] == 0){
			[self selectFrameAtIndexPath:relativeIndexPath byExtendingSelection:NO];
			goto bailout;
		}
		[self deselectAll];
		for (NSIndexPath *indexPath in draggableFrames){
			TimelineLayer *theLayer = [_layers objectAtIndex:[indexPath layer]];
			NSIndexPath *theIndexPath = [NSIndexPath 
				indexPathForFrame:[indexPath frame] - theLayer.frameRange.location 
				inLayer:[indexPath layer]];
			[self selectFrameAtIndexPath:theIndexPath byExtendingSelection:YES];
		}
		[selectedFrames release];
		selectedFrames = [draggableFrames mutableCopy];
	}
	
	_isDraggingFrames = YES;
	
	NSPoint startPoint = point;
	NSInteger offsetFrames = 0; 
	NSInteger offsetLayers = 0;
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
		inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		NSSize offset = (NSSize){point.x - startPoint.x, point.y - startPoint.y};
		offsetFrames = (NSInteger)roundf(offset.width / (_frameWidth + _frameSpacing));
		offsetLayers = (NSInteger)roundf(offset.height / (_layerHeight + _layerSpacing));
		
		NSMutableArray *dropTargetIndexSets = [NSMutableArray array];
		for (NSIndexPath *indexPath in selectedFrames){
			NSInteger dropFrame = [indexPath frame] + offsetFrames;
			NSInteger dropLayer = [indexPath layer] + offsetLayers;
			if (dropFrame < 0) dropFrame = 0;
			if (dropLayer < 0) dropLayer = 0;
			
			NSIndexPath *dropIndexPath = [NSIndexPath indexPathForFrame:dropFrame 
				inLayer:dropLayer];
			if ([_delegate respondsToSelector:
				@selector(timeline:validateFrameDropPosition:frameSourcePosition:)]){
				dropIndexPath = [_delegate timeline:_timelineView 
					validateFrameDropPosition:dropIndexPath frameSourcePosition:indexPath];
			}
			[dropTargetIndexSets addObject:dropIndexPath];
		}
		[_dropTargetIndexSets release];
		_dropTargetIndexSets = [dropTargetIndexSets copy];
		[self _updateScrollPositionIfNeeded];
		[self setNeedsDisplayInRect:[self _visibleLayersRect]];
		
		[pool release];
	}
	
	_isDraggingFrames = NO;

	// user didn't drag far enough, so we interpret this action as a click	
	if (offsetLayers == 0 && offsetFrames == 0){
		[self selectFrameAtIndexPath:relativeIndexPath byExtendingSelection:NO];
		[_dropTargetIndexSets release];
		_dropTargetIndexSets = nil;
		[self setNeedsDisplayInRect:[self _visibleLayersRect]];
		goto bailout;
	}
	
	NSEnumerator *selectedFramesEnum = [selectedFrames objectEnumerator];
	NSEnumerator *dropTargetIndexSetsEnum = [_dropTargetIndexSets objectEnumerator];
	if (offsetFrames > 0){
		selectedFramesEnum = [selectedFrames reverseObjectEnumerator];
		dropTargetIndexSetsEnum = [_dropTargetIndexSets reverseObjectEnumerator];
	}
	
	NSIndexPath *sourcePosition;
	while (sourcePosition = [selectedFramesEnum nextObject]){
		NSIndexPath *targetPosition = [dropTargetIndexSetsEnum nextObject];
		[_dataSource timeline:_timelineView performFrameDrop:targetPosition 
			sourcePosition:sourcePosition];
	}
	
	[self reloadData];
	
	// just to be sure
	[self willChangeValueForKey:@"selectionIndexPaths"];
	[self didChangeValueForKey:@"selectionIndexPaths"];
	
bailout:
	[selectedFrames release];
	[_dropTargetIndexSets release];
	_dropTargetIndexSets = nil;
}

- (void)_performLayerDragging:(NSEvent *)theEvent{
	if ([[[NSApplication sharedApplication] currentEvent] type] == NSLeftMouseUp){
		return;
	}

	// datasource cannot act on drag & drop, so we do nothing
	if (![_dataSource respondsToSelector:@selector(timeline:performLayerDropAtIndex:toFrameIndex:)])
		return;

	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSIndexPath *clickedIndexPath = [self _indexPathAtPoint:point allowOutOfBoundsFrameIndex:NO];
	if (!clickedIndexPath){
		return;
	}
	
	TimelineLayer *clickedLayer = [_layers objectAtIndex:[clickedIndexPath layer]];
	[[clickedLayer retain] autorelease];
	NSRange formerFrameRange = clickedLayer.frameRange;
	
	// the delegate prevented dragging
	if ([_delegate respondsToSelector:@selector(timeline:canDragLayerAtIndex:)]){
		if (![_delegate timeline:_timelineView canDragLayerAtIndex:[clickedIndexPath layer]])
			return;
	}
	
	_isDraggingLayers = YES;
	[[NSCursor closedHandCursor] set];
	_draggedLayers = [[NSSet alloc] initWithObjects:
		[NSNumber numberWithInt:[clickedIndexPath layer]], nil];
	
	NSPoint startPoint = point;
	NSInteger offsetFrames = 0; 
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;
	NSInteger location = formerFrameRange.location;
	
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
		inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		NSSize offset = (NSSize){point.x - startPoint.x, point.y - startPoint.y};
		offsetFrames = (NSInteger)roundf(offset.width / (_frameWidth + _frameSpacing));
		
		//location = formerFrameRange.location;
		location = MAX(0, (NSInteger)(formerFrameRange.location + offsetFrames));
		location = MIN(_maxFrames - formerFrameRange.length, location);
		clickedLayer.temporaryFrameOffset = location;
		
		[self _updateScrollPositionIfNeeded];
		[self setNeedsDisplayInRect:[self _visibleLayersRect]];
		
		[pool release];
	}
	
	_isDraggingLayers = NO;
	[_draggedLayers release];
	_draggedLayers = nil;
	
	[_dataSource timeline:_timelineView performLayerDropAtIndex:[clickedIndexPath layer] 
		toFrameIndex:location];
	clickedLayer.temporaryFrameOffset = NSNotFound;
	[self setNeedsDisplayInRect:[self _visibleLayersRect]];
	
	// just to be sure
	[self willChangeValueForKey:@"selectionIndexPaths"];
	[self didChangeValueForKey:@"selectionIndexPaths"];
}

- (void)_performRectangularSelection:(NSEvent *)theEvent{
	if ([[[NSApplication sharedApplication] currentEvent] type] == NSLeftMouseUp){
		return;
	}
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	NSPoint startPoint = point;
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
		inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSSize offset = (NSSize){point.x - startPoint.x, point.y - startPoint.y};
		
		_selectionRect = (NSRect){startPoint, offset};
		if (_selectionRect.size.width < 0.0f){
			_selectionRect.origin.x += _selectionRect.size.width;
			_selectionRect.size.width *= -1.0f;
		}
		if (_selectionRect.size.height < 0.0f){
			_selectionRect.origin.y += _selectionRect.size.height;
			_selectionRect.size.height *= -1.0f;
		}
		
		[self _updateScrollPositionIfNeeded];
		[self selectFramesInRect:_selectionRect byExtendingSelection:NO];
		[self setNeedsDisplay:YES];
		[pool release];
	}
	
	[self setNeedsDisplay:YES];
	_selectionRect = NSZeroRect;
}

- (void)_updateScrollPositionIfNeeded{
	NSEvent *theEvent = [[NSApplication sharedApplication] currentEvent];
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	[self scrollRectToVisible:(NSRect){point, _frameWidth, _layerHeight}];
}

- (void)_setPlayheadPosition:(NSUInteger)position notifyDelegate:(BOOL)notifyDelegate{
	if (_scrubberView.index == position)
		return;
	_scrubberView.index = position;
	[self setNeedsDisplay:YES];


	if( !notifyDelegate ) {
		NSInteger spaceAround = [[NSUserDefaults standardUserDefaults] integerForKey: kSTENumberOfFramesAroundPlayheadForProgrammaticMoves];
		
		NSRect currentFrameRect = [self visibleRect];
		lpdebug(currentFrameRect);
		currentFrameRect.origin.x = MAX(0, (NSInteger) position - spaceAround) * ( _frameWidth + _frameSpacing );
		currentFrameRect.size.width = (spaceAround ? 2 * spaceAround : 1) * ( _frameWidth + _frameSpacing );
		lpdebug(position,currentFrameRect);
		[self scrollRectToVisible: currentFrameRect];
	}
		
	
	if (!notifyDelegate)
		return;
	if ([_delegate respondsToSelector:@selector(timeline:didSeekToFrame:)]){
		objc_msgSend(_delegate, @selector(timeline:didSeekToFrame:), _timelineView, 
			_scrubberView.index);
	}
}

- (void)_deselectAll{
	[_outOfBoundsSelections removeAllObjects];
	for (TimelineLayer *layer in _layers){
		[layer deselectAll];
		[self setNeedsDisplay:YES];
	}
}

- (NSRect)_visibleLayersRect{
	NSRect visibleRect = [self visibleRect];
	visibleRect.origin.y += kTimeScrubberHeight;
	visibleRect.size.height -= kTimeScrubberHeight;
	return visibleRect;
}





#pragma mark -
#pragma mark Notifications

- (void)scrollViewDidChange:(NSNotification *)notification{
	[self _updateBounds];
}

- (void)scrollViewDidScroll:(NSNotification *)notification{
	NSRect frame = [_scrubberView frame];
	frame.origin.y = NSMinY([[[self enclosingScrollView] contentView] documentVisibleRect]);
	[_scrubberView setFrame:frame];
	[self setNeedsDisplayInRect:[self _visibleLayersRect]];
}

- (void)windowDidResignKey:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}

- (void)windowDidBecomeKey:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}



#pragma mark -
#pragma mark TimelineScrubberViewDelegate methods

- (void)scrubberDidChangeKnobPosition:(TimelineScrubberView *)scrubber{
	[self _updateScrollPositionIfNeeded];
	[self setNeedsDisplay:YES];
	if ([_delegate respondsToSelector:@selector(timeline:didSeekToFrame:)]){
		objc_msgSend(_delegate, @selector(timeline:didSeekToFrame:), _timelineView, scrubber.index);
	}
}
@end
