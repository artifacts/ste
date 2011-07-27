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

/*
 dynamic properties in dictionary:
 
 mass
 friction
 physicsIsStatic
 physicsEnabled
 
 */

#import "AssetMO.h"
#import "RegexKitLite.h"
#import <EngineRoom/CrossPlatform_Utilities.h>

//static NSString *kKeyFrameAnimationDidChangeContext;


@implementation AssetMO

@dynamic scene;
@dynamic name;
@dynamic viewPosition;
@dynamic hidden;
@dynamic expandedInOutlineView;
@dynamic parent;

@dynamic children;
@dynamic keyframeAnimation;
@dynamic blobRefs;
@dynamic isButton;
@dynamic triggeredScene;
@dynamic buttonTargetJumpId;
@dynamic buttonTargetType;
@dynamic kind;

@dynamic primaryBlob;


+ (NSSet *) keyPathsForValuesAffectingPrimaryBlob
{
	return [NSSet setWithObject: @"blobRefs"];
}

+ (NSSet *) keyPathsForValuesAffectingInactiveButtonImage
{
	return [NSSet setWithObject: @"blobRefs"];
}

- (NSSet *) keysToExcludeFromDictionaryRepresentationInContext: (void *) context
{
	return [NSSet setWithObjects: @"scene", @"triggeredScene", nil];
}

- (NSUInteger)numberOfChildren {
	return [[self children] count];
}

- (BOOL)expanded {
	return [[self expandedInOutlineView] boolValue];
}

- (void)setExpanded:(BOOL)value {
	[self setExpandedInOutlineView:[NSNumber numberWithBool:value]];
}

- (NSRange) range {

	if (![self keyFramesEditable]) {
			return NSMakeRange(0, 0);
	}
		NSArray *orderedKeyframes = [self valueForKeyPath:@"keyframeAnimation.orderedKeyframes"];
		NSInteger numKeyframes = [orderedKeyframes count];
		if (numKeyframes == 0){
			_cachedRange = (NSRange){0, 1};
		}else if (numKeyframes == 1){
			_cachedRange = (NSRange){[[[orderedKeyframes objectAtIndex:0] valueForKey:@"time"] 
									  integerValue], 1};
		}else{
			NSInteger firstKeyframeIndex = [[[orderedKeyframes objectAtIndex:0] 
											 valueForKey:@"time"] integerValue];
			NSInteger lastKeyframeIndex = [[[orderedKeyframes lastObject] valueForKey:@"time"] 
										   integerValue];
			//NSLog(@"lastKeyframeIndex: %d", lastKeyframeIndex);
			
			_cachedRange = (NSRange){firstKeyframeIndex, lastKeyframeIndex - firstKeyframeIndex + 1};
		}

	return _cachedRange;
}

- (NSMutableIndexSet*)keyframes {
		[_cachedKeyframes release];
		_cachedKeyframes = [[NSMutableIndexSet alloc] init];
		NSArray *orderedKeyframes = [self valueForKeyPath:@"keyframeAnimation.orderedKeyframes"];	
		for (id keyframe in orderedKeyframes){
			[_cachedKeyframes addIndex:[[keyframe valueForKey:@"time"] integerValue]];
		}
	return _cachedKeyframes;
}

- (BOOL)hasSameParentAsAssetInArray:(NSArray*)otherAssets {
	id myParent = [self parent];
	id otherParent;
	if (myParent == nil) return NO;
	
	for (AssetMO *otherAsset in otherAssets) {
		otherParent = [otherAsset parent];
		if (otherParent == nil || otherParent!= myParent) return NO;
	}
	return YES;
}

- (void)setBlobRefValue:(ExternalDataMO*)aBlob accessorKey:(NSString*)accessorKey blobKey:(NSString*)blobKey {
	[self willChangeValueForKey: accessorKey];
	
	ExternalDataMO *existingBlob = [self blobRefValueForAccessorKey:accessorKey blobKey: blobKey];

	if( nil != existingBlob ) {
		[self removeBlobRefsObject:	existingBlob];
	}
	
	if( nil != aBlob ) {
		[self addBlobRefsObject: aBlob];
	}

	[self didChangeValueForKey: accessorKey];
}

- (ExternalDataMO*)blobRefValueForAccessorKey:(NSString*)accessorKey blobKey:(NSString*)blobKey {
	[self willAccessValueForKey: accessorKey];

	NSSet *blobs = self.blobRefs;

	if( nil == blobs ) {
		NSLog(@"No blobs to fetch %@ from %@", accessorKey, self);
		return nil;
	}

	NSSet *matchingBlobs = [blobs objectsPassingTest: ^(id obj, BOOL *stop) {
		return [[obj valueForKey: @"keyName"] isEqualToString: blobKey];
	}];

	if( [blobs count] > 1 ) {
		NSLog(@"WARNING: found more than one blob for %@: %@", accessorKey, matchingBlobs);
	}			

	[self didAccessValueForKey: accessorKey];
	return [matchingBlobs anyObject];
}

- (ExternalDataMO*)primaryBlob {
	return [self blobRefValueForAccessorKey:@"primaryBlob" blobKey:kSTEBlobRefKeyPrimary];
}

- (void)setPrimaryBlob:(ExternalDataMO*)aBlob {
	[self setBlobRefValue:aBlob accessorKey:@"primaryBlob" blobKey:kSTEBlobRefKeyPrimary];
}

- (ExternalDataMO*)inactiveButtonImage {
	return [self blobRefValueForAccessorKey:@"inactiveButtonImage" blobKey:kSTEBlobRefKeyInactiveButtonImage];
}

- (void)setInactiveButtonImage:(ExternalDataMO*)aBlob {
	[self setBlobRefValue:aBlob accessorKey:@"inactiveButtonImage" blobKey:kSTEBlobRefKeyInactiveButtonImage];
}

// KFs may only be edited when asset has no children. Assets with no children act as groups.
// This is for now and may change in the future.

- (BOOL)keyFramesEditable {
	return (self.children == nil || [self.children count] == 0);
}

// returns true if it has a parent - needed for NSTreeController
- (BOOL)isLeaf {
	return (self.parent != nil);
}

- (void) obtainInitialAttributesIfNeeded
{
	KeyframeMO *keyframe = [[self valueForKeyPath:@"keyframeAnimation.keyframes"] anyObject];
		
	// on asset creation (and only then, not when loading a document) 
	// we need to get the bounds from the image
	NSValue *boundsValue = [keyframe valueForKey: @"bounds"];
	BOOL needsInitialSize = ( nil == boundsValue || CGRectEqualToRect( CGRectZero, [boundsValue CGRectValue] ) );

	ExternalDataMO *BLOB = self.primaryBlob;
		
	MediaContainer *mediaContainer = BLOB.mediaContainer;
	
	if( YES == needsInitialSize && mediaContainer.loaded ) {

		CGSize imageSize = { mediaContainer.width, mediaContainer.height }; 
		
		lpkdebug("mediaContainer", "initial size", imageSize);
		[keyframe setValue:[NSValue valueWithCGRect: (CGRect) { CGPointZero, imageSize } ] forKey:@"bounds"];		
	}
}

@end



