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

#import "TimelineViewController.h"
#import "AssetMO.h"
#import "ModelAccess.h"
#import "NSArrayController_ObjectExchange.h"
#import "NSTreeController+NSMAdditions.h"
#import "StageEditorViewController.h"

@implementation TimelineViewController

@synthesize deleteButton=_deleteButton,
			treeController=_treeController,
			sceneViewController = _sceneViewController,
			assetEditor = _assetEditor,
			splitView = _splitView;

#pragma mark -
#pragma mark Initialization & Deallocation

#define MODEL_KEYPATH(base, rest) GENERIC_MODEL_KEYPATH(@"representedObject", (base), (rest))
#define MODEL_ACCESS(base, rest)  [self valueForKeyPath: MODEL_KEYPATH((base), (rest))]

- (id)init{
	if ((self = [super initWithNibName:@"TimelineView" bundle:nil])){
	}
	return self;
}

- (void)dealloc{
	[self setModelAccessObservingState: NO];
	[_sceneViewController release];
	[_treeController release];
	[_assetEditor release];
	[_splitView release];	
	[super dealloc];
}

- (TimelineView*)timeline {
	return (TimelineView*)self.view;
}

#pragma mark -
#pragma mark datasource methods

- (NSUInteger)numberOfLayersInTimeline:(TimelineView *)timeline {
	NSUInteger count = 0;
	NSInteger row = 0;
	NSOutlineView *outlineView = [[self timeline] layerOutlineView];
	id rootNode = [self.treeController arrangedObjects];
	for (id node in [rootNode childNodes]) {
		BOOL expanded = [self.timeline isItemExpanded:node];
		count++;
		if (expanded) count += [[node childNodes] count];
		row = [outlineView rowForItem:node];
		count = fmax(count, row);
	}
	return fmax(0, count);
}

- (id)timeline:(TimelineView *)timeline itemForLayerAtIndex:(NSInteger)layerIndex {
	NSUInteger idx = 0;
	id rootNode = [self.treeController arrangedObjects];

	for (id node in [rootNode childNodes]) {
		if (idx==layerIndex) return [node representedObject];
		BOOL expanded = [self.timeline isItemExpanded:node];
		if (expanded == YES) {
			for (id child in [node childNodes]) {
				idx++;
				if (idx==layerIndex) return [child representedObject];
			}			
		}	
		idx++;
	}	
	return nil;	
}

- (NSUInteger)timeline:(TimelineView *)timeline firstFrameIndexInLayerWithIndex:(NSUInteger)layerIndex{
	NSRange range = [[self timeline:self.timeline itemForLayerAtIndex:layerIndex] range];
	return range.location;
}

- (NSUInteger)timeline:(TimelineView *)timeline numberOfFramesInLayerWithIndex:(NSUInteger)layerIndex{
	NSRange range = [[self timeline:timeline itemForLayerAtIndex:layerIndex] range];	
	return range.length;
}

- (void)timeline:(TimelineView *)timeline setTitleOfLayer:(NSString *)newName atIndex:(NSInteger)layerIndex{
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex:layerIndex];
	asset.name = newName;
}

- (NSUInteger)timeline:(TimelineView *)timeline loopValueForLayerAtIndex:(NSInteger)layerIndex {
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex: layerIndex];
	NSUInteger loopValue = [asset.keyframeAnimation.loop unsignedIntValue];
	return loopValue;
}

- (BOOL)timeline:(TimelineView *)timeline layerAtIndexIsVisible:(NSInteger)layerIndex {
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex: layerIndex];
	NSNumber *hidden = [asset valueForKey: @"hidden"];
	BOOL isVisible = ! [hidden boolValue];
	return isVisible;
}

- (BOOL)frameAtIndexPathIsKeyframe:(NSIndexPath *)indexPath{
	AssetMO *asset = [self timeline:nil itemForLayerAtIndex:[indexPath layer]];
	NSIndexSet *keyframes = asset.keyframes;
	return [keyframes containsIndex:[indexPath frame]];
}

- (KeyframeMO *) keyframeForFrameIndex: (NSInteger) frameIndex inLayer: (NSInteger) layerIndex {
	AssetMO *asset = [self timeline:nil itemForLayerAtIndex:layerIndex];	
	return [asset.keyframeAnimation keyframeForTime: [NSNumber numberWithInteger: frameIndex]];
}

- (KeyframeMO *) keyframeForIndexPath: (NSIndexPath *) indexPath {
	return [self keyframeForFrameIndex: [indexPath frame] inLayer: [indexPath layer]];
}

#pragma mark -
#pragma mark observing methods for TimelineGridView

- (void) assets: (NSArray *) assets didChange: (NSDictionary *) change {
	//NDCLog(@"assets: %ld change: %@", (long)[assets count], [change valueForKey: NSKeyValueChangeKindKey]);
	//NSLog(@"asset count: %d", [assets count]);

	SceneMO *scene = [[assets lastObject] scene];

	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(scene == %@) AND (parent == nil)", scene];
	[self.treeController setFetchPredicate:fetchPredicate];
	
	id gridView = [[self timeline] gridView];
	id outlineView = [[self timeline] layerOutlineView];

	[gridView performSelector:@selector(reloadData) withObject:nil afterDelay:0.0];
	[outlineView performSelector:@selector(reloadData) withObject:nil afterDelay:0.0];
}

- (NSTreeNode *)treeNodeForItem:(id)item rootNode:(id)rootNode {
	id obj = [rootNode representedObject];
	if (obj == item) return rootNode;
	for (id child in [rootNode childNodes]) {
		return [self treeNodeForItem:item rootNode:child];
	}
	return nil;
}

//- (NSPredicate*)parentAssetsOnlyFilterPredicate {
//	return [NSPredicate predicateWithFormat:@"parent == nil"];
//}

- (void) selectedAssets: (NSArray *) selectedAssets didChange: (NSDictionary *) change {	
	[[NSNotificationCenter defaultCenter] removeObserver:[self timeline] 
													name:NSOutlineViewSelectionDidChangeNotification object:[[self timeline] layerOutlineView]];
	//NDCLog(@"selectedAssets: %ld change: %@", (long)[selectedAssets count], [change valueForKey: NSKeyValueChangeKindKey]);
	NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
		for (id selectedAsset in selectedAssets) {
			NSIndexPath *indexPath = [self.treeController indexPathForObject:selectedAsset];
			if (indexPath) {
				[indexPaths addObject:indexPath];
			}
		}
	
	[self.treeController setSelectionIndexPaths:indexPaths];
	[[NSNotificationCenter defaultCenter] addObserver:[self timeline] 
											 selector:@selector(layerOutlineViewSelectionDidChange:) 
												 name:NSOutlineViewSelectionDidChangeNotification object:[[self timeline] layerOutlineView]];
	[[[self timeline] layerOutlineView] reloadData];
	[[[self timeline] gridView] reloadData];
	[indexPaths release];
}

- (void) assetsParent: (NSArray *) assetsParent didChange: (NSDictionary *) change {
	[[self treeController] rearrangeObjects];
	[[[self timeline] gridView] reloadData];
}

- (void) assetsHidden: (NSArray *) assetsHidden didChange: (NSDictionary *) change {
	[[[self timeline] gridView] reloadData];
}

- (void) coalescedUnionOfSceneKeyframesTimeDidChange
{
	lptrace();
	[[[self timeline] gridView] reloadData];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// non-magic - comes from ModelAccess.m - calls selectors like [self selectedAssets:newValue didChange: changeDict]
	if( NO == [self processModelAccessObservationForKeyPath: keyPath ofObject:object change:change context:context] ) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)loadView {
	[super loadView];
	//[_treeController setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"viewPosition" ascending:YES]]];
}

- (void)awakeFromNib {
	[self setModelAccessObservingState: YES];
}

#pragma mark -
#pragma mark outlineView delegate methods

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
	[[[self timeline] gridView] reloadData];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
	[[[self timeline] gridView] reloadData];
}

#pragma mark -
#pragma mark timelineview delegate methods

- (void)timeline:(TimelineView *)timeline willDisplayCell:(NSCell *)cell inLayer:(NSUInteger)layerIndex frame:(NSUInteger)frameIndex{
	NSRange range = [[self timeline:timeline itemForLayerAtIndex:layerIndex] range];	
	
	TimelineFrameCell *timelineCell = (TimelineFrameCell *)cell;
	
	if (range.length == 1){
		timelineCell.framePosition = kFramePositionSingle;
	}else{
		if (frameIndex == range.location){
			timelineCell.framePosition = kFramePositionLeft;
			timelineCell.keyframe = YES;
		}else if (frameIndex == range.location + range.length - 1){
			timelineCell.framePosition = kFramePositionRight;
			timelineCell.keyframe = YES;
		}else{
			timelineCell.framePosition = kFramePositionMiddle;
			timelineCell.keyframe = NO;
		}
	}
	
	if (timeline.isDraggingLayers && 
		[timeline.draggedLayers containsObject:[NSNumber numberWithInt:layerIndex]]) {
		timelineCell.enclosingLayerIsDragged = YES;
	} else {
		timelineCell.enclosingLayerIsDragged = NO;
	}
	
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex:layerIndex];
	
	[timelineCell setEnabled: [asset keyFramesEditable]];
	
	NSMutableIndexSet *set = [asset keyframes];
	if ([set containsIndex:frameIndex]){
		timelineCell.keyframe = YES;
	}
}

- (void)timeline:(TimelineView *)timeline didDoubleClickFrame:(NSUInteger)frameIndex inLayer:(NSUInteger)layerIndex {
	NDCLog(@"frame index: %d", frameIndex);
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex:layerIndex];
	if (![asset keyFramesEditable]) {
		NSBeep();
		return;
	}
	[asset.keyframeAnimation ensureKeyframeForTime: [NSNumber numberWithInteger: frameIndex]];
	[[[self timeline] gridView] reloadData];
}

- (void)timeline:(TimelineView *)timeline didChangeLoopValue:(NSUInteger)loopValue forLayerAtIndex:(NSUInteger)index {
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex:index];
	asset.keyframeAnimation.loop = [NSNumber numberWithUnsignedInt:loopValue];
}

- (void)timeline:(TimelineView *)timeline didSeekToFrame:(NSUInteger)frameIndex {
	NSNumber *theTime = [NSNumber numberWithInteger: frameIndex];
	[self.sceneViewController setCurrentTime: theTime];
	self.assetEditor.currentTime = theTime;
	AssetMO *asset = MODEL_ACCESS(kModelAccessAssetSelectionKeyPath, @"self");
	if( nil != asset && NO == NSIsControllerMarker(asset) ) {
		KeyframeMO *keyframe = [asset.keyframeAnimation keyframeForTime: theTime];		
		NSArrayController *arrayController = MODEL_ACCESS(kModelAccessKeyframeArrayControllerKeyPath, nil);
		[arrayController setSelectedObjects: keyframe == nil ? [NSArray array] : [NSArray arrayWithObject: keyframe]];
	}
}
/*
- (BOOL) timeline:(TimelineView *)timeline layerAtIndex: (NSInteger)layerIndex shouldBecomeVisible: (BOOL) visibility {
	NSNumber *hidden = [NSNumber numberWithBool: ! visibility];
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex: layerIndex];
	[asset setValue: hidden forKey: @"hidden"];
	return YES;
}*/

- (NSArray *)timeline:(TimelineView *)timeline draggableFramesAtIndexPaths:(NSArray *)indexPaths{
	#ifdef MULTIPLE_FRAME_DRAG
	return YES;
	#endif
	
	__block BOOL (^isKeyFrame)(NSInteger, AssetMO *) = 	^(NSInteger frame, AssetMO *asset){
		NSRange range = [asset range];
		NSIndexSet *keyframes = [asset keyframes];
		if (frame != range.location && 
			frame != NSMaxRange(range) - 1 && 
			![keyframes containsIndex:frame]){
			return NO;
		}
		return YES;
	};
	
	NSMutableArray *draggableFrames = [NSMutableArray array];
	for (NSIndexPath *indexPath in indexPaths){
		AssetMO *asset = [self timeline:timeline itemForLayerAtIndex:[indexPath layer]];
		if (isKeyFrame([indexPath frame], asset)){
			[draggableFrames addObject:indexPath];
		}
	}
	return draggableFrames;
}

- (NSIndexPath *)timeline:(TimelineView *)timeline 
validateFrameDropPosition:(NSIndexPath *)dropPosition 
	  frameSourcePosition:(NSIndexPath *)sourcePosition{
	return [NSIndexPath indexPathForFrame:[dropPosition frame] inLayer:[sourcePosition layer]];
}

- (void)timeline:(TimelineView *)timeline performFrameDrop:(NSIndexPath *)dropPosition sourcePosition:(NSIndexPath *)sourcePosition{
	
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex:[dropPosition layer]];
	
	if (![asset keyFramesEditable]) {
		NSBeep();
		return;
	}
	
	NSIndexSet *keyframes = [asset keyframes];
	
	KeyframeMO *keyframe = [self keyframeForIndexPath: sourcePosition];
	AssetMO *layer = [self timeline:[self timeline] itemForLayerAtIndex:[dropPosition layer]];
	if (nil != keyframe) {
		// if a keyframe already exists at the drop position, replace it
		if ([keyframes containsIndex:[dropPosition frame]]){
			[[layer.keyframeAnimation mutableSetValueForKey: @"keyframes"]
			 removeObject:[layer.keyframeAnimation keyframeForTime:
						   [NSNumber numberWithInt:[dropPosition frame]]]];
		}
		keyframe.time = [NSNumber numberWithInteger: [dropPosition frame]];
	} else {
		NSLog(@"%@ ALERT !!! Hell freezing over - received drop for non-existing sourcePosition: %@", [self class], sourcePosition);
	}
	
	[[[self timeline] gridView] reloadData];	
	[[NSNotificationCenter defaultCenter] postNotificationName:	kModelAccessPropertiesAffectedNotification object: keyframe];
}

- (BOOL)timeline:(TimelineView *)timeline performLayerDropAtIndex:(NSInteger)layerIndex 
	toFrameIndex:(NSInteger)firstFrameIndex{
	
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex:layerIndex];

	NSRange formerRange = [asset range];
	NSInteger diff = firstFrameIndex - formerRange.location;
	NSArray *orderedKeyframes = [asset valueForKeyPath:@"keyframeAnimation.orderedKeyframes"];
	for (KeyframeMO *keyframe in orderedKeyframes){
		NSInteger formerTime = [keyframe.time integerValue];
		keyframe.time = [NSNumber numberWithInt:formerTime + diff];
	}
	
	// post global one (object nil)
	[[NSNotificationCenter defaultCenter] postNotificationName:kModelAccessPropertiesAffectedNotification object:nil];
	
	[[[self timeline] gridView] reloadData];
	return YES;
}

- (BOOL)timeline:(TimelineView *)timeline shouldDeleteLayersAtIndexes:(NSIndexSet *)layerIndexes {
	[layerIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) { 
		AssetMO *asset = [self timeline:timeline itemForLayerAtIndex: idx];
		[MODEL_ACCESS(kModelAccessAssetArrayControllerKeyPath, nil) removeObject: asset];
	}];
	return YES;
}

- (BOOL)timeline:(TimelineView *)timeline shouldDeleteFramesWithIndexPaths:(NSArray *)indexPaths{
	NSMutableDictionary *indexesPerLayer = [NSMutableDictionary dictionary];
	BOOL shiftKeyDown = ([NSEvent modifierFlags] & NSShiftKeyMask) != 0;
	
	for (NSIndexPath *indexPath in indexPaths){
		NSNumber *key = [NSNumber numberWithInt:[indexPath layer]];
		NSMutableIndexSet *indexSet = [indexesPerLayer objectForKey:key];
		if (!indexSet){
			indexSet = [NSMutableIndexSet indexSet];
			[indexesPerLayer setObject:indexSet forKey:key];
		}
		[indexSet addIndex:[indexPath frame]];
	}
	for (NSNumber *key in indexesPerLayer){
		AssetMO *asset = [self timeline:timeline itemForLayerAtIndex:[key integerValue]];
		NSMutableIndexSet *keyframeIndexes = [asset keyframes];
		NSIndexSet *frames = [indexesPerLayer objectForKey:key];
		NSMutableDictionary *keyframes = [NSMutableDictionary dictionary];
		for (KeyframeMO *keyframe in asset.keyframeAnimation.keyframes){
			[keyframes setObject:keyframe forKey:keyframe.time];
		}
		
		// decreases position of following keyframes by one
		__block void (^deleteFrameAtIndex)(NSInteger) = ^(NSInteger frame){
			NSInteger nextKeyframe = [keyframeIndexes indexGreaterThanIndex:frame];
			while (nextKeyframe != NSNotFound){
				KeyframeMO *keyframe = [keyframes objectForKey:[NSNumber numberWithInt:nextKeyframe]];
				NSNumber *newTime = [NSNumber numberWithInt:([keyframe.time intValue] - 1)];
				keyframe.time = newTime;
				nextKeyframe = [keyframeIndexes indexGreaterThanIndex:nextKeyframe];
			}
		};
		
		NSInteger frame = [frames firstIndex];
		while (frame != NSNotFound){
			if ([keyframeIndexes containsIndex:frame]){ // keyframe
				KeyframeMO *keyframe = [keyframes objectForKey:[NSNumber numberWithInt:frame]];
				NSMutableSet *assetKeyframes = 
					[NSMutableSet setWithSet:asset.keyframeAnimation.keyframes];
				[assetKeyframes removeObject:keyframe];
				asset.keyframeAnimation.keyframes = assetKeyframes;
				if ([assetKeyframes count] < 1){ // last keyframe was deleted
					// remove layer
					[MODEL_ACCESS(kModelAccessAssetArrayControllerKeyPath, nil) removeObject:asset];
					break;
				}else{
					if (shiftKeyDown) deleteFrameAtIndex(frame);
				}
			}else{ // non-keyframe
				if (shiftKeyDown) deleteFrameAtIndex(frame);
			}
			frame = [frames indexGreaterThanIndex:frame];
		}
	}
	[[[self timeline] gridView] reloadData];
	return YES; 
}

- (BOOL)timeline:(TimelineView *)timeline insertLayersFromIndexPaths:(NSArray *)fromIndexPaths  atIndexPaths:(NSArray *)toIndexPaths{

	return NO;
// FIXME
/*	[self setModelAccessObservingState:NO];

	
	// for now from and toIndexPaths will only have one item - an indexpath which also only has one index
	NSInteger fromIndex = [(NSIndexPath *)[fromIndexPaths objectAtIndex:0] indexAtPosition:0];
	NSInteger toIndex = [(NSIndexPath *)[toIndexPaths objectAtIndex:0] indexAtPosition:0];
	
	//	AssetMO *asset = [_cachedLayers objectAtIndex:fromIndex];
	AssetMO *asset = [self timeline:timeline itemForLayerAtIndex:fromIndex];
	//	AssetMO *asset = [layerItemVO representedObject];
	NSMutableArray *layers = [_cachedLayers mutableCopy];
	[layers insertObject:layerItemVO atIndex:toIndex];
	if (toIndex < fromIndex){
		fromIndex++;
	}
	[layers removeObjectAtIndex:fromIndex];
	
	// in theory one could assume that only affected layers need to have their viewPosition updated
	// unfortunately after a PSD import the viewPosition is not neccessarily zero based, nor 
	// have layers incremented their viewPosition by 1; thus we normalize the viewPosition here
	NSInteger i = [layers count] - 1;
	for (LayerItemVO *lyr in layers){
		[[lyr representedObject] setViewPosition: [NSNumber numberWithInt:i--]];
	}
	[layers release];
	
	[self _cacheModelData:YES];
	[self setModelAccessObservingState:YES];
	return YES;*/
}

- (void)timelineLayerSelectionIndexDidChange:(TimelineView *)timeline {
	NSMutableArray *selectedObjects = [NSMutableArray array];
	NSIndexSet *indexes = [[self timeline] selectedLayerListIndexes];
	NSInteger index = [indexes firstIndex];
	while (index != NSNotFound){
		id item = [self timeline:timeline itemForLayerAtIndex:index];
		if (item) {
			[selectedObjects addObject:item];			
		}
		index = [indexes indexGreaterThanIndex:index];
	}
	[self setValue:selectedObjects forKeyPath:MODEL_KEYPATH(kModelAccessSelectedAssetsKeyPath, nil)];
}

#pragma mark -
#pragma mark Actions

- (IBAction)removeLayer:(id)sender{
	NSIndexSet *indexes = [[self timeline] selectedLayerListIndexes];
	if (![indexes count]){
		return;
	}
	[self timeline:[self timeline] shouldDeleteLayersAtIndexes:indexes];
}

@end
