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

#import "MergeDocumentsWizardController.h"

#import "ModelAccess.h"
#import "Convenience_Macros.h"
#import "NSManagedObject_DictionaryRepresentation.h"

@implementation MergeDocumentsWizardController

@synthesize chooseTypeOfMergeView, chooseAssetsView, mergeTypeMatrix, assetMergeTableView, assetMergeDictionariesArrayController;

@synthesize sourceDocuments;
@synthesize targetDocuments;

@synthesize assetMergeDictionaries;

- (NSSet *) sourceAssetsForMerge: (NSError **) outError
{
	NSLog(@"sources: %@", self.sourceDocuments);

	NSArray *sourceScenes = [self valueForKeyPath: GENERIC_MODEL_KEYPATH(@"sourceDocuments", kModelAccessScenesKeyPath, nil)];
	NSArray *sourceSelectedScenes = [self valueForKeyPath: GENERIC_MODEL_KEYPATH(@"sourceDocuments", kModelAccessSelectedScenesKeyPath, nil)];
	
	// we don't support multiple source documents yet
	sourceScenes = [sourceScenes lastObject];
	sourceSelectedScenes = [sourceSelectedScenes lastObject];

	if( [sourceSelectedScenes count] ) {
		sourceScenes = sourceSelectedScenes;
	}
	
	SceneMO	*sourceScene = [sourceScenes count] ? [sourceScenes objectAtIndex: 0] : nil;
	
	CHECK_NSERROR_REASON_RETURN_NIL(nil != sourceScene, outError, NSPOSIXErrorDomain, EINVAL, @"sourceDocumentForMergeHasNoScene");

	NSSet *sourceAssets = sourceScene.assets;

	CHECK_NSERROR_REASON_RETURN_NIL(0 != [sourceAssets count], outError, NSPOSIXErrorDomain, EINVAL, @"sourceSceneForMergeHasNoAssets");

	return sourceAssets;
}

- (NSArray *) targetScenesForMerge: (NSError **) outError
{
	NSLog(@"targets: %@", self.targetDocuments);

	NSArray *targetScenes = [self valueForKeyPath: GENERIC_MODEL_KEYPATH(@"targetDocuments", kModelAccessScenesKeyPath, nil)];
	
	// we don't support multiple target documents yet
	targetScenes = [targetScenes lastObject];
	
	
	CHECK_NSERROR_REASON_RETURN_NIL(0 != [targetScenes count], outError, NSPOSIXErrorDomain, EINVAL, @"targetDocumentForMergeHasNoScene");

	return targetScenes;
}

- (IBAction)cancelAction:(id)sender {
    [NSApp stopModal];
}

- (IBAction)continueToAssetSelectionViewAction:(id)sender {
    [transition setSubtype:kCATransitionFromRight];
	[[[[self window] contentView] animator] replaceSubview:chooseTypeOfMergeView with:chooseAssetsView];

	[[self window] makeFirstResponder: self.assetMergeTableView]; 

	NSError *error;

	NSSet *sourceAssets = nil;
	NSArray *targetScenes = nil;
	
	if ( nil == ( sourceAssets = [self sourceAssetsForMerge: &error] ) || nil == ( targetScenes = [self targetScenesForMerge: &error] ) ) {
		lpkerrorf("preconditionFail, documentMerge", "error: %@", error);
		[self presentError: error];

		[NSApp stopModal];
		return;
	}
	
	NSMutableArray *tempAssetMergeDictionaries = [NSMutableArray array];

	NSCountedSet *maxViewPositions = [NSCountedSet setWithCapacity: [targetScenes count]];

	// establish initial countedSet values for maxViewPositions, allows for easier handling afterwards
	// and avoids using names as dictionary keys (scenes don't support NSCopying and therefore can't be keys)
	for( SceneMO *targetScene in targetScenes ) {
		NSInteger maxViewPosition = [[targetScene.assets valueForKeyPath: @"@max.viewPosition"] integerValue];
		for ( int i = 0 ; i < maxViewPosition ; ++i ) { 
			[maxViewPositions addObject: targetScene];
		}
	}

	for( AssetMO *sourceAsset in sourceAssets ) {
		NSString *sourceAssetName = sourceAsset.name;

		for( SceneMO *targetScene in targetScenes ) {

			[maxViewPositions addObject: targetScene]; // increment viewPosition
			NSNumber *nextViewPosition = [NSNumber numberWithInteger: [maxViewPositions countForObject: targetScene]];
			
			NSMutableDictionary *assetDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
													sourceAsset, @"sourceAsset", 
													sourceAssetName, @"sourceAssetName", 
													sourceAsset.scene, @"sourceScene", 
													sourceAsset.scene.name, @"sourceSceneName", 
													sourceAssetName, @"targetAssetName", // not a typo - the same for now
													nextViewPosition, @"targetAssetViewPosition", // default if not replacing target
													targetScene, @"targetScene", 
													targetScene.name, @"targetSceneName", 
													[NSNumber numberWithBool: YES], @"isSelected",
													[NSNumber numberWithBool: NO], @"doesReplaceTargetAsset",
													nil];
																
			for( AssetMO *targetAsset in targetScene.assets ) {
				if( [targetAsset.name isEqualToString: sourceAssetName] ) {
						[assetDictionary setValue: targetAsset forKey: @"targetAsset"];
						[assetDictionary setValue: targetAsset.name forKey: @"targetAssetName"];
						[assetDictionary setValue: targetAsset.viewPosition forKey: @"targetAssetViewPosition"];
						[assetDictionary setValue: [NSNumber numberWithBool: YES] forKey: @"doesReplaceTargetAsset"];

						[maxViewPositions removeObject: targetScene]; // decrement viewPosition because we didn't use the default one

						break;
				}
			} // for targetAssets
			
			[tempAssetMergeDictionaries addObject: assetDictionary];
			
		} // for targetScenes
	} // for sourceAssets

	// very heavy
	// NSLog(@"merge to do: %@", tempAssetMergeDictionaries);
	
	self.assetMergeDictionaries = tempAssetMergeDictionaries;
	
	[self.assetMergeDictionariesArrayController setSortDescriptors: 
		[NSArray arrayWithObjects: 
			[NSSortDescriptor sortDescriptorWithKey: @"targetSceneName" ascending: YES],
			[NSSortDescriptor sortDescriptorWithKey: @"targetAssetViewPosition" ascending: NO],
		nil]
	];
}


- (IBAction)doMergeAction:(id)sender {

	for( NSDictionary *mergeDict in self.assetMergeDictionaries ) {
		
		if( NO == [[mergeDict valueForKey: @"isSelected"] boolValue] ) {
			continue;
		}

		AssetMO *sourceAsset = [mergeDict valueForKey: @"sourceAsset"];
		NSString *sourceExternalURL = sourceAsset.primaryBlob.externalURL;

		SceneMO *targetScene = [mergeDict valueForKey: @"targetScene"];

		BOOL doesReplaceTargetAsset = [[mergeDict valueForKey: @"doesReplaceTargetAsset"] boolValue];
		
		AssetMO *targetAsset = doesReplaceTargetAsset ? [mergeDict valueForKey: @"targetAsset"] : nil;
		NSString *targetAssetName = [mergeDict valueForKey: @"targetAssetName"];
		NSNumber *targetAssetViewPosition = [mergeDict valueForKey: @"targetAssetViewPosition"];

		
		if( YES == doesReplaceTargetAsset ) {
			NSData *sourceCachedData = sourceAsset.primaryBlob.cachedData;

			NSString *targetExternalURL = targetAsset.primaryBlob.externalURL;

			NSLog(@"replacing %@->%@\n%@ with\n%@", targetScene.name, targetAsset.name, targetExternalURL, sourceExternalURL);
			
			targetAsset.primaryBlob.cachedData = sourceCachedData;
			targetAsset.primaryBlob.externalURL = nil;
			// seems to work without [[targetAsset managedObjectContext] processPendingChanges];
			targetAsset.primaryBlob.externalURL = sourceExternalURL;
			
		} else { // !doesReplaceTargetAsset
			NSLog(@"copying  %@->%@ z%@\n%@", targetScene.name, targetAssetName, targetAssetViewPosition, sourceExternalURL);

			NSError *error = nil;

			targetAsset = [NSManagedObject objectFromDictionaryRepresentation: [sourceAsset dictionaryRepresentationWithOptions: nil] 
			inManagedObjectContext: [targetScene managedObjectContext] options: nil error: &error];

			if( nil == targetAsset ) {
				lpkerrorf("postConditionFail, documentMerge", "error: %@", error);
				[self presentError: error];
				break;
			}
			
			targetAsset.viewPosition = targetAssetViewPosition;

			[[targetScene mutableSetValueForKey: @"assets"] addObject: targetAsset];

		} // if doesReplaceTargetAsset
		
	} // for mergeDictionaries
	
    [NSApp stopModal];
}

- (void)awakeFromNib {
	[[self.window contentView] addSubview:chooseTypeOfMergeView];
    transition = [CATransition animation];
    [transition setType:kCATransitionPush];
    [transition setSubtype:kCATransitionFromRight];
    
    NSDictionary *ani = [NSDictionary dictionaryWithObject:transition forKey:@"subviews"];
    [[self.window contentView] setAnimations:ani];	
}

- (void) dealloc
{
	lptrace();
	[chooseAssetsView release];
	[chooseTypeOfMergeView release];
	[mergeTypeMatrix release];
	[assetMergeTableView release];
	[assetMergeDictionariesArrayController release];


	[sourceDocuments release];
	[targetDocuments release];

	[assetMergeDictionaries release];

	[super dealloc];
}

@end
