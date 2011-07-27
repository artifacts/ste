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

#import "SceneViewController.h"
#import "ModelAccess.h"
#import "StoryTellingEditorAppDelegate.h"

#define MODEL_KEYPATH(base, rest) GENERIC_MODEL_KEYPATH(@"representedObject", (base), (rest))
#define MODEL_ACCESS(base, rest)  [self valueForKeyPath: MODEL_KEYPATH((base), (rest))]

#define REMOVE_ITEM(item) [[self valueForKeyPath: MODEL_KEYPATH(kModelAccessAssetArrayControllerKeyPath, @"")] removeObject: (item)]

@implementation SceneViewController

@synthesize currentTime;
@synthesize enablesActionsWhileScrubbing;

- (NSDictionary *) optionsForDragOperation: (NSDragOperation) operation
{
	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary: [super optionsForDragOperation: operation]];

	[options setValue: @"name" forKey: kObjectExchangeNameToChangeOnCopyKeyPath];
	[options setValue: @"viewPosition" forKey: kObjectExchangeViewPositionKeyPath];

	return options;
}

- (void) loadView
{
    [super loadView];

	self.currentTime = [NSNumber numberWithInteger: 0];

	[self.view bind:@"width" toObject: self withKeyPath: MODEL_KEYPATH(kModelAccessStageSelectionKeyPath, @"width") options: nil];
	[self.view bind:@"height" toObject: self withKeyPath: MODEL_KEYPATH(kModelAccessStageSelectionKeyPath, @"height") options: nil];

 	[self.view bind:@"pageWidth" toObject: self withKeyPath: MODEL_KEYPATH(kModelAccessStageSelectionKeyPath, @"pageWidth") options: nil];
 	[self.view bind:@"pageHeight" toObject: self withKeyPath: MODEL_KEYPATH(kModelAccessStageSelectionKeyPath, @"pageHeight") options: nil];

	[self.view bind: @"representedObject" toObject: self withKeyPath: @"representedObject" options: nil];
	[self.view bind: @"currentTime" toObject: self withKeyPath: @"currentTime" options: nil];
	
	//self.view.layer.backgroundColor = UTIL_AUTORELEASE_CF( CGColorCreateGenericRGB(1, 1, 0, 0.5) );	
}

- (void) dealloc
{
	[self.view unbind: @"width"];
	[self.view unbind: @"height"];

	[self.view unbind: @"pageWidth"];
	[self.view unbind: @"pageHeight"];

	self.representedObject = nil;

	[self.view unbind: @"representedObject"];
	[self.view unbind: @"currentTime"];


	[currentTime release];
	[super dealloc];
}

- (NSNumber *) currentTimeWithSwitchableActions
{
        return self.currentTime;
}

- (void) setCurrentTimeWithSwitchableActions: (NSNumber *) newTime
{
        BOOL enableActions = self.enablesActionsWhileScrubbing;
        if( NO == enableActions ) {
                [CATransaction begin];
                [CATransaction setDisableActions: YES];
        }

        self.currentTime = newTime;

        if( NO == enableActions ) {
                [CATransaction commit];
        }
}

- (void) removeCanvasItem:(CanvasItem*)item {
	REMOVE_ITEM(item);
}

- (NSDictionary *) optionsForAnimatableProperties
{
	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary: [super optionsForDragOperation: NSDragOperationNone]];
	[options setValue: @"animatableProperties" forKey: kObjectExchangeVariantName];
	return options;
}

- (IBAction) copyFont: (id) sender
{
	AssetEditor *assetEditor = [NSApp storyTellingEditorDelegate].assetEditor;
	NSDictionary *options = [self optionsForAnimatableProperties];

	NSDictionary *animatableProperties = [assetEditor currentTimedProperties];

	NSLog(@"copying1 %@", animatableProperties);
	
	animatableProperties = [assetEditor.currentAsset persistentPropertiesFromProperties: animatableProperties];
		
	NSLog(@"copying2 %@", animatableProperties);

	[ObjectExchange writeDictionaries: [NSArray arrayWithObject: animatableProperties] indexes: nil toPasteboard: nil options: options];
}

- (IBAction) pasteFont: (id) sender
{
	AssetEditor *assetEditor = [NSApp storyTellingEditorDelegate].assetEditor;
	NSDictionary *options = [self optionsForAnimatableProperties];

	NSError *error = nil;
	NSArray *dictionaries = [ObjectExchange dictionariesFromPasteboard: nil options: options error: &error];

	if( nil == dictionaries ) {
		[NSApp presentError: error];
	} else {
		NSDictionary *animatableProperties = [dictionaries lastObject];
		NSLog(@"pasting1 %@", animatableProperties);
		
		animatableProperties = [assetEditor.currentAsset propertiesFromPersistentProperties: animatableProperties];
		
		NSLog(@"pasting2 %@", animatableProperties);
		
		[assetEditor setValuesForKeysWithDictionary: animatableProperties];
	}
}

- (void) moveInTimeBy: (NSInteger) deltaT
{
	NSInteger newTime = [self.currentTime integerValue] + deltaT;

	if( newTime < 0 ) {
		newTime = 0;
		lpdebug("clipping newTime to 0");
	} else {
		NSInteger maxTime = [MODEL_ACCESS(kModelAccessUnionOfSceneKeyframesKeyPath, @"@max.time") integerValue]; 
		if( newTime > maxTime ) {
			lpdebugf("clipping newTime to %ld", (long)maxTime);
			newTime = maxTime;
		}
	}
	
	lpdebug(newTime);

	self.currentTime = [NSNumber numberWithInteger: newTime];
}


- (IBAction) moveInTimeByTagValue: (id) sender;
{
	[self moveInTimeBy: [sender tag] ?: 1];
}

- (NSNumber *) timeForMoveInKeyframesBy: (CGFloat) deltaKeyframe fromTime: (NSNumber *) baseTime
{
	NSArray *keyframeTimes = [MODEL_ACCESS(kModelAccessUnionOfSceneKeyframesKeyPath, @"@distinctUnionOfObjects.time") sortedArrayUsingSelector: @selector(compare:)];
	
	NSInteger deltaKeyframeIndex = deltaKeyframe > 0 ? floor(deltaKeyframe) : ceil(deltaKeyframe);

	CGFloat deltaKeyframeFraction = fabs(deltaKeyframe) - fabs(deltaKeyframeIndex);
	
	NSNumber *movingTime = baseTime;
		
	NSUInteger newKeyframeIndex = ( deltaKeyframe < 0 ) ? [keyframeTimes count] - 1 : 0;

	
	lpdebug(deltaKeyframe, deltaKeyframeIndex, deltaKeyframeFraction, keyframeTimes);


	while( deltaKeyframeIndex != 0 ) {
		
		lpdebug(movingTime, deltaKeyframeIndex);
				
		NSUInteger nextKeyframeIndex = [keyframeTimes indexOfObjectWithOptions: ( deltaKeyframe < 0 ) ? NSEnumerationReverse : 0 passingTest: ^(id obj, NSUInteger idx, BOOL *stop) { 
			NSComparisonResult comp = [obj compare: movingTime]; 
			lpdebug(obj, movingTime, comp);
			return (BOOL) ( ( deltaKeyframe < 0 ) ? ( NSOrderedAscending == comp ) : ( NSOrderedDescending == comp ) );
		}];
		
		if( NSNotFound == nextKeyframeIndex) {
			lpdebug("search aborted");
			break;
		} else {
			newKeyframeIndex = nextKeyframeIndex;
			movingTime = [keyframeTimes objectAtIndex: newKeyframeIndex];
		}
		
		deltaKeyframeIndex += (deltaKeyframeIndex > 0) ? -1 : 1;
	}
			
	lpdebug(newKeyframeIndex, deltaKeyframeFraction);
	
	if( NSNotFound != newKeyframeIndex && deltaKeyframeFraction > 0 ) {
		
		NSInteger neighborIndex = newKeyframeIndex + ( (deltaKeyframe > 0) ? ( newKeyframeIndex < [keyframeTimes count] - 1 ? 1 : 0) : (newKeyframeIndex > 0 ) ? -1 : 0 );

		NSInteger deltaTimeForFraction = deltaKeyframeFraction * [[keyframeTimes objectAtIndex: neighborIndex] integerValue] - [movingTime integerValue];
		
		lpdebug(deltaTimeForFraction);
		
		movingTime = [NSNumber numberWithInteger: [movingTime integerValue] + deltaTimeForFraction];
	}

	return_lpdebug(movingTime);
}

- (BOOL) moveInKeyframesBy: (CGFloat) deltaKeyFrame
{
	NSNumber *newTime = [self timeForMoveInKeyframesBy: deltaKeyFrame fromTime: self.currentTime];
	if( NSOrderedSame == [self.currentTime compare: newTime] ) {
		return NO;
	}
	
	self.currentTime = newTime;
	return YES;
}

- (IBAction) moveInKeyFramesByTagPercent: (id) sender;
{
	if( NO == [self moveInKeyframesBy: [sender tag] / 100.0 ?: 1] ) {
		NSBeep();
	}
}

@end
