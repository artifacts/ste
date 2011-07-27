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
#import "STViewController.h"
#import "TimelineView.h"
#import "TimelineFrameCell.h"
#import "KeyframeMO.h"
#import "SceneViewController.h"
#import "AssetEditor.h"

@interface TimelineViewController : STViewController {
	IBOutlet NSView *_buttonBar;
	IBOutlet NSButton *_deleteButton;
	NSTreeController *_treeController;
	SceneViewController *_sceneViewController;
	AssetEditor *_assetEditor;
	NSSplitView *_splitView;
}

@property (nonatomic, readonly) NSButton *deleteButton;
@property (nonatomic, retain) IBOutlet NSTreeController *treeController;
@property (nonatomic, retain) IBOutlet SceneViewController *sceneViewController;
@property (nonatomic, retain) IBOutlet AssetEditor *assetEditor;
@property (nonatomic, retain) IBOutlet NSSplitView *splitView;

- (TimelineView*)timeline;
- (IBAction)removeLayer:(id)sender;

@end

@interface TimelineViewController(Keyframes)
- (BOOL)frameAtIndexPathIsKeyframe:(NSIndexPath *)indexPath;
- (KeyframeMO *) keyframeForFrameIndex: (NSInteger) frameIndex inLayer: (NSInteger) layerIndex;
- (KeyframeMO *) keyframeForIndexPath: (NSIndexPath *) indexPath;
@end


@interface TimelineViewController(ModelAccessObserver)
- (void) assets: (NSArray *) assets didChange: (NSDictionary *) change;
- (void) selectedAssets: (NSArray *) selectedAssets didChange: (NSDictionary *) change;
- (void) assetsHidden: (NSArray *) assetsHidden didChange: (NSDictionary *) change;
- (void) keyframes: (NSArray *) keyframes didChange: (NSDictionary *) change;
- (void) keyframesTime: (NSArray *) keyframesTime didChange: (NSDictionary *) change;
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
@end
