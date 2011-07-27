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

#import "MyDocument.h"
#import "StoryTellingEditorAppDelegate.h"
#import <AFCache/AFCacheLib.h>
#import <EngineRoom/CrossPlatform_Utilities.h>
#import <EngineRoom/tracer.h>
#import "ObjectExchange.h"
#import "NSManagedObject_DictionaryRepresentation.h"
#import "Convenience_Macros.h"
#import "FileUtil.h"
#import "NSWindow+Util.h"
#import "MediaContainer.h"
#import "NSString+md5.h"

#define MODEL_KEYPATH(base, rest) GENERIC_MODEL_KEYPATH(nil, (base), (rest))
#define MODEL_ACCESS(base, rest)  [self valueForKeyPath: MODEL_KEYPATH((base), (rest))]

#define TOGGLE_OBSERVERS 0

#if ! TOGGLE_OBSERVERS
#endif

static NSString *kDocumentTypePSD = @"PSD";
static NSString *kDocumentTypeTIFF = @"TIFF";
static NSString *kDocumentTypeDictionary = @"Dictionary";
static NSString *kDocumentTypeSTPNGImport = @"STPNGImport";
static NSString *kAFPSDImportBundleName	= @"AFPSDImport";
static NSString *kAFPSDImportBundleExtension = @"app";
static NSString *kAFPSDImportBundleCLIToolXee = @"afpsdcli";
static NSString *kAFPSDImportBundleCLIToolImageMagick = @"afmagickcli";
static NSString *kAFPSDImportPrototypeDocumentName = @"DefaultPrototypeDocument";
static NSString *kAFPSDImportPrototypeSceneName = @"DefaultPrototypeScene";
static NSString *kStoryTellingPrototypeAssetName = @"DefaultPrototypeAsset";
static NSString *kStoryTellingPrototypeEmptyDocumentName = @"DefaultEmptyStoryTellingPrototypeDocument";

@implementation MyDocument

@synthesize stageArrayController;
@synthesize scenarioController;
@synthesize playableArrayController;
@synthesize sceneArrayController;
@synthesize assetArrayController;
@synthesize keyframeAnimationController;
@synthesize keyframeArrayController;
@synthesize unionOfSceneKeyframesArrayController;
@synthesize editorWindow;
@synthesize statusDisplay, statusDisplayToolbarItem;
@synthesize physicsSwitchToolbarItem, physicsSwitch;
@synthesize progressSheet;
@synthesize progressTitleField;
@synthesize progressIndicator;
@synthesize stageEditorViewController;
@synthesize stageEditorViewPlaceholder;
@synthesize importTaskWrapper;
@synthesize disableObserversCount;
@synthesize previewController;

@synthesize psdImportScale = _psdImportScale;
@synthesize editorWindowDragTypes = _editorWindowDragTypes;

#pragma mark -
#pragma mark Candidates for refactoring

// located here because it is addressed via representedObject from CanvasSceneView
// could move into a dedicated model manager

// Is the created object autoreleased?
// If so, the method must be renamed
// BK: I don't think so - this is not CF Level - Cocoa rules are: alloc new (mutable)[cC]opy 
// It should also return the created object

// used by drag code and by the MergeDocumentsWizardController
- (void)createAssetFromDragData:(AssetDragVO *)dragData atPoint:(CGPoint)aPoint {
	NSError *error = nil;
	AssetMO *asset = [[self objectsFromPlistResourceNamed: kStoryTellingPrototypeAssetName error: &error] lastObject];
	
	if( nil == asset ) {
		NSLog(@"could not create prototype asset: %@", error);
		[self presentError: error];
	} else {
		asset.name = dragData.name;
		
		switch (dragData.type) {
			case AssetDragVOTypeImage:
				asset.kind = [NSNumber numberWithInteger:AssetMOKindImage];
				break;
			case AssetDragVOTypeVideo:
				asset.kind = [NSNumber numberWithInteger:AssetMOKindVideo];
				break;
		}
		
		NSDictionary *externalDataProperties = ER_DICT(
													   @"keyName", kSTEBlobRefKeyPrimary,
													   @"externalURL", (id)dragData.externalURL ?: (id)[NSNull null],
   													   @"externalId", (id)dragData.externalId   ?: (id)[NSNull null],
   													   @"contentType", (id)dragData.contentType ?: (id)[NSNull null],
													   );
		
		asset.primaryBlob = [self externalDataWithProperties: externalDataProperties];
		
		asset.viewPosition = [NSNumber numberWithInteger: [MODEL_ACCESS(kModelAccessAssetsKeyPath, nil) count]];	
		[[asset.keyframeAnimation.keyframes anyObject] setValue:[NSValue valueWithCGPoint:aPoint] forKey:@"position"];

		[MODEL_ACCESS(kModelAccessAssetArrayControllerKeyPath, nil) addObject: asset];
	}
	NSLog(@"assetArrayController: %@", self.assetArrayController);
}

// putting it here because it should placed elsewhere after refactoring
- (void)createAssetContainingChildren:(NSArray *)children withName:(NSString*)name {
	NSError *error = nil;
	AssetMO *parentAsset = [[self objectsFromPlistResourceNamed: kStoryTellingPrototypeAssetName error: &error] lastObject];
	if( nil == parentAsset ) {
		NSLog(@"could not create prototype asset: %@", error);
		[self presentError: error];
	} else {
		parentAsset.name = name;
		parentAsset.viewPosition = [NSNumber numberWithInteger: [MODEL_ACCESS(kModelAccessAssetsKeyPath, nil) count]];	
		[[parentAsset.keyframeAnimation.keyframes anyObject] setValue:[NSValue valueWithCGPoint:CGPointZero] forKey:@"position"];
		[MODEL_ACCESS(kModelAccessAssetArrayControllerKeyPath, nil) addObject: parentAsset];
		for (AssetMO *child in children) {
			child.parent = parentAsset;
		}		
	}
}

- (ExternalDataMO *) externalDataWithProperties: (NSDictionary *) properties;
{
	NSError *error = nil;
	
	NSMutableDictionary *mutableProperties = [NSMutableDictionary dictionaryWithDictionary: properties];
	
	[mutableProperties setObject: @"ExternalData" forKey: kObjectExchangeDictionaryRepresentationEntityNameKey];
	
	ExternalDataMO *externalDataMO = [ExternalDataMO objectFromDictionaryRepresentation: mutableProperties inManagedObjectContext: self.managedObjectContext options: nil error: &error];

	if( nil == externalDataMO ) {
		lpdebug(error, error.userInfo);
		[self presentError: error];
	}
	
	lpdebug(externalDataMO);
	
	return externalDataMO;
}

- (BOOL)itemsMayBeGrouped:(NSArray *)items {
	for (AssetMO *asset in items) {
		if (asset.parent != nil) return NO;
	}
	return YES;
}

- (void) makeCurrentInAppDelegate: (BOOL) active
{
	[[[NSApp delegate] valueForKey: @"assetEditorController"] setValue: active ? self.stageEditorViewController.assetEditor : nil forKey: @"content"];
}

// for debugging
- (void) objectsDidChange: (NSNotification *) n
{
	[[n.userInfo objectForKey: NSUpdatedObjectsKey] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
	}];
}


#pragma mark -
#pragma mark Construction

- (void)awakeFromNib
{	
	[statusDisplayToolbarItem setView:statusDisplay];
	[statusDisplayToolbarItem setMinSize:NSMakeSize(415, 40)];
	[physicsSwitchToolbarItem setView:physicsSwitch];
	[physicsSwitchToolbarItem setMinSize:NSMakeSize(96, 21)];	
}

- (NSString *)windowNibName 
{
    return [[NSApp currentEvent] modifierFlags] & NSControlKeyMask ? @"DebugDocument" : @"StoryTellingDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController 
{
    [super windowControllerDidLoadNib:windowController];
		
	// for re-import dragging of stpngimport files 
	self.editorWindowDragTypes = [NSArray arrayWithObjects: (id)kUTTypeFileURL, nil];
	// disabled, not yet done [[windowController window] registerForDraggedTypes: self.editorWindowDragTypes];

	NSArray *nameSortDescriptors = [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES]];
	NSArray *sceneViewPositionSortDescriptors = [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"viewPosition" ascending: YES]];
	NSArray *assetViewPositionSortDescriptors = [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"viewPosition" ascending: NO]];
	NSArray *timeSortDescriptors = [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"time" ascending: YES]];

	[self.stageArrayController setSortDescriptors: nameSortDescriptors];
	[self.sceneArrayController setSortDescriptors: sceneViewPositionSortDescriptors];
	[self.assetArrayController setSortDescriptors: assetViewPositionSortDescriptors];
	[self.keyframeArrayController setSortDescriptors: timeSortDescriptors];

	//self.stageEditorViewController = [[StageEditorViewController viewControllerReplacingPlaceholderView: stageEditorViewPlaceholder mainArrayControllerKeyPath: kModelAccessSceneArrayControllerKeyPath] retain];
	self.stageEditorViewController = [[StageEditorViewController viewControllerReplacingPlaceholderView: stageEditorViewPlaceholder] retain];
	
	[self enableObservers];
	
	[self performSelector:@selector(postInit) withObject:nil afterDelay:0.0];
	
	// [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(objectsDidChange:) name: NSManagedObjectContextObjectsDidChangeNotification object: nil];
}

- (void)postInit {
//	[self setDocumentSettingsDate];
}

- (void)setDocumentSettingsDate {
}

- (id)init
{
	if (self = [super init]){
		_playTimer = nil;
		disableObserversCount = 1; // initially disabled

		_psdImportScale = [[NSUserDefaults standardUserDefaults] doubleForKey: @"psdImportScale"];
		if( fabs(_psdImportScale) < 0.01 ) {
			_psdImportScale = 1.0;
		}
		NSLog(@"psdImportScale: %.3lf", _psdImportScale);
	}
	return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError {
	if (self = [super initWithType:typeName error:outError]) {
		NSError *error = nil;
		
		NSArray *objectsRead = nil;
		
		NSManagedObjectContext *moc = [self managedObjectContext];

		[moc processPendingChanges];
		[[moc undoManager] disableUndoRegistration];
		
		objectsRead = [self objectsFromPlistResourceNamed: kStoryTellingPrototypeEmptyDocumentName error: &error];
		
		[moc processPendingChanges];
		[[moc undoManager] enableUndoRegistration];
		
		if( nil == objectsRead ) {
			[NSApp presentError: error];
		}		
	}
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if( YES == [typeName isEqualToString: kDocumentTypePSD] || 
		YES == [typeName isEqualToString: kDocumentTypeTIFF] ||
		YES == [typeName isEqualToString: kDocumentTypeDictionary] ||		
		YES == [typeName isEqualToString: kDocumentTypeSTPNGImport] 
		) {

		Class myClass = [self class];

		[self release]; // we are re-birthing as a default document and then import the data
		self = [[myClass alloc] init];
				
		if( ( nil != self ) ) {

			if( NO == [self readFromURL: absoluteURL ofType: typeName error: outError] ) {
				[self release];
				self = nil;
			}
		}
		
		return self;
	}

	// Display alert if migration will occur
	BOOL isMigrationNecessary = [self isMigrationNecessaryForURL:absoluteURL ofType:typeName];	
	if (isMigrationNecessary == YES) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"Öffnen"];
		[alert addButtonWithTitle:@"Abbruch"];
		[alert setMessageText:@"Aktualisierung des Dokuments notwendig"];
		NSString *backupDocumentName = [NSString stringWithFormat:@"%@~%@", 
										[[[absoluteURL path] lastPathComponent] stringByDeletingPathExtension], 
										[[absoluteURL path] pathExtension]];
		
		NSString *txt = [NSString stringWithFormat:@"Sie öffnen ein Dokument, das mit einer älteren Version des StoryTellingEditors erstellt wurde.\n\nWenn sie fortfahren, wird das Dokument aktualisiert und Sie können es danach nicht mehr mit der älteren Version des StoryTellingEditors öffnen.\n\nEine Sicherheitskopie der alten Version wird unter\n\"%@\" abgelegt.", backupDocumentName];
		[alert setInformativeText:txt];
		[alert setAlertStyle:NSWarningAlertStyle];

		if ([alert runModal] == NSAlertFirstButtonReturn) {
			return [super initWithContentsOfURL: absoluteURL ofType: typeName error: outError];	
		} else {
			*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
			return nil;
		}
	}		
	return [super initWithContentsOfURL: absoluteURL ofType: typeName error: outError];	
}

- (BOOL)isMigrationNecessaryForURL:(NSURL*)sourceStoreURL ofType:(NSString*)sourceStoreType {
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	NSError *error = nil;
	NSDictionary *sourceMetadata =
    [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:sourceStoreType
															   URL:sourceStoreURL
															 error:&error];	
	if (sourceMetadata == nil) {
		// TODO: deal with error
		lpdebug(@"sourceMetadata is nil");
	}
	
	lpdebug(sourceMetadata);
	
	NSString *configuration = nil;
	NSManagedObjectModel *destinationModel = [psc managedObjectModel];
	BOOL pscCompatibile = [destinationModel isConfiguration:configuration compatibleWithStoreMetadata:sourceMetadata];
	
	return (pscCompatibile == YES)?NO:YES;
}



#pragma mark -
#pragma mark Destruction

- (void) close
{
	NSLog(@"close %@", self);
#if TOGGLE_OBSERVERS
	[self disableObservers];
#endif
	[super close];
}

- (void) dealloc
{
	NSLog(@"dealloc %@", self);

	// [[NSNotificationCenter defaultCenter] removeObserver: self];	
	
	[self disableObservers];

	[stageArrayController release];
	[scenarioController release];
	[playableArrayController release];
	[sceneArrayController release];
	[assetArrayController release];
	[keyframeArrayController release];
	[unionOfSceneKeyframesArrayController release];
	
	[progressTitleField release];
	[progressIndicator release];
	[progressSheet release];

	[statusDisplayToolbarItem release];
	[statusDisplay release];
	[editorWindow release];
	[_editorWindowDragTypes release];

	[previewController release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Window delegate methods

- (void) windowDidBecomeMain: (NSNotification *) notification {
	[self makeCurrentInAppDelegate: YES];
}

- (void) windowDidResignMain: (NSNotification *) notification {
	[self makeCurrentInAppDelegate: NO];
}

- (void) windowWillClose: (NSNotification *) notification {
	[self makeCurrentInAppDelegate: NO];
}

#pragma mark -
#pragma mark Window delegate methods (Drag n Drop)

- (NSURL *) _fileURLFromDraggingInfo: (id <NSDraggingInfo>) draggingInfo
{
	NSPasteboard *pboard = [draggingInfo draggingPasteboard]; 

	NSString *type = [pboard availableTypeFromArray: self.editorWindowDragTypes];
	NSString *draggedURLText = nil;
	if( nil != type ) {
		draggedURLText = [pboard stringForType: type];
	} 

	NSLog(@"url: %@ types: %@", draggedURLText, [pboard types]);


	return draggedURLText ? [NSURL URLWithString: draggedURLText] : nil;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender{
	return [[[self _fileURLFromDraggingInfo: sender] pathExtension] isEqualToString: @"stpngimport"] ? NSDragOperationLink /* for the link arrow */ : NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{

	NSURL *draggedFileURL = [self _fileURLFromDraggingInfo: sender];
	BOOL success = NO;
	NSError *error = nil;
	
	if( nil != draggedFileURL ) {
		//success = [self reimportFromURL: draggedFileURL ofType: kDocumentTypeSTPNGImport error: &error];
		if( NO == success ) {
			[self presentError: error];
		}
	} else {
		SET_NSERROR_REASON(&error, NSPOSIXErrorDomain, EINVAL, @"EXPECTED_FILE_URL_GOT_NONE");
		[self presentError: error];
	}

	return success;
}

#pragma mark -
#pragma mark Controlling observers
- (void) enableObservers
{
	NSLog(@"%@", tracerBacktraceAsString(0));
	if( self.disableObserversCount == 1 ) { 
		NSLog(@"enabling observers");
		[self.stageEditorViewController bind:@"representedObject" toObject: self withKeyPath: @"self" options: nil];
		
		self.disableObserversCount = self.disableObserversCount - 1;
		
	} else {
		NSLog(@"ignoring enableObservers - disableCount: %ld", (long) self.disableObserversCount);
	}
}

- (void) disableObservers
{
	NSLog(@"%@", tracerBacktraceAsString(0));
	[[self class] cancelPreviousPerformRequestsWithTarget: self selector: @selector(enableObservers) object: [NSNull null]];

	if( 0 == self.disableObserversCount ) {
		NSLog(@"disabling observers");
		[self.stageEditorViewController unbind: @"representedObject"];
		[self.stageEditorViewController setRepresentedObject: nil];
		self.disableObserversCount = self.disableObserversCount + 1;
	} else {
		NSLog(@"ignoring disableObservers - disableCount: %ld", (long) self.disableObserversCount);
	}
}

#pragma mark -
#pragma mark Actions and friends

#pragma mark -
#pragma mark Physics stuff

- (IBAction)togglePhysicsMode:(id)sender {
	NSSegmentedControl *seg = sender;
	
	BOOL canSwitch = [self documentHasKeyframeAnimationsOrMultipleScenes]==NO?YES:NO;
	for (AssetMO *asset in [assetArrayController arrangedObjects]) {
		if ([[asset keyframes] count] > 1) {
			canSwitch = NO;
			break;
		}
	}				
	if (canSwitch == NO) {
		[seg setSelectedSegment:SwitchModeOff];
		StageMO *stage = MODEL_ACCESS(kModelAccessStageSelectionKeyPath, @"self");
		if( NSNoSelectionMarker == stage ) return;
		[stage setValue:[NSNumber numberWithBool:NO] forKey:@"physicsEnabled"];			
		NSBeginCriticalAlertSheet(@"Umschalten nicht möglich.", 
									@"OK", 
									nil, nil, [NSApp keyWindow], self, 
									@selector(sheetDidEnd:returnCode:contextInfo:), 
									@selector(sheetDidDismiss:returnCode:contextInfo:), nil,
									@"Um in den Physik-Modus zu wechseln, darf das Dokument nur eine Szene enthalten. Weiterhin dürfen keine Animationen (mehr als ein Keyframe pro Asset) vorhanden sein.");
		return;
	}				
	
	StageMO *stage = MODEL_ACCESS(kModelAccessStageSelectionKeyPath, @"self");
	BOOL physicsEnabled = !NSIsControllerMarker(stage) && [[stage valueForKey:@"physicsEnabled"] boolValue];
		
	[[[self.stageEditorViewController.timelineViewController timeline] gridView] setEnabled:!physicsEnabled];
//	[self.stageEditorViewController.timelineViewController.splitView setPosition:pos ofDividerAtIndex:0];
}

- (BOOL)documentHasKeyframeAnimationsOrMultipleScenes {
	BOOL multiple = ([[self.sceneArrayController arrangedObjects] count] != 1);
	for (AssetMO *asset in [assetArrayController arrangedObjects]) {
		if ([[asset keyframes] count] > 1) {
			multiple = YES;
			break;
		}
	}				
	return multiple;		
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
}


- (NSInteger)lastFrame {
  NSInteger lastFrame = 0;
	NSInteger t = 0;
  for (AssetMO *asset in [assetArrayController arrangedObjects]) {
    if ([[asset hidden] boolValue]) continue;
	  t = [asset range].length + [asset range].location;
    lastFrame = fmax(lastFrame, t);
  }
  return lastFrame;
}

- (IBAction)rewind:(id)sender{
	NSNumber *theTime = [NSNumber numberWithInteger: 0];
	[self.stageEditorViewController.sceneViewController setCurrentTime: theTime];
}

- (IBAction)play:(id)sender{
	NSInteger currentTime = [self.stageEditorViewController.sceneViewController.currentTime 
		integerValue];
	if ([self lastFrame] - 1 == currentTime){
		self.stageEditorViewController.sceneViewController.currentTime = [NSNumber numberWithInt:0];
	}
	
	if (_playTimer){
		[_playTimer invalidate];
		_playTimer = nil;
		[self updatePlayButton];
		return;
	}
	_playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/25.0f target:self 
		selector:@selector(doPlay:) userInfo:[NSNumber numberWithInt:[self lastFrame]] repeats:YES];
	[self updatePlayButton];
}

- (void)doPlay:(NSTimer *)aTimer{
	NSInteger theLastFrame = [[aTimer userInfo] integerValue];
	NSInteger currentTime = [self.stageEditorViewController.sceneViewController.currentTime 
		integerValue];
	if (currentTime + 1 >= theLastFrame){
		[_playTimer invalidate];
		_playTimer = nil;
		[self updatePlayButton];
		return;
	}
	NSNumber *theTime = [NSNumber numberWithInteger: currentTime + 1];
	[self.stageEditorViewController.sceneViewController setCurrentTime: theTime];
//	self.assetEditor.currentTime = theTime;	
}

- (void)updatePlayButton{
	if (_playTimer){
		[playButton setImage:[NSImage imageNamed:@"maintoolbar-icon-pause.png"]];
	}else{
		[playButton setImage:[NSImage imageNamed:@"maintoolbar-icon-play.png"]];
	}
}

- (IBAction) test: (id) sender
{
	NSLog(@"sac: %@", [self.sceneArrayController sortDescriptors]);
}

- (IBAction) producePageLayoutData: (id) sender
{
	BOOL normalizeCoordinates = YES;
	StageMO *stage = MODEL_ACCESS(kModelAccessStageSelectionKeyPath, @"self");
	CGSize pageSize = CGSizeZero;
	NSString *tmpDir = NSTemporaryDirectory();
	
	if (stage) {
		pageSize = CGSizeMake([[stage valueForKey: @"pageWidth"] floatValue],
							   [[stage valueForKey: @"pageHeight"] floatValue]);							   

		if( pageSize.width <= 0 || pageSize.height <= 0) { 
			pageSize = CGSizeMake([[stage valueForKey: @"width"] floatValue],
								[[stage valueForKey: @"height"] floatValue]);
		}
	}
	
	if( pageSize.width <= 0 || pageSize.height <= 0) { 
		pageSize = CGSizeMake(1, 1); // to avoid div by zero, equal to no scaling 
	}
	
	NSString *basePath = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"css"];
	basePath = [basePath stringByDeletingLastPathComponent];
	//NSString *logoPath = [[NSBundle mainBundle] pathForResource:@"aflogo" ofType:@"png"];
	NSMutableString *HTML = [NSMutableString stringWithFormat:	
							 @"<%%@page contentType=\"text/html\" pageEncoding=\"UTF-8\"%%>" \
							 "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"" \
							 "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">" \
							 "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">" \
							 "<head>" \
							 "<title>StoryTelling Editor</title>" \
							 "<link href=\"%@/main.css\" type=\"text/css\" rel=\"stylesheet\" />" \
							 "</head>" \
							 "<body\">" \
							 "<div id=\"container\">" \
							 "<h1>Layout data &amp; export statistics</h1>", basePath, basePath, basePath, basePath, basePath];
	
	[HTML appendString: @"<form><table>"];
	
	[HTML appendFormat: @"<tr><th>%@</th><th>%@</th><th>%@</th><th>%@</th><th>%@</th><th>%@</th><th>%@</th><th>%@</th></tr>",	
				@"zPosition",
				@"Name",
				@"xOffset", 
				@"yOffset",
				@"width",
				@"height",
				@"size k",
				@"LayerImage"				
		];
	
	unsigned long long totalImageFileSize = 0;
	NSMutableString *chartValues = [NSMutableString stringWithString:@"["];
	NSMutableString *legendValues = [NSMutableString stringWithString:@"["];
	
	NSArray *assets = MODEL_ACCESS(kModelAccessAssetsKeyPath, nil);
	int assetCounter = 0;
	
	for( AssetMO *asset in assets ) {
		NSArray *orderedKeyframes = [asset valueForKeyPath: @"keyframeAnimation.orderedKeyframes"];

		if( [orderedKeyframes count] < 1 ) {
			NSLog(@"%@ WARNING !!!! - accessing layer (%@) without keyframes", [self class], asset);
			return;
		}

		KeyframeMO *kf = [orderedKeyframes objectAtIndex: 0]; 
		
		CGPoint position = [[kf valueForKey: @"position"] CGPointValue];
		CGRect bounds = [[kf valueForKey: @"bounds"] CGRectValue];
		
		if (normalizeCoordinates) {
			position.x /= pageSize.width;
			position.y /= pageSize.height;
			bounds.size.width /= pageSize.width;
			bounds.size.height /= pageSize.height;
		}

		NSString *imageURLString = nil;
		
		[asset.primaryBlob.mediaContainer updateRenderings];
		unsigned long long fileSize = [asset.primaryBlob.mediaContainer.renderedData length];
		imageURLString = [asset.primaryBlob.mediaContainer.renderedURL absoluteString];
		

		totalImageFileSize += fileSize;
		
		[HTML appendFormat: @"<tr><td><input size=\"2\" type=\"text\" value=\"%@\"></td>" \
		 "<td><input size=\"25\" type=\"text\" value=\"%@\"></td>" \
		 "<td><input size=\"8\" type=\"text\" value=\"%.4f\"></td>" \
		 "<td><input size=\"8\" type=\"text\" value=\"%.4f\"></td>" \
		 "<td><input size=\"8\" type=\"text\" value=\"%.4f\"></td>" \
		 "<td><input size=\"8\" type=\"text\" value=\"%.4f\"></td>" \
		 "<td><input size=\"8\" type=\"text\" value=\"%.4f\"></td>" \
		 "<td>" \
		 "<a href=\"%@\"><img src=\"%@\" width=\"128\"/></a></td></tr>",	
				asset.viewPosition,
				asset.name,
				position.x, position.y,
				CGRectGetWidth(bounds), CGRectGetHeight(bounds),
				(float)fileSize / 1000,
				imageURLString,
				imageURLString
		];
		[chartValues appendFormat:@"%.2f", (float)fileSize / 1000];
		[legendValues appendFormat:@"\"%%%%.%%%% - %@\"", asset.name];
		if ([assets count]-1 > assetCounter) {
			[chartValues appendString:@", "];
			[legendValues appendString:@", "];			
		}
		assetCounter++;
		//[mediaContainer release];

	}

	[HTML appendFormat: @"<tr><td><strong>Total file size (images): %f</strong></td></tr>", (float)totalImageFileSize / 1000];
	[HTML appendString: @"</table></form>"];
	[HTML appendString: @"</div>"];
	[HTML appendString: @"<div id=\"piechart\"></div>"];
	
	[chartValues appendString:@"]"];
	[legendValues appendString:@"]"];
	
	[HTML appendString: @"<script type=\"text/javascript\">"];
	[HTML appendString: @"var pie = null;"];
	[HTML appendString: @"function chart() {"];
	[HTML appendString: @"var r = Raphael(\"piechart\", 640, 200);"];
	[HTML appendFormat: @"pie = r.g.piechart(100, 100, 100, %@, {legend: %@, legendpos: 'east'});", chartValues, legendValues];
	[HTML appendString: @"}"];
	[HTML appendString: @"</script>"];
	
	//[HTML appendFormat:@"<br/><img src=\"%@\" alt=\"Artifacts\">", logoPath];
	[HTML appendString: @"<br/></body></html>"];

	NSString *HTMLFile = [tmpDir stringByAppendingFormat: @"PageLayout-%.1lf.html", [NSDate timeIntervalSinceReferenceDate]];

	NSError *error = nil;

	if( NO == [HTML writeToFile: HTMLFile atomically: YES encoding: NSUTF8StringEncoding error: &error] ) {
		[NSApp presentError: error];
	} else {
		[[NSWorkspace sharedWorkspace] openFile: HTMLFile];
	}
}


#pragma mark -
#pragma mark CoreData versioning

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL*)url 
										   ofType:(NSString*)fileType
							   modelConfiguration:(NSString*)configuration
									 storeOptions:(NSDictionary*)storeOptions
											error:(NSError**)error {
	NSMutableDictionary *options = nil;
	if (storeOptions != nil) {
		options = [storeOptions mutableCopy];
	} else {
		options = [[NSMutableDictionary alloc] init];
	}
	
	[options setObject:[NSNumber numberWithBool:YES] 
				forKey:NSMigratePersistentStoresAutomaticallyOption];
//	[options setObject:[NSNumber numberWithBool:YES]
//				forKey:NSInferMappingModelAutomaticallyOption];
	
	BOOL result = [super configurePersistentStoreCoordinatorForURL:url
															ofType:fileType
												modelConfiguration:configuration
													  storeOptions:options
															 error:error];
	[options release], options = nil;
	return result;
}


- (void)document:(NSDocument *)doc didSaveForBackwardCompatibleCopy:(BOOL)didSave contextInfo:(void  *)contextInfo
{
	lpkdebug("backwardCompatibleMigration", didSave);

	if( NO == didSave ) {
		return;
	}

	NSError *error = nil;

	NSBundle *classBundle = [NSBundle bundleForClass: [self class]];

	NSArray *modelBundles = [NSArray arrayWithObject: classBundle];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString *backwardCompatibleModel = [defaults valueForKey: kSTEBackwardCompatibleModel];
	NSString *backwardCompatibleVersionSuffix = [defaults valueForKey: kSTEBackwardCompatibleVersionSuffix];
	NSString *backwardCompatibleFileType = [backwardCompatibleVersionSuffix pathExtension];

	if( NO == CHECK_NSERROR_REASON(nil != backwardCompatibleModel && nil != backwardCompatibleVersionSuffix, 
		&error, NSPOSIXErrorDomain, ENOENT, @"errorMissingConfigurationForBackwardCompatibleSave") ) {
		lpkdebug("backwardCompatibleMigration", error);
		[self presentError: error];
		return;
	}

	NSString *sourceType = [self persistentStoreTypeForFileType: [self fileType]];
	NSString *destinationType = [self persistentStoreTypeForFileType: backwardCompatibleFileType];

	lpkdebug("backwardCompatibleMigration", backwardCompatibleModel, backwardCompatibleVersionSuffix, backwardCompatibleFileType, sourceType, destinationType);

	NSString *destinationModelPath = [[classBundle resourcePath] stringByAppendingPathComponent: backwardCompatibleModel];

	NSManagedObjectModel *destinationModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: destinationModelPath]] autorelease];
	
	if( NO == CHECK_NSERROR_REASON(nil != destinationModel, &error, NSPOSIXErrorDomain, ENOENT, @"errorNoDestinationModelForBackwardCompatibleSave") ) {
		lpkdebug("backwardCompatibleMigration", error);
		[self presentError: error];
		return;
	}
	
	NSManagedObjectModel *sourceModel = [self managedObjectModel];

	NSSet *sourceVersionIdentifiers = [sourceModel versionIdentifiers];
	NSSet *destinationVersionIdentifiers = [destinationModel versionIdentifiers];

	lpkdebug("backwardCompatibleMigration", sourceVersionIdentifiers, destinationVersionIdentifiers);

	if( NO == CHECK_NSERROR_REASON(1 == [sourceVersionIdentifiers count], &error, NSPOSIXErrorDomain, ENOENT, @"errorSourceModelForBackwardCompatibleSaveHasNotExactlyOneVersionIdentifier") ) {
		lpkdebug("backwardCompatibleMigration", error);
		[self presentError: error];
		return;
	}
	
	if( NO == CHECK_NSERROR_REASON(1 == [destinationVersionIdentifiers count], &error, NSPOSIXErrorDomain, ENOENT, @"errorSourceModelForBackwardCompatibleSaveHasNotExactlyOneVersionIdentifier") ) {
		lpkdebug("backwardCompatibleMigration", error);
		[self presentError: error];
		return;
	}

	NSMigrationManager *migrationManager = [[[NSMigrationManager alloc] initWithSourceModel: sourceModel destinationModel: destinationModel] autorelease];

	NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles: modelBundles forSourceModel: sourceModel destinationModel: destinationModel];

	if( NO == CHECK_NSERROR_REASON(nil != mappingModel, &error, NSPOSIXErrorDomain, ENOENT, @"errorNoMappingModelForBackwardCompatibleSave") ) {
		lpkdebug("backwardCompatibleMigration", error);
		[self presentError: error];
		return;
	}
	
	NSURL *currentURL = [self fileURL];

	lpkdebug("backwardCompatibleMigration", currentURL);
	
	NSString *path = [currentURL path];
	
	NSURL *destinationURL = [NSURL fileURLWithPath: [[path stringByDeletingPathExtension] stringByAppendingString: backwardCompatibleVersionSuffix]];

	lpkdebug("backwardCompatibleMigration", destinationURL);
	
	if( NO == [migrationManager migrateStoreFromURL: currentURL type: sourceType options: nil withMappingModel: mappingModel toDestinationURL: destinationURL destinationType: destinationType destinationOptions: nil error: &error] ) {
		lpkdebug("backwardCompatibleMigration", error);
	}
}

- (IBAction) saveDocumentAndCreateBackwardCompatibleCopy: (id) sender
{
	[self saveDocumentWithDelegate: self didSaveSelector: @selector(document:didSaveForBackwardCompatibleCopy:contextInfo:) contextInfo: NULL];
}


#pragma mark -
#pragma mark Undo utilities


- (BOOL) enableUndo: (BOOL) shouldEnableUndo
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSUndoManager *undoManager = [moc undoManager];
	BOOL wasUndoRegistrationEnabled = [undoManager isUndoRegistrationEnabled];
	
	if ( wasUndoRegistrationEnabled != shouldEnableUndo ) {
		[moc processPendingChanges];
		[[moc undoManager] performSelector: shouldEnableUndo ? @selector(enableUndoRegistration) : @selector(disableUndoRegistration)];	
	}

	return wasUndoRegistrationEnabled;
}

#pragma mark -
#pragma mark Housekeeping

#define kSTEConsistencyCheckOptionConfigured	0x01
#define kSTEConsistencyCheckOptionRun			0x02
#define kSTEConsistencyCheckOptionShow			0x04
#define kSTEConsistencyCheckOptionAsk			0x08
#define kSTEConsistencyCheckOptionFix			0x10
#define kSTEConsistencyCheckOptionSend			0x20

- (NSUInteger) consistencyCheckOptionsFromString: (NSString *) optionsString
{
	NSArray *optionList = [optionsString componentsSeparatedByString: kSTEConsistencyCheckOptionSeparator];

	NSUInteger options = 0;
	
	if( [optionList count] > 0 ) {
		options = 
		kSTEConsistencyCheckOptionRun * [optionList containsObject: kSTEConsistencyCheckOptionRunKey] |
		kSTEConsistencyCheckOptionFix * [optionList containsObject: kSTEConsistencyCheckOptionFixKey] |
		kSTEConsistencyCheckOptionAsk * [optionList containsObject: kSTEConsistencyCheckOptionAskKey] |
		kSTEConsistencyCheckOptionShow * [optionList containsObject: kSTEConsistencyCheckOptionShowKey] |
		kSTEConsistencyCheckOptionSend * [optionList containsObject: kSTEConsistencyCheckOptionSendKey] |
		kSTEConsistencyCheckOptionConfigured;
	}

	return options;
}


- (BOOL) consistencyCheckOrphanedObjectsForDocumentFromURL: (NSURL *) URL error: (NSError **) outError
{	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSDictionary *checks = [defaults dictionaryForKey: kSTEConsistencyCheckOrphanRelations];
	
	NSUInteger options = [self consistencyCheckOptionsFromString: [defaults stringForKey: kSTEConsistencyCheckOrphan]];

	if( !( options & kSTEConsistencyCheckOptionRun ) || 0 == [checks count] ) {
		return YES;
	}
	
	NSManagedObjectContext *moc = [self managedObjectContext];
	
	for( int iteration = 0 ; iteration < 3 ; ++iteration ) {
		
		NSMutableString *messages = [NSMutableString stringWithFormat: NSLocalizedString(@"alertConsistencyCheckIteration %ld\n", @""), (long)iteration];
		
		NSMutableArray *orphans = [NSMutableArray array];
		
		for( NSString *entityName in checks ) {
			NSString *ownerRelationshipName = [checks valueForKey: entityName];
			
			lpkdebug("consistency,heavy", entityName, ownerRelationshipName);
			
			NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];  
			NSEntityDescription *entity = [NSEntityDescription entityForName: entityName inManagedObjectContext: moc];  
			NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(%K == nil)", ownerRelationshipName];
			
			[fetchRequest setPredicate: fetchPredicate];
			[fetchRequest setEntity: entity];       
			
			NSError *error = nil;
			NSArray *fetchResults = [moc executeFetchRequest:fetchRequest error: &error];
			
			if( nil == fetchResults ) {
				lpkerror("consistency", error);
				if( nil != outError ) {
					*outError = error;
				}
				return NO;
			}
			
			NSInteger count = [fetchResults count];

			for( NSManagedObject *object in fetchResults ) {
				lpkdebugf("consistency,heavy", "Orphaned %@ %@", entityName, [object respondsToSelector: @selector(name)] ? [object valueForKey: @"name"] : @"");
			}
			
			if( 0 != count ) {
				 [messages appendFormat: NSLocalizedString(@"alertOrphanedObjects: %ld ofType %@ without %@\n", @"repeating part of alert box message"), (long) count, entityName, ownerRelationshipName];
				 [orphans addObjectsFromArray: fetchResults];
			}
		}	 

		lpinfo(iteration, [orphans count]);
		
		if( 0 != [orphans count] ) {
			
			BOOL doFix = ( options & kSTEConsistencyCheckOptionFix ) ? YES : NO;
			
			if( options & kSTEConsistencyCheckOptionAsk ) {
				doFix = ( NSAlertDefaultReturn == NSRunCriticalAlertPanel(
														   NSLocalizedString(@"alertTitleDocumentFailedConsistencyCheck", @""), 
														   @"%@", 
														   NSLocalizedString(@"buttonDeleteOrphans_harmless", @""), 
														   NSLocalizedString(@"buttonIgnoreOrphans", @""), 
														   nil, 
														   messages));
			} else {
				if( NO == doFix && ( options & kSTEConsistencyCheckOptionShow ) ) {
					NSRunInformationalAlertPanel(NSLocalizedString(@"alertTitleDocumentFailedConsistencyCheck", @""), @"%@", NSLocalizedString(@"buttonIgnoreOrphans", @""), nil, nil, messages);
				}	
			}
				
			if( doFix ) {
				
				BOOL undoWasEnabled = [self enableUndo: NO];
				
				for(NSManagedObject *object in orphans ) {
					[moc deleteObject: object];
				}
				
				[self enableUndo: undoWasEnabled];
				
				if( options & kSTEConsistencyCheckOptionShow ) {
					NSRunInformationalAlertPanel(NSLocalizedString(@"alertTitleOrphansRemoved", @""), NSLocalizedString(@"alertTotalObjectsRemoved_includingChildren: %ld", @""), NSLocalizedString(@"buttonOK", @""), nil, nil, [[moc deletedObjects] count]);
				}
				
				if( options & kSTEConsistencyCheckOptionSend ) {
					[[NSApp storyTellingEditorDelegate] mailto: nil subject: @"orphaned objects" body: messages];
				}
			} else { // ! doFix
				break;
			}
			
		} else { // ! orphans count 
			break; 
		}

	} // for iteration
				 
	return YES;
}


- (BOOL) consistencyCheckForDocumentFromURL: (NSURL *) URL error: (NSError **) outError
{
	BOOL success = YES;
	NSError *localError = nil;
	
	success = [self consistencyCheckOrphanedObjectsForDocumentFromURL: URL error: &localError];

	if( NO == success ) {
		[NSApp presentError: localError];
	}
	
	// don't stop loading - try as hard as we can
	
	return YES;
}

#pragma mark -
#pragma mark Saving

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	NSString *path = [[absoluteURL path] stringByDeletingLastPathComponent];
	BOOL isLocal = [FileUtil isLocalFile:path];
	CHECK_NSERROR_REASON_RETURN_NO(isLocal == YES, outError, NSPOSIXErrorDomain, EDEADLK, @"errorSavingToNonLocalVolumeProhibited");
		
	return [super writeToURL:absoluteURL ofType:typeName error:outError];	
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError {
	NSString *path = [[absoluteURL path] stringByDeletingLastPathComponent];
	BOOL isLocal = [FileUtil isLocalFile:path];
	CHECK_NSERROR_REASON_RETURN_NO(isLocal == YES, outError, NSPOSIXErrorDomain, EDEADLK, @"errorSavingToNonLocalVolumeProhibited");

	return [super writeToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:outError];
}


#pragma mark -
#pragma mark Document and snippet reading

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName toplevelObjects: (NSArray **) outToplevelObjects error:(NSError **)outError
{
	BOOL success = NO;

	if( [typeName isEqualToString: kDocumentTypeDictionary] || [typeName isEqualToString: kDocumentTypeSTPNGImport] ) {
		NSString *errorDescription = nil;

		// use NSPropertyListMutableContainers to allow for coordinate patching
		id plist = [NSPropertyListSerialization propertyListFromData: data mutabilityOption: NSPropertyListMutableContainers format: nil errorDescription: &errorDescription];

		CHECK_NSERROR_REASON_RETURN_NO(nil != plist, outError, NSPOSIXErrorDomain, EINVAL, @"errorCanNotParseDictionaryRepresentation");

		if( [typeName isEqualToString: kDocumentTypeSTPNGImport] ) {

			[self performSelector: @selector(delayedImportLayerDictionaries:) withObject: plist afterDelay: 0.0];		
			success = YES;
		}

		if( [typeName isEqualToString: kDocumentTypeDictionary] ) {

			NSArray *toplevelObjects =  [[self class] importPlistRepresentation: plist intoManagedObjectContext: [self managedObjectContext] error: outError];

			if( nil != toplevelObjects ) {
				if( nil != outToplevelObjects ) {
					*outToplevelObjects = toplevelObjects;
				}
				success = YES;
			}
		}

	} else {
		success = [super readFromData:data ofType:typeName error:outError];
	}

	return success;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	return [self readFromData: data ofType: typeName toplevelObjects: nil error: outError];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName toplevelObjects: (NSArray **) outToplevelObjects error:(NSError **)outError
{
	BOOL ret = NO;

	if( [typeName isEqualToString: kDocumentTypeDictionary] || [typeName isEqualToString: kDocumentTypeSTPNGImport] ) {

		NSData *data = [NSData dataWithContentsOfURL:absoluteURL options: NSUncachedRead error: outError];

		ret = data ? [self readFromData: data ofType: typeName toplevelObjects: outToplevelObjects error: outError] : NO;
	} else {

		if( [typeName isEqualToString: kDocumentTypePSD] || [typeName isEqualToString: kDocumentTypeTIFF]) {

			// do it a bit later so we have a window and can present a progress sheet
			[self performSelector: @selector(importLayersFromFileAtPath:) withObject: [absoluteURL path] afterDelay: 0.0];
			ret = YES;
			
		} else {
			ret = [super readFromURL:absoluteURL ofType:typeName error:outError];			

			if( YES == ret ) {
				ret = [self consistencyCheckForDocumentFromURL: absoluteURL error: outError];
			}
		}
	}
	
	return ret;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL isLocal = [FileUtil isLocalFileURL:absoluteURL];
	CHECK_NSERROR_REASON_RETURN_NO(isLocal == YES, outError, NSPOSIXErrorDomain, EDEADLK, @"errorOpenFromNonLocalVolumeProhibited");
	
	return [self readFromURL: absoluteURL ofType: typeName toplevelObjects: nil error: outError];
}

// imports plist representations 
// if defined STE_PLIST_COORDINATE_SCALING: with all coordinates (except the stage size) normalized to a 1 by 1 coordinate system
// else just a passthrough
+ (NSArray *) importPlistRepresentation: (NSArray *) plist intoManagedObjectContext: (NSManagedObjectContext *) managedObjectContext error: (NSError **) outError
{
#if STE_PLIST_COORDINATE_SCALING
	// keep it, maybe we need it for pluggable scripts later on
	ObjectExchangeObjectProcessor coordinateScaler = ^(NSManagedObject *obj, NSDictionary *options, NSInteger depth) {
		if([obj isKindOfClass: [SceneMO class]]) {
			SceneMO *scene = (SceneMO *)obj;
			StageMO *stage = scene.scenario.stage;
			CGSize stageSize = CGSizeMake( [stage.width floatValue], [stage.height floatValue] );			
			//NSLog(@"stageSize %@", NSStringFromCGSize(stageSize));

			for( AssetMO *asset in scene.assets ) {
				//NSLog(@"scaling %@", asset.name);
				[asset.keyframeAnimation scaleGeometricPropertiesBy: stageSize];
			}
		} 
	};

	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSArray arrayWithObject: [[coordinateScaler copy] autorelease]], kObjectExchangeObjectProcessors,
							 nil];
#else
	NSDictionary *options = nil;
#endif
	
	NSArray *objects = [NSManagedObject objectsFromDictionaryRepresentations: plist inManagedObjectContext: managedObjectContext options: options error: outError];
		
	return objects;
}

// uses readFromURL, therefore scales normalized coordinates if STE_PLIST_COORDINATE_SCALING is defined
- (NSArray *) objectsFromPlistResourceNamed: (NSString *) name error:(NSError **)outError
{
	NSArray *toplevelObjects = nil;

	NSString *plistPath = [[NSBundle bundleForClass: [self class]] pathForResource: name ofType: @"plist"];

	CHECK_NSERROR_REASON_RETURN_NO(plistPath, outError, NSPOSIXErrorDomain, ENOENT, @"errorPlistResourceNotFound: %@", name);					

	if( NO == [self readFromURL: [NSURL fileURLWithPath: plistPath] ofType: kDocumentTypeDictionary toplevelObjects: &toplevelObjects error: outError] ) {
		return nil;
	}

	return toplevelObjects;
}

#pragma mark -
#pragma mark Scene Prototype creation

- (SceneMO*)createScenePrototype {
	NSError *outError = nil;
	SceneMO *scene = [[self objectsFromPlistResourceNamed: kAFPSDImportPrototypeSceneName error: &outError] lastObject];
	return scene;
}

#pragma mark -
#pragma mark Layer Dictionary Import

- (void) delayedImportLayerDictionaries: (NSArray *) layerDictionaries
{
	NSError *error = nil;
	if( NO == [self importLayerDictionaries: layerDictionaries error: &error] ) {
		[NSApp presentError: error];
	}
}

- (BOOL) importLayerDictionaries: (NSArray * ) layerDictionaries error: (NSError **) outError;
{
	BOOL success = YES;

	NSManagedObjectContext *moc = [self managedObjectContext];

	[moc processPendingChanges];
    [[moc undoManager] disableUndoRegistration];

	StageMO *stage = [self ensureStageAndSceneForImportOfLayerDictionaries: layerDictionaries error: outError];

	// BK: when we start importing into existing documents we should make a decision about undo registration
	// based on whether the above call created a stage or not (it will need a BOOL * argument)

	do {
		if( nil == stage ) {
			success = NO;
			break;
		}

		SceneMO *scene = [[stage valueForKeyPath: @"scenario.playables"] anyObject];

		NSAssert( scene != nil, @"no scene in import");

		NSMutableSet *mutableAssets = [scene mutableSetValueForKey: @"assets"];
		
		for(NSDictionary *layerDictionary in layerDictionaries) {

			if( -1 == [[layerDictionary valueForKey: @"zPosition"] integerValue] ) { // skip composite layer
				continue;
			}
			
			AssetMO *asset = [[self objectsFromPlistResourceNamed: kStoryTellingPrototypeAssetName error: outError] lastObject];
			
			if( nil == asset || NO == [self configureAsset: asset fromLayerDictionary: layerDictionary error: outError] ) {
				success = NO;
				break;
			}
			
			[mutableAssets addObject: asset];
			
			if ([asset.primaryBlob.externalURL length] > 0) {
				NSURL *URL = [NSURL URLWithString: asset.primaryBlob.externalURL];
				if (URL != nil) {
					if ([[AFCache sharedInstance] hasCachedItemForURL:URL]) {
						[[AFCache sharedInstance] purgeCacheableItemForURL:URL];
					}
				}
			}
		}
	} while(0);
		
	[moc processPendingChanges];
    [[moc undoManager] enableUndoRegistration];	
			
	return success;
}

- (StageMO *) ensureStageAndSceneForImportOfLayerDictionaries: (NSArray * ) layerDictionaries error: (NSError **) outError
{
	NSRect documentRect = NSZeroRect;
	NSRect stageRect = NSZeroRect;

	//NSMutableArray *offendingNames = [NSMutableArray array];

	for(NSDictionary *layerProperties in layerDictionaries) {
		NSRect layerRect = NSRectFromString([layerProperties valueForKey: @"frame"]);
		stageRect = NSUnionRect(stageRect,  layerRect);

		if( -1 == [[layerProperties valueForKey: @"zPosition"] integerValue] ) {
			documentRect = layerRect;
		}
	}

#ifdef STE_WARN_ON_NEGATIVE_LAYER_OFFSET	
	if( NSMinX(stageRect) < 0 || NSMinY(stageRect) < 0 ) {
		NSAlert *alert = [NSAlert alertWithMessageText: NSLocalizedString(@"warningPSDImportHasNegativeLayerOffsetsTitle", @"alert box text") defaultButton: NSLocalizedString(@"ignoreAndImportAsIsButtonTitle", @"") alternateButton:  NSLocalizedString(@"auto-correct will follow", @"") otherButton: nil informativeTextWithFormat:
		NSLocalizedString(@"warningPSDImportHasNegativeLayerOffsetsText", @"")];
		[alert runModal];
	}
#endif
	
	if( NO == NSEqualRects( NSZeroRect, documentRect) ) {
		stageRect = documentRect;
	}
	
	double psdImportScale = self.psdImportScale;
	
	stageRect.origin.x *= psdImportScale;
	stageRect.origin.y *= psdImportScale;
	stageRect.size.width *= psdImportScale;
	stageRect.size.height *= psdImportScale;
	
	NSLog(@"stageRect: %@", NSStringFromRect(stageRect));

	
	StageMO *stage = MODEL_ACCESS(kModelAccessStageSelectionKeyPath, @"self");

	if( NSNoSelectionMarker == stage ) {

		NSLog(@"constructing stage");

		stage = [[self objectsFromPlistResourceNamed: kAFPSDImportPrototypeDocumentName error: outError] lastObject];

		if( nil == stage ) {
			return nil;
		}	

		[stage setValue: [NSNumber numberWithInteger: NSWidth(stageRect)] forKey: @"width"];
		[stage setValue: [NSNumber numberWithInteger: NSHeight(stageRect)] forKey: @"height"];
	}

	// returns array, has 1 scene
	SceneMO *scene = [[self objectsFromPlistResourceNamed: kAFPSDImportPrototypeSceneName error: outError] lastObject];

	if( nil == scene ) {
		return nil;
	}

	[[stage.scenario mutableSetValueForKey: @"playables"] addObject: scene];

	return stage;
}

- (BOOL) configureAsset: (AssetMO *) asset fromLayerDictionary: (NSDictionary *) layerDictionary error: (NSError **) outError
{
	CGRect frame = CGRectFromString([layerDictionary valueForKey: @"frame"]);

	double psdImportScale = self.psdImportScale;

	frame.origin.x *= psdImportScale;
	frame.origin.y *= psdImportScale;
	frame.size.width *= psdImportScale;
	frame.size.height *= psdImportScale;
	
	asset.name = [layerDictionary valueForKey: @"name"];

	NSString *externalURL = [layerDictionary valueForKey: @"lastExportURL"];
	
	if( nil == externalURL ) {
		NSString *importPath = [[layerDictionary valueForKey: @"importPath"] stringByExpandingTildeInPath];
		if( nil != importPath ) {
			externalURL = [[NSURL fileURLWithPath: importPath] absoluteString];
		}
	}

	NSDictionary *externalDataProperties = ER_DICT(
												   @"keyName", kSTEBlobRefKeyPrimary,
												   @"externalURL", externalURL,
   												   @"externalId", @"none",
												   @"contentType", (id)kUTTypeImage,
												   );
	
	asset.primaryBlob = [self externalDataWithProperties: externalDataProperties];
		
	asset.viewPosition = [layerDictionary valueForKey: @"zPosition"];

	NSNumber *hidden = [layerDictionary valueForKey: @"hidden"];

	asset.hidden = (nil == hidden) ? [NSNumber numberWithBool: NO] : hidden;

	KeyframeMO *keyframe = [[asset valueForKeyPath: @"keyframeAnimation.keyframes"] anyObject];
	
	[keyframe setValue: [NSValue valueWithCGPoint: frame.origin] forKey: @"position"];

	frame.origin = CGPointZero;
	[keyframe setValue: [NSValue valueWithCGRect: frame] forKey: @"bounds"];

	return YES;
}


- (void) startImportTaskWithCLITool: (NSString *) cliTool arguments: (NSArray *) arguments
{
	NSBundle *myBundle = [NSBundle bundleForClass: [self class]];

	NSString *importerBundlePath = [myBundle pathForResource: kAFPSDImportBundleName ofType: kAFPSDImportBundleExtension];
	NSAssert(nil != importerBundlePath, @"missing importer bundle");

	NSBundle *importerBundle = [NSBundle bundleWithPath: importerBundlePath];
	NSAssert(nil != importerBundle, @"can not create importer bundle");

	NSString *importerCLIToolPath = [importerBundle pathForAuxiliaryExecutable: cliTool];
	NSAssert(nil != importerCLIToolPath, @"can not locate cli tool in importer bundle");

	NSArray *importerArguments = [[NSArray arrayWithObject: importerCLIToolPath] arrayByAddingObjectsFromArray: arguments];
	
	self.importTaskWrapper = [[[TaskWrapper alloc] initWithController: self arguments: importerArguments userInfo: nil] autorelease];
	[self.importTaskWrapper startProcess];
}

- (void) importLayersFromFileAtPath: (NSString *) path
{
	NSString *theCLITool = nil;
	NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	if ([[currentDefaults objectForKey:kSTEUseImageMagick] boolValue] == YES) {
		theCLITool = kAFPSDImportBundleCLIToolImageMagick;
	} else {
		theCLITool = kAFPSDImportBundleCLIToolXee;
	}
	[self startImportTaskWithCLITool: theCLITool arguments: [NSArray arrayWithObject: path]];
}

- (void) startModalProgress: (NSString *) title
{
#if TOGGLE_OBSERVERS
	[self disableObservers];
#endif
	[self.progressTitleField setStringValue: title];
	[self.progressIndicator startAnimation: self];

	[NSApp beginSheet: self.progressSheet modalForWindow: self.editorWindow modalDelegate: self didEndSelector: @selector(progressSheetDidEnd:returnCode:contextInfo:) contextInfo: nil];
}

- (void) progressSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[self.progressIndicator stopAnimation: self];
	[sheet orderOut:self];
}

- (void) endModalProgress
{
	[NSApp endSheet: self.progressSheet];
#if TOGGLE_OBSERVERS
	[self enableObservers];
#endif
}

- (void) processStarted
{
	NSLog(@"processStarted");
	[self startModalProgress: NSLocalizedString(@"psdImportInProgress", @"")];
}


- (void) processFinishedWithStatus: (NSInteger) terminationStatus reason: (NSTaskTerminationReason) terminationReason outputData: (NSData *) outputData errorData: (NSData *) errorData userInfo: (id) info
{
	NSError *error = nil;
	
	BOOL showError = NO;
	BOOL showOutput = NO;
	
	NSString *basename = [NSString stringWithFormat: @"AFImport-%f", [NSDate timeIntervalSinceReferenceDate]];
	
	NSString *errorFile = [NSTemporaryDirectory() stringByAppendingPathComponent: [basename stringByAppendingPathExtension: @"log"]];
	NSString *outputFile = [NSTemporaryDirectory() stringByAppendingPathComponent: [basename stringByAppendingPathExtension: @"plist"]];
	
	NSLog(@"importer finished - status: %ld reason: %ld log: %@ output: %@", (long) terminationStatus, (long) terminationReason, errorFile, outputFile);

	if( NO == [errorData writeToFile: errorFile atomically: YES] || NO == [outputData writeToFile: outputFile atomically: YES] ) {
		SET_NSERROR_REASON(&error, NSPOSIXErrorDomain, EINVAL, @"errorPSDImportCouldNotWriteDebugOutput");			
	} else { 
	
		if( NSTaskTerminationReasonExit == terminationReason && 0 == terminationStatus ) {
			
			NSArray *layerDictionaries = [NSPropertyListSerialization propertyListWithData: outputData options: 0 format: nil error: &error];
			
			if( nil == layerDictionaries ) {
				SET_NSERROR_REASON(&error, NSPOSIXErrorDomain, EINVAL, @"errorPSDImportProducedUnparseableData");
				showError = showOutput = YES;
			} else {
			
				if( 0 == [layerDictionaries count] ) {
					SET_NSERROR_REASON(&error, NSPOSIXErrorDomain, EINVAL, @"errorPSDImportProducedZeroLayers");
					showError = showOutput = YES;
				} else {
					
					if( NO == [self importLayerDictionaries: layerDictionaries error: &error] ) {
						showOutput = YES;
					}
				}
			
			}
			
		} else {
			SET_NSERROR_REASON(&error, NSPOSIXErrorDomain, EINVAL, @"errorPSDImportFailed");
			showError = YES;
		}
	}
		
	[self endModalProgress];
		
	if( nil != error ) {
		[self presentError: error];
	}
		
	if( showOutput || showError ) {
		system([[NSString stringWithFormat: @"open -e %@ %@", showError ? errorFile : @"", showOutput ? outputFile : @""] UTF8String]);
	}
	
	// delay release so we don't destruct our caller
	[self performSelector: @selector(setImportTaskWrapper:) withObject: nil afterDelay: 0.0];
}


@end



