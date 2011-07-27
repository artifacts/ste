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
#import "KeyframeMO.h"

@class AssetMO;

typedef enum {
		kTimeQualificationUnrelated = 0,
		kTimeQualificationBeforeFirstKeyframe = 1,
		kTimeQualificationAfterLastKeyframe = 2,
		kTimeQualificationExistingKeyframe = 3,
		kTimeQualificationNewKeyframe = 4,
		kTimeQualificationTween = 5
} KeyframeAnimationTimeQualification;

#define KeyframeAnimationIsTimeQualificationInsideKeyframes( tQ ) ({ KeyframeAnimationTimeQualification __tQ = (tQ); ( __tQ != kTimeQualificationUnrelated && __tQ != kTimeQualificationBeforeFirstKeyframe && __tQ != kTimeQualificationAfterLastKeyframe ); }) 
#define KeyframeAnimationIsTimeQualificationOnKeyframe( tQ )      ({ KeyframeAnimationTimeQualification __tQ = (tQ); ( __tQ == kTimeQualificationExistingKeyframe || __tQ == kTimeQualificationNewKeyframe ); }) 


@interface KeyframeAnimationMO : NSManagedObject {

}

@property(nonatomic, retain) NSSet *keyframes;
@property(nonatomic, readonly) NSArray *orderedKeyframes;
@property (nonatomic, retain) NSNumber * loop;
@property (nonatomic, retain) NSNumber * loopCount;

@property (nonatomic, retain) AssetMO *asset;

// returns nil if no exact match is found
- (KeyframeMO *) keyframeForTime: (NSNumber *) theTime;

// returns nil if outside any keyframes unless stretchFirstAndLast == YES
- (NSDictionary *) propertiesForTime: (NSNumber *) theTime stretchFirstAndLast: (BOOL) stretchFirstAndLast timeQualification: (KeyframeAnimationTimeQualification *) outTimeQualification;

// returns nil if outside any keyframes unless stretchFirstAndLast == YES
- (NSDictionary *) propertiesForTime: (NSNumber *) theTime stretchFirstAndLast: (BOOL) stretchFirstAndLast;

// returns nil if outside any keyframes
- (NSDictionary *) propertiesForTime: (NSNumber *) theTime;

// returns existing or creates if needed, use outTimeQualification to know which
- (KeyframeMO *) ensureKeyframeForTime: (NSNumber *) newTime timeQualification: (KeyframeAnimationTimeQualification *) outTimeQualification;

// returns existing or creates if needed, use outTimeQualification to know which
- (KeyframeMO *) ensureKeyframeForTime: (NSNumber *) newTime;

// internal workhorse
- (KeyframeAnimationTimeQualification) getStartKeyframe: (KeyframeMO **) outStartKeyframe nextKeyframe: (KeyframeMO **) outNextKeyframe nearestKeyframe: (KeyframeMO **) outNearestKeyframe timeBetween: (NSTimeInterval *) outTimeBetween fraction: (CGFloat *) outFraction forTime: (NSNumber *) theTime;

// scales all keyframes
- (BOOL) scaleGeometricPropertiesBy: (CGSize) scale; 

@end

