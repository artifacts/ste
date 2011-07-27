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

#import "SceneCollectionViewController.h"
#import "NSArrayController_ObjectExchange.h"
#import "Constants.h"
#import "SceneMO.h"
#import "TransitionMO.h"
#import "StoryTellingEditorAppDelegate.h"
#import "MyDocument.h"

static NSArray *kSTETransitionTypeNames = nil;
static NSArray *kSTETransitionTriggerTypeNames = nil;

@implementation SceneCollectionViewController

@synthesize transitionHUD=_transitionHUD;
@synthesize sceneArrayController = _sceneArrayController;
@synthesize sceneCollectionView= _sceneCollectionView;

- (void) loadView
{
    [super loadView];

	[self.sceneCollectionView setMaxItemSize:NSMakeSize(135, 55)];
	[self.sceneCollectionView setMinItemSize:NSMakeSize(135, 55)];
//	[self.sceneCollectionView setBackgroundColors:[NSArray arrayWithObject:[NSColor colorWithPatternImage:[NSImage imageNamed:@"scenecollection-bg.png"]]]];
}

- (void) dealloc
{
	self.representedObject = nil;

	[self.transitionHUD close];
	[self.transitionHUD release];

	self.sceneCollectionView = nil;
	self.sceneArrayController = nil;

	[super dealloc];
}

- (IBAction)addScene:(id)sender {
	StoryTellingEditorAppDelegate *appDelegate = (StoryTellingEditorAppDelegate*)[NSApp delegate];
	MyDocument *currentDocument = [appDelegate currentDocument];
	SceneMO *scene = [currentDocument createScenePrototype];
		
	NSInteger num = [[self.sceneArrayController arrangedObjects] count];
	NSInteger viewPosition = [[[[self.sceneArrayController arrangedObjects] lastObject] viewPosition] integerValue];
	viewPosition += 1;
	[scene setName:[NSString stringWithFormat:@"%@ %d", [scene name], num]];
	[scene setViewPosition:[NSNumber numberWithInt:viewPosition]];
	if (scene != nil) {
		[self.sceneArrayController addObject:scene];	
	}
}

// see awakeFromNib for an explanation
NSDragOperation decideOnDragOperation(NSView *view, id <NSDraggingInfo> draggingInfo, NSDragOperation allowedMaskForSameView, NSDragOperation allowedMaskForOtherView)
{
	NSDragOperation operationMask = (view == [draggingInfo draggingSource]) ? allowedMaskForSameView : allowedMaskForOtherView;

	NSDragOperation sourceMask = [draggingInfo draggingSourceOperationMask];

	if( [draggingInfo draggingSource] != view ) {
		operationMask &= NSDragOperationCopy;
	}

	sourceMask &= operationMask;

	NSDragOperation finalOperation = 
	(sourceMask & NSDragOperationMove) ? NSDragOperationMove : 
	(sourceMask & NSDragOperationCopy) ? NSDragOperationCopy : 
	(sourceMask & NSDragOperationLink) ? NSDragOperationLink : 
	NSDragOperationNone;
	
	return finalOperation;
}

+ (void)initialize {
	kSTETransitionTypeNames = [[NSArray alloc] initWithObjects:@"Hardcut", @"Crossfade", @"Farbüberblendung", nil];
	kSTETransitionTriggerTypeNames = [[NSArray alloc] initWithObjects:@"Auto", @"Warten", @"Tap", nil];
}

- (NSArray*)transitionTypeContentValues {
	return kSTETransitionTypeNames;
}

- (NSArray*)transitionTriggerTypeContentValues {
	return kSTETransitionTriggerTypeNames;
}

- (void) awakeFromNib 
{
	// BK:
	// we use NSDragOperationEvery for the local mask because if we don't the + icon appears on every drag
	// as of 10.6.4 it appears for every value which is not NSDragOperationEvery
	// this is the reason for the weird clause used to return the drag mask - it prevents the unwanted drag types from occurring while
	// allowing for copy operations with the Alt modifier
	//
	[self.sceneCollectionView setDraggingSourceOperationMask: NSDragOperationCopy | NSDragOperationMove | NSDragOperationDelete	forLocal: YES];
	[self.sceneCollectionView setDraggingSourceOperationMask: NSDragOperationDelete forLocal: NO];
}	

- (NSSet *) viewsForRegisteringObjectExchangeTypes: (NSArray *) types
{
	return [NSSet setWithObject: self.sceneCollectionView];
}

- (NSDictionary *) optionsForDragOperation: (NSDragOperation) operation
{
	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary: [super optionsForDragOperation: operation]];

	[options setValue: @"name" forKey: kObjectExchangeNameToChangeOnCopyKeyPath];
	[options setValue: @"viewPosition" forKey: kObjectExchangeViewPositionKeyPath];

	return options;
}

- (IBAction)showTransitionHUD:(id)sender {
}

- (void)showTransitionHUDForScene:(SceneMO*)scene {
	[self.sceneArrayController setSelectedObjects:[NSArray arrayWithObject:scene]];
	if ([_transitionHUD isVisible]) {
//		[_transitionHUD close];
	} else {
		[_transitionHUD makeKeyAndOrderFront:nil];
	}
}

@end

@implementation SceneCollectionViewController (NSCollectionViewDelegate)

- (BOOL)collectionView:(NSCollectionView *)collectionView writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard {
	NSDictionary *options = [self optionsForDragOperation: NSDragOperationNone];
	return [self.mainArrayController writeObjectsAtIndexes: indexes toPasteboard:pasteboard options: options];
}

- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
	// we can't drop a scene on another one
	if( NSCollectionViewDropOn == *proposedDropOperation ) {
		*proposedDropOperation = NSCollectionViewDropBefore;
	}

	// see -[SceneCollectionView awakeFromNib] for an explanation
	return decideOnDragOperation(collectionView, draggingInfo, NSDragOperationCopy | NSDragOperationMove, NSDragOperationCopy);		
}

- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)destinationIndex dropOperation:(NSCollectionViewDropOperation)dropOperation
{
	NSDragOperation dragOperation = decideOnDragOperation(collectionView, draggingInfo, NSDragOperationCopy | NSDragOperationMove, NSDragOperationCopy);		
	
	NSError *error = nil;

	NSDictionary *options = [self optionsForDragOperation: dragOperation];

	if( NO == [self.mainArrayController performDragOperation: dragOperation fromPasteboard: [draggingInfo draggingPasteboard] beforeIndex: destinationIndex options: options error: &error] ) {
		[NSApp presentError: error];
		return NO;
	}	

	return YES;
}

#pragma mark -
#pragma mark text field delegate methods

- (BOOL)sceneNameAlreadyExists:(NSString*)newName {
	for (SceneMO *scene in [_sceneArrayController arrangedObjects]) {
		if ([scene.name isEqualToString:newName]) return YES;
	}
	return NO;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
	NSString *errorMessage = nil;
	NSString *errorTitle = nil;
	
	if ([self sceneNameAlreadyExists:[fieldEditor string]]) {
		errorTitle = @"Namenskonflikt";
		errorMessage = @"Es gibt bereits eine Szene mit diesem Namen. Bitte wählen Sie einen anderen Namen.";
	}
	
	if ([[fieldEditor string] length] == 0) {
		errorTitle = @"Ungültiger Name";
		errorMessage = @"Bitte geben Sie der Szene einen Namen.";
	}
	
	if (errorMessage) {
		NSBeginCriticalAlertSheet(errorTitle, 
							  @"OK", 
							  nil, nil, [NSApp keyWindow], self, 
							  @selector(sheetDidEnd:returnCode:contextInfo:), 
							  @selector(sheetDidDismiss:returnCode:contextInfo:), nil, errorMessage);
		return NO;
	}
	return YES;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
}

@end


@implementation TransitionTypeToIconTransformer

+ (Class)transformedValueClass { return [NSImage class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {	
	int v = [value intValue];
	switch (v) {
		case kTransitionTypeNone:
			return [NSImage imageNamed:@"button-bg-fade-hardcut.png"];			
		case kTransitionTypeFade:
			return [NSImage imageNamed:@"button-bg-fade-cross.png"];
		case kTransitionTypeFadeThroughColor:
			return [NSImage imageNamed:@"button-bg-fade-color.png"];
	}
	return nil;
}

@end

@implementation TransitionTypeShowOffsetSliderTransformer
+ (Class)transformedValueClass { return [NSNumber class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {	
	switch ([value intValue]) {
		case kTransitionTypeFade:
			return [NSNumber numberWithBool:YES];
	}
	return [NSNumber numberWithBool:NO];
}
@end

@implementation TransitionTypeShowDurationSliderTransformer
+ (Class)transformedValueClass { return [NSNumber class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {	
	switch ([value intValue]) {
		case kTransitionTypeFade: 
		case kTransitionTypeFadeThroughColor: 
			return [NSNumber numberWithBool:YES];
	}
	return [NSNumber numberWithBool:NO];
}
@end

@implementation TransitionTypeShowColorWellTransformer
+ (Class)transformedValueClass { return [NSNumber class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {	
	switch ([value intValue]) {
		case kTransitionTypeFadeThroughColor: 
			return [NSNumber numberWithBool:YES];
	}
	return [NSNumber numberWithBool:NO];
}
@end

@implementation TriggerTypeToIconTransformer

+ (Class)transformedValueClass { return [NSImage class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {	
	int v = [value intValue];
	switch (v) {
		case kTransitionTriggerTypeAutomatic:
			return nil;			
		case kTransitionTriggerTypeTap:
			return [NSImage imageNamed:@"transitionModeTap.png"];
			return nil;
		case kTransitionTriggerTypeWait:
			return [NSImage imageNamed:@"transitionModeWait.png"];
	}
	return nil;
}


@end
