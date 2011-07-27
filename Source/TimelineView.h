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
#import "TimelineGridView.h"
#import "STEScrollView.h"
#import "TimelineLayerBackgroundView.h"
#import "TimelineSplitView.h"
#import "TimelineLayerListCell.h"
#import "TimelineLayerListOutlineView.h"

#define kTimelineViewLayerDragType @"TimelineViewLayerDragType"

@protocol TimelineViewDataSource, TimelineViewDelegate;

@interface TimelineView : NSView <NSOutlineViewDataSource, NSOutlineViewDelegate>{
	STEScrollView *_scrollView;
	TimelineGridView *_gridView;
	NSClipView *_layerOutlineClipView;
	TimelineLayerListOutlineView *_layerOutlineView;
	TimelineLayerBackgroundView *_layerBackgroundView;
	IBOutlet NSTreeController *_treeController;
}
@property (nonatomic, assign) IBOutlet id <NSObject, TimelineViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id <NSObject, TimelineViewDelegate> delegate;
@property (nonatomic, assign) NSUInteger playHeadPosition;
@property (nonatomic, assign) BOOL allowsDraggingOfMultipleFrames;
@property (nonatomic, assign) NSArray *frameSelectionIndexPaths;
@property (nonatomic, readonly) BOOL isDraggingLayers;
@property (nonatomic, readonly) BOOL isDraggingFrames;
@property (nonatomic, readonly) NSSet *draggedLayers;

@property (nonatomic, retain) IBOutlet STEScrollView *scrollView;
@property (nonatomic, retain) IBOutlet TimelineLayerListOutlineView *layerOutlineView;
@property (nonatomic, retain) IBOutlet TimelineGridView *gridView;
@property (nonatomic, retain) IBOutlet TimelineLayerBackgroundView *layerBackgroundView;

- (void)reloadData;
- (BOOL)isItemExpanded:(id)item;
- (NSIndexSet *)selectedLayerListIndexes;

@end


@protocol TimelineViewDataSource
@required
- (NSUInteger)numberOfLayersInTimeline:(TimelineView *)timeline;
- (NSUInteger)timeline:(TimelineView *)timeline firstFrameIndexInLayerWithIndex:(NSUInteger)layerIndex;
- (NSUInteger)timeline:(TimelineView *)timeline numberOfFramesInLayerWithIndex:(NSUInteger)layerIndex;
- (NSString *)timeline:(TimelineView *)timeline titleForLayerAtIndex:(NSInteger)layerIndex;
- (NSString *)timeline:(TimelineView *)timeline itemForLayerAtIndex:(NSInteger)layerIndex;
- (NSUInteger)timeline:(TimelineView *)timeline loopValueForLayerAtIndex:(NSInteger)layerIndex;
- (void)timeline:(TimelineView *)timeline setTitleOfLayer:(NSString *)newName atIndex:(NSInteger)layerIndex;
- (BOOL)timeline:(TimelineView *)timeline layerAtIndexIsVisible:(NSInteger)layerIndex;
@optional
- (void)timeline:(TimelineView *)timeline performFrameDrop:(NSIndexPath *)dropPosition sourcePosition:(NSIndexPath *)sourcePosition;
- (BOOL)timeline:(TimelineView *)timeline insertLayersFromIndexPaths:(NSArray *)fromIndexPaths atIndexPaths:(NSArray *)toIndexPaths;
- (BOOL)timeline:(TimelineView *)timeline performLayerDropAtIndex:(NSInteger)layerIndex toFrameIndex:(NSInteger)firstFrameIndex;
@end


@protocol TimelineViewDelegate
@optional
- (void)timeline:(TimelineView *)timeline willDisplayCell:(NSCell *)cell inLayer:(NSUInteger)layerIndex frame:(NSUInteger)frameIndex;
- (void)timeline:(TimelineView *)timeline didDoubleClickFrame:(NSUInteger)frameIndex inLayer:(NSUInteger)layerIndex;
- (void)timeline:(TimelineView *)timeline didChangeLoopValue:(NSUInteger)loopValue forLayerAtIndex:(NSUInteger)index;
- (void)timeline:(TimelineView *)timeline didSeekToFrame:(NSUInteger)frameIndex;
- (NSArray *)timeline:(TimelineView *)timeline draggableFramesAtIndexPaths:(NSArray *)indexPaths;
- (BOOL)timeline:(TimelineView *)timeline canDragLayerAtIndex:(NSInteger)layerIndex;
- (NSIndexPath *)timeline:(TimelineView *)timeline validateFrameDropPosition:(NSIndexPath *)dropPosition frameSourcePosition:(NSIndexPath *)sourcePosition;
- (BOOL)timeline:(TimelineView *)timeline shouldDeleteLayersAtIndexes:(NSIndexSet *)layerIndexes;
- (BOOL)timeline:(TimelineView *)timeline shouldDeleteFramesWithIndexPaths:(NSArray *)indexPaths;
- (BOOL)timeline:(TimelineView *)timeline layerAtIndex:(NSInteger)layerIndex shouldBecomeVisible:(BOOL)visible;
- (void)timelineLayerSelectionIndexDidChange:(TimelineView *)timeline;
- (BOOL)frameAtIndexPathIsKeyframe:(NSIndexPath *)indexPath;

@end
