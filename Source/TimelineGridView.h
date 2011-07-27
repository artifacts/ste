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

#import <Cocoa/Cocoa.h>
#import "TimelineLayer.h"
#import "NSIndexPath+TimelineView.h"
#import <EngineRoom/EngineRoom.h>
#import "TimelineScrubberView.h"

extern const CGFloat kTimeScrubberHeight;

@protocol TimelineViewDataSource, TimelineViewDelegate;
@class TimelineView;

@interface TimelineGridView : NSView <TimelineScrubberViewDelegate>{
	TimelineView *_timelineView;
	TimelineScrubberView *_scrubberView;
	NSArray *_layers;
	CGFloat _layerHeight;
	CGFloat _frameWidth;
	CGFloat _layerSpacing;
	CGFloat _frameSpacing;
	NSInteger _maxFrames;
	NSRect _selectionRect;
	id <NSObject, TimelineViewDataSource> _dataSource;
	id <NSObject, TimelineViewDelegate> _delegate;
	BOOL _allowsDraggingOfMultipleFrames;
	NSArray *_dropTargetIndexSets;
	NSMutableArray *_outOfBoundsSelections;
	BOOL _isDraggingLayers;
	BOOL _isDraggingFrames;
	NSSet *_draggedLayers;
	BOOL _spaceKeyDown;
	NSTrackingArea *_trackingArea;
	NSIndexSet *_highlightedLayers;
	BOOL _enabled;
}
@property (nonatomic, assign) IBOutlet TimelineView *timelineView;
@property (nonatomic, assign) IBOutlet id <NSObject, TimelineViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id <NSObject, TimelineViewDelegate> delegate;
@property (nonatomic, assign) CGFloat layerHeight;
@property (nonatomic, assign) CGFloat frameWidth;
@property (nonatomic, assign) CGFloat frameSpacing;
@property (nonatomic, assign) CGFloat layerSpacing;
@property (nonatomic, assign) NSUInteger playHeadPosition;
@property (nonatomic, assign) BOOL allowsDraggingOfMultipleFrames;
@property (nonatomic, assign) NSArray *selectionIndexPaths;
@property (nonatomic, readonly) BOOL isDraggingLayers;
@property (nonatomic, readonly) BOOL isDraggingFrames;
@property (nonatomic, readonly) NSSet *draggedLayers;
@property (nonatomic, retain) NSIndexSet *highlightedLayers;
@property (nonatomic, assign) BOOL enabled;
- (void)reloadData;
- (void)selectFrameAtIndexPath:(NSIndexPath *)indexPath byExtendingSelection:(BOOL)byExtending;
- (void)selectFramesInRect:(NSRect)aRect byExtendingSelection:(BOOL)byExtending;
- (void)deselectAll;
@end
