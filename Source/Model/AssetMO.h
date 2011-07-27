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
#import "PropertyContainerMO.h"
#import "KeyframeAnimationMO.h"
#import "ExternalDataMO.h"

#define kSTEBlobRefKeyPrimary @"STEBlobRefKeyPrimary"
#define kSTEBlobRefKeyInactiveButtonImage @"kSTEBlobRefKeyInactiveButtonImage"
#define kSTEBlobRefKeyImageSequence @"kSTEBlobRefKeyImageSequence"

enum AssetMOKind {
	AssetMOKindImage = 0,
	AssetMOKindVideo = 1,
};

enum ButtonTargetType {
	ButtonTargetTypeScene = 0,
	ButtonTargetTypeExternalId = 1,
};

@class SceneMO;
@class ExternalDataMO;

@interface AssetMO : PropertyContainerMO {
	NSRange _cachedRange;
	NSMutableIndexSet *_cachedKeyframes;
//	BOOL _keyframesCacheDirty;
//	BOOL _rangeCacheDirty;
}

@property (nonatomic, retain) SceneMO *scene;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *viewPosition;
@property (nonatomic, retain) NSNumber *hidden;
@property (nonatomic, retain) NSNumber *expandedInOutlineView;
@property (nonatomic, assign) AssetMO *parent;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) KeyframeAnimationMO *keyframeAnimation;
@property (nonatomic, retain) NSSet* blobRefs;
@property (nonatomic, retain) NSNumber *isButton;
@property (nonatomic, retain) SceneMO *triggeredScene;
@property (nonatomic, retain) NSString *buttonTargetJumpId;
@property (nonatomic, retain) NSNumber *buttonTargetType;
@property (nonatomic, retain) NSNumber *kind;

@property (nonatomic, retain) ExternalDataMO *primaryBlob;
@property (nonatomic, retain) ExternalDataMO *inactiveButtonImage;


- (NSUInteger)numberOfChildren;
- (void)setExpanded:(BOOL)expanded;
- (BOOL)expanded;

// for timeline view
- (NSRange) range;
- (NSMutableIndexSet*)keyframes;

- (BOOL)hasSameParentAsAssetInArray:(NSArray*)otherAssets;
- (BOOL)keyFramesEditable;

- (void)setBlobRefValue:(ExternalDataMO*)aBlob accessorKey:(NSString*)accessorKey blobKey:(NSString*)blobKey;
- (ExternalDataMO*)blobRefValueForAccessorKey:(NSString*)accessorKey blobKey:(NSString*)blobKey;

- (void) obtainInitialAttributesIfNeeded;

@end

// coalesce these into one @interface Asset (CoreDataGeneratedAccessors) section
@interface AssetMO (CoreDataGeneratedAccessors)
- (void)addChildrenObject:(NSManagedObject *)value;
- (void)removeChildrenObject:(NSManagedObject *)value;
- (void)addChildren:(NSSet *)value;
- (void)removeChildren:(NSSet *)value;

- (void)addBlobRefsObject:(NSManagedObject *)value;
- (void)removeBlobRefsObject:(NSManagedObject *)value;
- (void)addBlobRefs:(NSSet *)value;
- (void)removeBlobRefs:(NSSet *)value;

@end


