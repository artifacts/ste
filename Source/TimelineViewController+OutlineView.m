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

#import "TimelineViewController+OutlineView.h"
#import "NSTreeController+NSMAdditions.h"

#import "TimelineView.h"
#import "MyDocument.h"

@implementation TimelineViewController (OutlineView)

#pragma mark -
#pragma mark NSOutlineViewDataSource/NSOutlineViewDelegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if (![item respondsToSelector:@selector(representedObject)]) return;
	AssetMO *asset = [item representedObject];
	TimelineLayerListCell *theCell = (TimelineLayerListCell *)cell;
	[theCell setTarget:self];
	[theCell setAction:@selector(outlineViewCellWasClicked:)];
	[theCell setRepresentedObject:[self.treeController indexPathForObject:asset]];
	theCell.layerIsVisible = ![[asset valueForKey:@"hidden"] boolValue];
	theCell.layerIsVisible = [self timeline:self layerAtIndexIsVisible:[[[self timeline] layerOutlineView] rowForItem:item]];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	[[[self timeline] gridView] reloadData];
}

#pragma mark -
#pragma mark Action methods

- (void)outlineViewCellWasClicked:(id)sender {
	TimelineLayerListCell *cell = sender;
	NSIndexPath *indexPath = [cell representedObject];
	id node = [self.treeController nodeAtIndexPath:indexPath];
	AssetMO *asset = [node representedObject];
	BOOL hidden = [[asset hidden] boolValue];
	[asset setValue: [NSNumber numberWithBool:!hidden] forKey: @"hidden"];
}

- (NSArray *)treeNodeSortDescriptors {
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"viewPosition" ascending:NO]];
}
- (void)setTreeNodeSortDescriptors:(NSArray*)desc {
}

@end

@implementation TimelineViewController (NSOutlineViewDragAndDrop)

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteBoard;
{
	[pasteBoard declareTypes:[NSArray arrayWithObject:kTimelineViewLayerDragType] owner:self];
	[pasteBoard setData:[NSKeyedArchiver archivedDataWithRootObject:[items valueForKey:@"indexPath"]] forType:kTimelineViewLayerDragType];
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)proposedParentItem proposedChildIndex:(NSInteger)proposedChildIndex;
{
	NSData *carriedData = [info.draggingPasteboard dataForType:kSTEAssetDragType];
	NSArray *dragData = [NSKeyedUnarchiver unarchiveObjectWithData:carriedData];
	
	if ([dragData count] > 0) {
		return (proposedParentItem != nil) ? NSDragOperationLink : NSDragOperationNone;
	}
	if (proposedChildIndex == -1) // will be -1 if the mouse is hovering over a leaf node
		return NSDragOperationNone;
	return NSDragOperationMove;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)proposedParentItem childIndex:(NSInteger)proposedChildIndex 
{
	// handle Assets (update URL and ID)
	NSData *carriedData = [info.draggingPasteboard dataForType:kSTEAssetDragType];
	NSArray *dragData = [NSKeyedUnarchiver unarchiveObjectWithData:carriedData];
	AssetMO *assetToBeUpdated = [proposedParentItem representedObject];
	for (AssetDragVO *dragVO in dragData){
		assetToBeUpdated.primaryBlob.externalURL = dragVO.externalURL;
		assetToBeUpdated.primaryBlob.externalId = dragVO.externalId;
		return YES;
	}
	
	
	// handle TL List items
	NSArray *droppedIndexPaths = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:kTimelineViewLayerDragType]];
	
	NSMutableArray *draggedNodes = [NSMutableArray array];
	for (NSIndexPath *indexPath in droppedIndexPaths)
		[draggedNodes addObject:[self.treeController nodeAtIndexPath:indexPath]];
	
	NSIndexPath *proposedParentIndexPath;
	if (!proposedParentItem)
		proposedParentIndexPath = [[[NSIndexPath alloc] init] autorelease]; // makes a NSIndexPath with length == 0
	else
		proposedParentIndexPath = [proposedParentItem indexPath];
	
	[self.treeController moveNodes:draggedNodes toIndexPath:[proposedParentIndexPath indexPathByAddingIndex:proposedChildIndex]];
	return YES;
}


@end
