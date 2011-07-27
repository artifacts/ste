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
#import "ModelAccess.h"
#import "AssetDragVO.h"
#import "BKColor.h"
#import "SceneArrayController.h"
#import "PreviewController.h"
#import "BooleanToIndexTransformer.h"
#import "StageEditorViewController.h"
#import "TaskWrapper.h"

typedef enum{
	kSTEAnimationModeToolbar,
	kSTEPSDImportModeToolbar
} STEToolbarMode;

@interface MyDocument : NSPersistentDocument <ModelAccess, TaskWrapperController, NSAlertDelegate> {

	NSArrayController *stageArrayController;
	NSObjectController *scenarioController;
	NSArrayController *playableArrayController;
	SceneArrayController *sceneArrayController;
	NSArrayController *assetArrayController;
	NSArrayController *keyframeArrayController;
	NSObjectController *keyframeAnimationController;
	NSArrayController *unionOfSceneKeyframesArrayController;
	
	NSWindow *editorWindow;
	NSArray *_editorWindowDragTypes;

	NSPanel *progressSheet;
	NSProgressIndicator *progressIndicator;
	NSTextField *progressTitleField;
	IBOutlet NSButton *playButton;

	StageEditorViewController *stageEditorViewController;
	NSView *stageEditorViewPlaceholder;

	NSInteger disableObserversCount;

	TaskWrapper *importTaskWrapper;

	double _psdImportScale; 
	NSTimer *_playTimer;
	
	NSToolbarItem *statusDisplayToolbarItem;
	NSToolbarItem *physicsSwitchToolbarItem;
	NSView *statusDisplay;
	NSView *physicsSwitch;
	
	PreviewController *previewController;
}

// ModelAccess properties
@property (nonatomic, retain) IBOutlet NSArrayController *stageArrayController;
@property (nonatomic, retain) IBOutlet NSObjectController *scenarioController;
@property (nonatomic, retain) IBOutlet NSArrayController *playableArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController *sceneArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController *assetArrayController;
@property (nonatomic, retain) IBOutlet NSObjectController *keyframeAnimationController;
@property (nonatomic, retain) IBOutlet NSArrayController *keyframeArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController *unionOfSceneKeyframesArrayController;
@property (nonatomic, retain) IBOutlet NSWindow *editorWindow;
@property (nonatomic, retain) IBOutlet NSToolbarItem *statusDisplayToolbarItem;
@property (nonatomic, retain) IBOutlet NSToolbarItem *physicsSwitchToolbarItem;
@property (nonatomic, retain) IBOutlet NSView *statusDisplay;
@property (nonatomic, retain) IBOutlet NSView *physicsSwitch;
@property (nonatomic, retain) IBOutlet NSPanel *progressSheet;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField *progressTitleField;
@property (nonatomic, retain) IBOutlet StageEditorViewController *stageEditorViewController;
@property (nonatomic, retain) IBOutlet NSView *stageEditorViewPlaceholder;
@property (nonatomic, retain) IBOutlet PreviewController *previewController;

@property (nonatomic, retain) NSArray *editorWindowDragTypes;
@property (nonatomic, assign) NSInteger disableObserversCount;
@property (nonatomic, retain) TaskWrapper *importTaskWrapper;
@property (nonatomic, assign) double psdImportScale;

#pragma mark -
#pragma mark Candidates for refactoring

// located here because it is addressed via representedObject from CanvasSceneView
// could move into a dedicated model manager
- (void)createAssetFromDragData:(AssetDragVO *)dragData atPoint:(CGPoint)aPoint;
- (void)makeCurrentInAppDelegate: (BOOL) active;
- (void)createAssetContainingChildren:(NSArray *)children withName:(NSString*)name;
- (BOOL)itemsMayBeGrouped:(NSArray *)items;

#pragma mark -
#pragma mark Construction

- (void)awakeFromNib;
- (NSString *)windowNibName ;
- (void)windowControllerDidLoadNib:(NSWindowController *)windowController ;
- (id)init;
- (id)initWithType:(NSString *)typeName error:(NSError **)outError ;
- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;


#pragma mark -
#pragma mark Destruction

- (void) close;
- (void) dealloc;


#pragma mark -
#pragma mark Window delegate methods

- (void) windowDidBecomeMain: (NSNotification *) notification;
- (void) windowDidResignMain: (NSNotification *) notification;
- (void) windowWillClose: (NSNotification *) notification;


#pragma mark -
#pragma mark Controlling observers

- (void) enableObservers;
- (void) disableObservers;


#pragma mark -
#pragma mark Actions and friends

- (IBAction)rewind:(id)sender;
- (IBAction)play:(id)sender;
- (void)doPlay:(NSTimer *)aTimer;
- (void)updatePlayButton;
- (IBAction) test: (id) sender;
- (IBAction) producePageLayoutData: (id) sender;
- (IBAction)togglePhysicsMode:(id)sender;
- (BOOL)documentHasKeyframeAnimationsOrMultipleScenes;

#pragma mark -
#pragma mark Housekeeping
- (BOOL) consistencyCheckOrphanedObjectsForDocumentFromURL: (NSURL *) URL error: (NSError **) outError;
- (BOOL) consistencyCheckForDocumentFromURL: (NSURL *) URL error: (NSError **) outError;

#pragma mark -
#pragma mark Document and snippet reading

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName toplevelObjects: (NSArray **) outToplevelObjects error:(NSError **)outError;
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError;
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName toplevelObjects: (NSArray **) outToplevelObjects error:(NSError **)outError;
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError;

// imports plist representations with all coordinates (except the stage size) normalized to a 1 by 1 coordinate system
// if defined STE_PLIST_COORDINATE_SCALING
+ (NSArray *) importPlistRepresentation: (NSArray *) plist intoManagedObjectContext: (NSManagedObjectContext *) managedObjectContext error: (NSError **) outError;

// uses readFromURL, therefore scales normalized coordinates
// if defined STE_PLIST_COORDINATE_SCALING
- (NSArray *) objectsFromPlistResourceNamed: (NSString *) name error:(NSError **)outError;


#pragma mark -
#pragma mark Scene Prototype creation

- (SceneMO*)createScenePrototype;

#pragma mark -
#pragma mark Layer Dictionary Import

- (void) delayedImportLayerDictionaries: (NSArray *) layerDictionaries;
- (BOOL) importLayerDictionaries: (NSArray * ) layerDictionaries error: (NSError **) outError;
- (StageMO *) ensureStageAndSceneForImportOfLayerDictionaries: (NSArray * ) layerDictionaries error: (NSError **) outError;
- (BOOL) configureAsset: (AssetMO *) asset fromLayerDictionary: (NSDictionary *) layerDictionary error: (NSError **) outError;
- (void) startImportTaskWithCLITool: (NSString *) cliTool arguments: (NSArray *) arguments;
- (void) importLayersFromFileAtPath: (NSString *) path;
- (void) startModalProgress: (NSString *) title;
- (void) progressSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void) endModalProgress;
- (void) processStarted;
- (void) processFinishedWithStatus: (NSInteger) terminationStatus reason: (NSTaskTerminationReason) terminationReason outputData: (NSData *) outputData errorData: (NSData *) errorData userInfo: (id) info;


#pragma mark -
#pragma mark migration

- (BOOL)isMigrationNecessaryForURL:(NSURL*)sourceStoreURL ofType:(NSString*)sourceStoreType;

#pragma mark -
#pragma mark DocumentSettings
- (void)setDocumentSettingsDate;

@end

