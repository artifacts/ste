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

#import "StageEditorViewController.h"
#import <EngineRoom/EngineRoom.h>

#import "ModelAccess.h"

#define MODEL_KEYPATH(base, rest) GENERIC_MODEL_KEYPATH(@"representedObject", (base), (rest))
#define MODEL_ACCESS(base, rest)  [self valueForKeyPath: MODEL_KEYPATH((base), (rest))]

static NSString *kStageEditorViewControllerTimelineGridViewSelectionIndexPathsKey = @"selectionIndexPaths";
static NSString *kStageEditorViewControllerTimelineGridViewOutOfBoundsSelectionIndexPathsKey = @"_outOfBoundsSelections";


@implementation StageEditorViewController

@synthesize assetEditor = _assetEditor;

@synthesize sceneViewController = _sceneViewController;
@synthesize scrollView = _scrollView;

@synthesize sceneCollectionViewController = _sceneCollectionViewController;
@synthesize sceneCollectionViewPlaceholder = _sceneCollectionViewPlaceholder;

@synthesize timelineViewController = _timelineViewController;
@synthesize timelineViewPlaceholder = _timelineViewPlaceholder;

@synthesize timelineView = _timelineView;
@synthesize timelineSplitView = _timelineSplitView;

- (void) setupSceneViewController
{
	self.sceneViewController = [[SceneViewController alloc] initWithMainArrayControllerKeyPath: kModelAccessAssetArrayControllerKeyPath];

	[self.sceneViewController addObserver:self forKeyPath: kSceneViewControllerCurrentTimeKey options:0 context: NULL];

	self.scrollView.documentView = self.sceneViewController.view;
	self.scrollView.layer.backgroundColor = UTIL_AUTORELEASE_CF( CGColorCreateGenericRGB(0, 0, 1, 1) );

	[self.sceneViewController insertIntoResponderChainAt: self.sceneViewController.view];

	[self.sceneViewController bind: @"representedObject" toObject: self withKeyPath: @"representedObject" options: nil];
}


- (void) shutdownSceneViewController
{
	[self.sceneViewController unbind: @"representedObject"];
	[self.sceneViewController removeObserver: self forKeyPath: kSceneViewControllerCurrentTimeKey];

	self.scrollView.documentView = nil;
	self.scrollView = nil;

	self.sceneViewController = nil;
}

- (void) setupSceneCollectionViewController
{
	self.sceneCollectionViewController = [[SceneCollectionViewController viewControllerReplacingPlaceholderView: self.sceneCollectionViewPlaceholder mainArrayControllerKeyPath: kModelAccessSceneArrayControllerKeyPath] retain];
	self.sceneCollectionViewPlaceholder = nil;

	[self.sceneCollectionViewController bind: @"representedObject" toObject: self withKeyPath: @"representedObject" options: nil];
}

- (void) shutdownSceneCollectionViewController
{
	[self.sceneCollectionViewController unbind: @"representedObject"];
	self.sceneCollectionViewController = nil;
}

- (void) setupAssetEditor
{
	self.assetEditor = [[AssetEditor alloc] init];
	self.assetEditor.currentTime = [NSNumber numberWithInteger: 0];

	[self.assetEditor bind: @"currentAsset" toObject: self withKeyPath: MODEL_KEYPATH(kModelAccessAssetSelectionKeyPath, @"self") options: nil];
}

- (void) shutdownAssetEditor
{
	[self.assetEditor unbind: @"currentAsset"];
	self.assetEditor = nil;
}

- (void) setupTimelineViewController
{
	self.timelineViewController = [TimelineViewController viewControllerReplacingPlaceholderView: self.timelineViewPlaceholder];
	self.timelineViewPlaceholder = nil;

	[self.timelineViewController bind: @"representedObject" toObject: self withKeyPath: @"representedObject" options: nil];
	self.timelineViewController.assetEditor = self.assetEditor;
	self.timelineViewController.sceneViewController = self.sceneViewController;

	// trigger view loading (in case the line below vanishes)
	self.timelineViewController.view;
	
	// support asset selection from the gridView - sigh - see top of file
	[self.timelineViewController.timeline.gridView addObserver: self 
									   forKeyPath: kStageEditorViewControllerTimelineGridViewSelectionIndexPathsKey
										  options: NSKeyValueObservingOptionNew 
										  context: NULL];
}

- (void) shutdownTimelineViewController
{
	[self.timelineViewController.timeline.gridView removeObserver: self forKeyPath: kStageEditorViewControllerTimelineGridViewSelectionIndexPathsKey];
	
	[self.timelineViewController unbind: @"representedObject"];

	self.timelineViewController = nil;
}

- (void) loadView
{
	[super loadView];
	
	// first ! - timelineViewController needs it
	[self setupAssetEditor];

	[self setupSceneViewController];
	[self setupSceneCollectionViewController];
	[self setupTimelineViewController];

	[self setModelAccessObservingState: YES];	
}

- (void) dealloc
{
	[self setModelAccessObservingState: NO];

	[self shutdownAssetEditor];
	[self shutdownTimelineViewController];
	[self shutdownSceneCollectionViewController];
	[self shutdownSceneViewController];

	self.representedObject = nil;

	[super dealloc];
}
@end

@implementation StageEditorViewController (ModelObserving)

- (void) delayedSelectionFromTimelineGridViewWithChangeDictionary
{
	NSArray *indexPaths = [self.timelineViewController.timeline.gridView valueForKey: kStageEditorViewControllerTimelineGridViewSelectionIndexPathsKey];

	BOOL outOfBounds = NO;
	
	if( 0 == [indexPaths count] ) {
		outOfBounds = YES;
		indexPaths = [self.timelineViewController.timeline.gridView valueForKey: kStageEditorViewControllerTimelineGridViewOutOfBoundsSelectionIndexPathsKey];
		if( 0 == [indexPaths count] ) {
			// avoid deselection - leads to visual annoyances - can't deselect in this sense from the GridView anyway
			return;
		}
	}
	
	NSMutableIndexSet *newAssetIndexes = [NSMutableIndexSet indexSet];

	NSArrayController *assetArrayController = MODEL_ACCESS(kModelAccessAssetArrayControllerKeyPath, nil);
	
	NSArray *arrangedAssets = MODEL_ACCESS(kModelAccessAssetsKeyPath, nil);
	
	[indexPaths enumerateObjectsUsingBlock:^(id indexPath, NSUInteger idx, BOOL *stop) { 
		NSUInteger layerIndex = [(NSIndexPath*)indexPath layer];

		id item = [self.timelineViewController timeline: self.timelineViewController.timeline itemForLayerAtIndex: layerIndex];
		if( nil != item ) {
			NSInteger assetIndex = [arrangedAssets indexOfObject: item];
			if( NSNotFound	!= assetIndex ) {
				[newAssetIndexes addIndex: assetIndex]; 				
			}
		}
	}];		


	
	NSIndexSet *currentAssetIndexes = [assetArrayController selectionIndexes];
	
	lpdebug(indexPaths, currentAssetIndexes, newAssetIndexes);
	
	if( NO == [currentAssetIndexes isEqualToIndexSet: newAssetIndexes] ) {
		[assetArrayController setSelectionIndexes: newAssetIndexes];

		// an asset selection change resets the frame selection...
		if( NO == outOfBounds ) {
			[self.timelineViewController.timeline.gridView setValue: indexPaths forKey: kStageEditorViewControllerTimelineGridViewSelectionIndexPathsKey];
		}
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// see top of file for why
	if ( [keyPath isEqualToString: kStageEditorViewControllerTimelineGridViewSelectionIndexPathsKey] ) {
		// the cancel is needed to prevent looping when selecting/moving keyframes in multiple assets
		[[self class] cancelPreviousPerformRequestsWithTarget: self selector: @selector(delayedSelectionFromTimelineGridViewWithChangeDictionary) object: nil];
		[self performSelector: @selector(delayedSelectionFromTimelineGridViewWithChangeDictionary) withObject: nil afterDelay: 0.0];
		return;
	}
	
	if ([keyPath isEqualToString: kSceneViewControllerCurrentTimeKey]){
		[[self.timelineViewController timeline] setPlayHeadPosition: [self.sceneViewController.currentTime integerValue]];
		return;
	}
	
	// non-magic - comes from ModelAccess.m - calls selectors like [self selectedAssets:newValue didChange: changeDict]
	if( NO == [self processModelAccessObservationForKeyPath: keyPath ofObject:object change:change context:context] ) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end

@implementation StageEditorViewController( FirstResponderMethods )

- (void) moveUp:(id)sender
{
	[(NSArrayController *)MODEL_ACCESS(kModelAccessAssetArrayControllerKeyPath, nil) selectPrevious: sender]; 
}

- (void) moveDown:(id)sender
{
	[(NSArrayController *)MODEL_ACCESS(kModelAccessAssetArrayControllerKeyPath, nil) selectNext: sender]; 
}

- (void) moveLeft: (id) sender
{
	[self.sceneViewController moveInTimeBy: -1];
}

- (void) moveRight: (id) sender
{
	[self.sceneViewController moveInTimeBy: 1];
}

@end

@implementation StageEditorViewController( ForwardingSelectorsBecauseTheChainIsMalformed )

static inline BOOL isSelectorInList(SEL sel, char **nameList) 
{
	const char *selName = sel_getName(sel);
	
	for(int i = 0 ; nameList[i] ; ++i ) {
		if( 0 == strcmp(nameList[i], selName ) ) {
			return YES;
		}
	}
	return NO;
}

static NSResponder *responderForSelector(StageEditorViewController *self, SEL sel)
{
	static char *selectorsForwardedToSceneViewController[] =
	{
		"cut:",
		"copy:",
		"paste:",
		"delete:",
		"duplicate:",
		"copyFont:",
		"pasteFont:",
		"moveInTimeByTagValue:",
		"moveInKeyFramesByTagPercent:",
		nil
	};
	
	
	if( isSelectorInList(sel, selectorsForwardedToSceneViewController) ) {
		return self.sceneViewController;
	}
	
	return nil;
}

- (BOOL) respondsToSelector:(SEL) sel
{
	lpdebug(sel);
	return responderForSelector(self, sel) ? YES : [super respondsToSelector: sel];
}

- (id) forwardingTargetForSelector: (SEL) sel
{
	lpdebug(sel);
	return responderForSelector(self, sel);
}

@end
