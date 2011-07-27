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

#import "AssetDimensionsPanelViewController.h"
#import "AssetMO.h"
#import "StageMO.h"
#import "Constants.h"
#import "ModelAccess.h"

#define MODEL_KEYPATH(base, rest) GENERIC_MODEL_KEYPATH(@"currentDocument", (base), (rest))
#define MODEL_ACCESS(base, rest)  [self valueForKeyPath: MODEL_KEYPATH((base), (rest))]

@implementation AssetDimensionsPanelViewController

- (id)initWithDocument:(MyDocument *)doc{
	if (self = [super initWithNibName:@"AssetDimensionsPanel" bundle:nil]){
	}
	return self;
}

- (void)dealloc{
	
	[[self class] cancelPreviousPerformRequestsWithTarget: self selector: @selector(delayedSetRenderQuality:) object: nil];						   
	
	[NSApp removeObserver:self forKeyPath:@"delegate.assetEditorController.selection.self"];
	[super dealloc];
}

- (MyDocument*)currentDocument {
	return [[NSApp delegate] currentDocument];
}

#pragma mark -
#pragma mark Initialization & Deallocation

- (void)awakeFromNib{	
	[NSApp addObserver:self forKeyPath:@"delegate.assetEditorController.selection.self" 
			   options:0 context:NULL];
	[self _updateContentView];
}

#pragma mark -
#pragma mark actions

- (void)didSelectPresetAction:(id)sender {
	NSPopUpButton *popup = sender;
	NSInteger idx = [popup indexOfSelectedItem] - 1; /* NULL placeholder */
	
	NSArray *presets = [[NSUserDefaults standardUserDefaults] arrayForKey: kSTEStageSizePresetsPreference];
	
	if( idx >= 0 && idx < [presets count] ) {
		id preset = [presets objectAtIndex: idx];
		StageMO *stage = MODEL_ACCESS(kModelAccessStageSelectionKeyPath, @"self");
		stage.height = [preset valueForKey: @"height"];
		stage.width = [preset valueForKey: @"width"];
	}
}

- (void) delayedSetRenderQuality: (NSArray *) targetAndQuality
{
	ExternalDataMO *target = [targetAndQuality objectAtIndex: 0];
	NSNumber *renderQuality = [targetAndQuality objectAtIndex: 1];

	target.renderQuality = renderQuality;
	
	// necessary to make CoreData send out the didChange messages while we are dragging the slider
	[target.managedObjectContext processPendingChanges];
}

- (void) takeDelayedRenderQualityFrom: (id) sender;
{
	NSInteger quality = [sender integerValue];
	
	ExternalDataMO *BLOB = [_assetEditorController valueForKeyPath: @"content.currentAsset.primaryBlob"];
	
	[[self class] cancelPreviousPerformRequestsWithTarget: self];
								
	NSTimeInterval delayTime = (kMediaContainerRenderQualityOriginal == quality) ? 0.0 : 0.1;

	[textFieldRenderQuality setStringValue: [NSString stringWithFormat: @"%ld%%", (long) quality]];
	[textFieldRenderQualityPhysics setStringValue: [textFieldRenderQuality stringValue]];
	
	NSArray *targetAndQuality = ER_ARRAY(BLOB, [NSNumber numberWithInteger: quality]);
	
	[self performSelector: @selector(delayedSetRenderQuality:) withObject: targetAndQuality afterDelay: delayTime inModes: ER_ARRAY(NSRunLoopCommonModes, NSEventTrackingRunLoopMode)];
//	[self delayedSetRenderQuality: targetAndQuality];
}

#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
					   context:(void *)context{

  [self _updateContentView];
}

#pragma mark -
#pragma mark Private methods

- (void)_updateContentView{
	NSView *newView = _stagePropertiesView;
	NSString *title = @"Bühne";
	StageMO *stage = MODEL_ACCESS(kModelAccessStageSelectionKeyPath, @"self");
	BOOL physicsEnabled = !NSIsControllerMarker(stage) && [stage.physicsEnabled boolValue];

	// we have selected assets	
	AssetMO *asset = [[_assetEditorController content] valueForKeyPath:@"currentAsset"];
	if (asset){
		newView = _assetPropertiesView;
		
		
		NSString *externalId =  NSLocalizedString(@"-", @"BLOB.externalId not applicable");
		NSString *externalURL = NSLocalizedString(@"-", @"BLOB.externalURL not applicable");
		
		ExternalDataMO *primaryBLOB = [asset primaryBlob];
		
		if( nil != primaryBLOB ) {
			externalId = [primaryBLOB externalId] ?: NSLocalizedString(@"-", @"BLOB.externalId not available");
			externalURL = [primaryBLOB externalURL] ?: NSLocalizedString(@"-", @"BLOB.externalURL not available");
		}
		
		title = [NSString stringWithFormat:@"Typ: Asset\n Name: %@\n z: %@\n URL: %@\n externe ID: %@", [_assetEditorController valueForKeyPath:@"selection.name"],
				 [_assetEditorController valueForKeyPath:@"selection.viewPosition"],
				 externalURL,
				 externalId];
		
		[textFieldExternalID setStringValue: externalId];
		[textFieldExternalURL setStringValue: externalURL];
		
		NSInteger quality = [primaryBLOB.renderQuality integerValue] ?: kMediaContainerRenderQualityOriginal;
		
		[sliderRenderQuality setIntegerValue: quality];
		[sliderRenderQualityPhysics setIntegerValue: quality];

		[textFieldRenderQuality setStringValue: [NSString stringWithFormat: @"%ld%%", (long) quality]];
		[textFieldRenderQualityPhysics setStringValue: [textFieldRenderQuality stringValue]];
		
		
		if (physicsEnabled == YES) {
			newView = _physicsPropertiesView;
		}		
	}	
		
	[self setTitle:title];
	[infoLabel setStringValue: title];
	
	if (newView == _currentView)
		return;
	
	[_currentView removeFromSuperview];
	
	NSRect frame = [[self view] frame];
	frame.size = [newView frame].size;
	[[self view] setFrame:frame];
	[newView setFrame:[[self view] bounds]];
	[[self view] addSubview:newView];
	
	_currentView = newView;
}

@end
