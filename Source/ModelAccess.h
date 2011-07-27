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
#import "Model.h"
#import "AssetDragVO.h"

@protocol ModelAccess <NSObject>

/*
#define REPRESENTED_OBJECT_KEYPATH(base, rest)  [[@"representedObject." stringByAppendingString: (base) ] stringByAppendingString: (rest)]
#define REPRESENTED_OBJECT_ACCESS(base, rest) 
*/

#define GENERIC_MODEL_KEYPATH(modelPath, base, rest)  ({ NSString *__modelPath = (modelPath); NSString *__base = (base); NSString *__rest = (rest); [(__modelPath ? [__modelPath stringByAppendingPathExtension: @""] : @"") stringByAppendingString: [__rest length] ? [__base stringByAppendingPathExtension: __rest] : __base]; })

#define kModelAccessStageArrayControllerKeyPath @"stageArrayController"
#define kModelAccessStagesKeyPath @"stageArrayController.arrangedObjects"
#define kModelAccessStageSelectionKeyPath @"stageArrayController.selection"
#define kModelAccessSelectedStagesKeyPath @"stageArrayController.selectedObjects"

#define kModelAccessSceneArrayControllerKeyPath @"sceneArrayController"
#define kModelAccessScenesKeyPath @"sceneArrayController.arrangedObjects"
#define kModelAccessSceneSelectionKeyPath @"sceneArrayController.selection"
#define kModelAccessSelectedScenesKeyPath @"sceneArrayController.selectedObjects"

#define kModelAccessAssetArrayControllerKeyPath @"assetArrayController"
#define kModelAccessAssetsKeyPath @"assetArrayController.arrangedObjects"
#define kModelAccessAssetSelectionKeyPath @"assetArrayController.selection"
#define kModelAccessSelectedAssetsKeyPath @"assetArrayController.selectedObjects"

#define kModelAccessKeyframeAnimationControllerKeyPath @"keyframeAnimationController"
#define kModelAccessKeyframeAnimationSelectionKeyPath @"keyframeAnimationController.selection"
#define kModelAccessSelectedKeyframeAnimationsKeyPath @"keyframeAnimationController.selectedObjects"

#define kModelAccessKeyframeArrayControllerKeyPath @"keyframeArrayController"
#define kModelAccessKeyframesKeyPath @"keyframeArrayController.arrangedObjects"
#define kModelAccessKeyframeSelectionKeyPath @"keyframeArrayController.selection"
#define kModelAccessSelectedKeyframesKeyPath @"keyframeArrayController.selectedObjects"

//#define kModelAccessExternalDataArrayControllerKeyPath @"externalDataArrayController"
//#define kModelAccessExternalDatasKeyPath @"externalDataArrayController.arrangedObjects"
//#define kModelAccessExternalDataSelectionKeyPath @"externalDataArrayController.selection"
//#define kModelAccessSelectedExternalDatasKeyPath @"externalDataArrayController.selectedObjects"

#define kModelAccessUnionOfSceneKeyframesArrayControllerKeyPath @"unionOfSceneKeyframesArrayController"
#define kModelAccessUnionOfSceneKeyframesKeyPath @"unionOfSceneKeyframesArrayController.arrangedObjects"

@property(nonatomic, retain, readonly) NSArrayController *stageArrayController;
@property(nonatomic, retain, readonly) NSObjectController *scenarioController;
@property(nonatomic, retain, readonly) NSArrayController *playableArrayController;
@property(nonatomic, retain, readonly) NSArrayController *sceneArrayController;
@property(nonatomic, retain, readonly) NSArrayController *assetArrayController;
@property(nonatomic, retain, readonly) NSArrayController *keyframeArrayController;

//@property(nonatomic, retain, readonly) NSArrayController *externalDataArrayController;

@property(nonatomic, retain, readonly) NSArrayController *unionOfSceneKeyframesArrayController;

- (void)createAssetContainingChildren:(NSArray *)children withName:(NSString*)name;
- (void)createAssetFromDragData:(AssetDragVO *)dragData atPoint:(CGPoint)aPoint;

- (ExternalDataMO *) externalDataWithProperties: (NSDictionary *) properties;

@end


@interface NSObject (StoryTellingModelObserver)

- (NSString *) modelAccessKeyPath;
- (NSDictionary *) modelAccessObservations;
- (void) setModelAccessObservingState: (BOOL) doObserve;
- (BOOL) processModelAccessObservationForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
