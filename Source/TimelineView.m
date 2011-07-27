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

#import "TimelineView.h"
#import "AssetMO.h"
#import "MyDocument.h"


@implementation TimelineView

@synthesize scrollView=_scrollView,
layerOutlineView=_layerOutlineView,
layerBackgroundView=_layerBackgroundView,
gridView=_gridView;

- (void) dealloc
{
	[_layerBackgroundView release];
	[_layerOutlineView release];
	[_scrollView release];
	[_gridView release];
	[super dealloc];
}

- (void)awakeFromNib {
	[_layerOutlineView setRowHeight:_gridView.layerHeight - 1.0f];
	[_layerOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:kTimelineViewLayerDragType, kSTEAssetDragType, nil]];
	[_layerOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
	[_layerOutlineView setBackgroundColor:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerOutlineViewDidScroll:) 
												 name:NSViewBoundsDidChangeNotification object:[[_layerOutlineView enclosingScrollView] contentView]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gridViewDidScroll:) 
												 name:NSViewBoundsDidChangeNotification object:[_scrollView contentView]];
												 
	[_treeController addObserver:self forKeyPath:@"selectionIndexPaths" options:0 context:NULL];
	
}

#pragma mark -
#pragma mark Public methods

- (void)setDataSource:(id <NSObject, TimelineViewDataSource>)aDataSource{
	[_layerOutlineView reloadItem:nil];
}

- (id <NSObject, TimelineViewDataSource>)dataSource{
	return _gridView.dataSource;
}

- (void)setDelegate:(id <NSObject,TimelineViewDelegate>)aDelegate{
	_gridView.delegate = aDelegate;
}

- (id <NSObject, TimelineViewDelegate>)delegate{
	return _gridView.delegate;
}

- (BOOL)isItemExpanded:(id)item {
	return [_layerOutlineView isItemExpanded:item];
}

- (void)reloadData{
	[_layerOutlineView reloadData];	
	[_gridView reloadData];	
}

- (NSIndexSet *)selectedLayerListIndexes{
	return [_layerOutlineView selectedRowIndexes];
}

- (NSUInteger)playHeadPosition{
	return _gridView.playHeadPosition;
}

- (void)setPlayHeadPosition:(NSUInteger)position{
	_gridView.playHeadPosition = position;
}

- (BOOL)allowsDraggingOfMultipleFrames{
	return _gridView.allowsDraggingOfMultipleFrames;
}

- (void)setAllowsDraggingOfMultipleFrames:(BOOL)bFlag{
	_gridView.allowsDraggingOfMultipleFrames = bFlag;
}

- (NSArray *)frameSelectionIndexPaths{
	return _gridView.selectionIndexPaths;
}

- (void)setFrameSelectionIndexPaths:(NSArray *)indexPaths{
	_gridView.selectionIndexPaths = indexPaths;
}

- (BOOL)isDraggingFrames{
	return _gridView.isDraggingFrames;
}

- (BOOL)isDraggingLayers{
	return _gridView.isDraggingLayers;
}

- (NSSet *)draggedLayers{
	return _gridView.draggedLayers;
}

- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath 
	options:(NSKeyValueObservingOptions)options context:(void *)context{
	// forward frameSelectionIndexPaths
	if ([keyPath isEqualToString:@"frameSelectionIndexPaths"]){
		[_gridView addObserver:anObserver forKeyPath:@"selectionIndexPaths" 
			options:options context:context];
		return;
	}
	[super addObserver:anObserver forKeyPath:keyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
	// forward frameSelectionIndexPaths
	if ([keyPath isEqualToString:@"frameSelectionIndexPaths"]){
		[_gridView removeObserver:observer forKeyPath:@"selectionIndexPaths"];
		return;
	}
	[super removeObserver:observer forKeyPath:keyPath];
}


#pragma mark -
#pragma mark Notifications

- (void) ensureScrollView: (NSScrollView *) scrollView reflectsVerticalPositionOfOtherScrollView: (NSScrollView *) otherScrollView
{	
	NSPoint curOffset = [[scrollView contentView] bounds].origin;
	
	NSPoint newOffset = NSMakePoint(
									NSMinX([[scrollView contentView] documentVisibleRect]), 
									NSMinY([[otherScrollView contentView] documentVisibleRect])
									);
	
    if ( NO == NSEqualPoints(curOffset, newOffset) ) {
		[[scrollView contentView] scrollToPoint: newOffset];
		[scrollView reflectScrolledClipView:[scrollView contentView]];
	}
}

- (void)gridViewDidScroll:(NSNotification *)notification{
	[self ensureScrollView: [_layerOutlineView enclosingScrollView] reflectsVerticalPositionOfOtherScrollView: _scrollView];
}

- (void)layerOutlineViewDidScroll:(NSNotification *)notification{
	[self ensureScrollView: _scrollView reflectsVerticalPositionOfOtherScrollView: [_layerOutlineView enclosingScrollView]];
}
	
- (void)layerOutlineViewSelectionDidChange:(NSNotification *)notification{
	if ([_gridView.delegate respondsToSelector:@selector(timelineLayerSelectionIndexDidChange:)]){
		[_gridView.delegate timelineLayerSelectionIndexDidChange:self];
	}
}


#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context{
	if ([keyPath isEqualToString:@"selectionIndexPaths"]){
		_gridView.highlightedLayers = [self selectedLayerListIndexes];
	}
}
@end
