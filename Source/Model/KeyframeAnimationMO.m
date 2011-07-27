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

#import "KeyframeAnimationMO.h"
#import "KeyframeMO.h"

#import <EngineRoom/CrossPlatform_Utilities.h>

#import "BKColor.h"

static int debug = 0;

#define OUT_VALUE_RETAIN(outPtr, value) do{ if( nil != (outPtr) ) { *(outPtr) = [[(value) retain] autorelease]; } } while( 0 )
#define OUT_VALUE_ASSIGN(outPtr, value) do{ if( nil != (outPtr) ) { *(outPtr) = (value); } } while( 0 )

#define KEYFRAMETIME(kf) ((NSTimeInterval)[[kf valueForKey: @"time"] doubleValue])

typedef id (^interpolator_t)(id startValue, id nextValue, CGFloat fraction);

@implementation KeyframeAnimationMO

@dynamic keyframes, loop, loopCount;

@dynamic asset;

- (NSSet *) keysToExcludeFromDictionaryRepresentationInContext: (void *) context
{
	return [NSSet setWithObjects: @"asset", nil];
}


- (NSArray *) orderedKeyframes
{
	return (nil == self.keyframes) ? [NSMutableArray array] : 
	[self.keyframes sortedArrayUsingDescriptors: 
			[NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey: @"time" ascending: YES]]];	
}

- (KeyframeMO *) keyframeForTime: (NSNumber *) theTime
{
	for(KeyframeMO *keyframe in self.keyframes) {
		if ( [keyframe.time isEqualToNumber: theTime] ) {
			return keyframe;
		}
	}
	
	return nil;
}

- (KeyframeAnimationTimeQualification) getStartKeyframe: (KeyframeMO **) outStartKeyframe nextKeyframe: (KeyframeMO **) outNextKeyframe nearestKeyframe: (KeyframeMO **) outNearestKeyframe timeBetween: (NSTimeInterval *) outTimeBetween fraction: (CGFloat *) outFraction forTime: (NSNumber *) theTime
{
	KeyframeAnimationTimeQualification timeQualification = kTimeQualificationUnrelated;

	NSInteger playTime = [theTime integerValue];

	NSArray *keyframes = self.orderedKeyframes;

	KeyframeMO *startKeyframe = nil;
	KeyframeMO *nextKeyframe = nil;
	KeyframeMO *nearestKeyframe = nil;

	NSTimeInterval timeBetween = 0.0;
	CGFloat fraction = 0.0;

	NSInteger startIndex = -1; 

	for(KeyframeMO *keyframe in keyframes) {

		NSInteger keyframeTime = KEYFRAMETIME(keyframe);

		nearestKeyframe = keyframe;

		if( playTime >= keyframeTime ) {

			startKeyframe = keyframe;
			
			++startIndex;
		} else {
			if ( nil == startKeyframe ) {
				timeQualification = kTimeQualificationBeforeFirstKeyframe;
			}
			break;
		}

	}

	if( nil != startKeyframe ) {

		NSTimeInterval startTime = KEYFRAMETIME(startKeyframe);
	
		if( [keyframes lastObject] == startKeyframe ) {

			nearestKeyframe = startKeyframe;

			if( playTime > startTime ) { // playtime exceeds available KeyframeMOs
				startKeyframe = nil;
				timeQualification = kTimeQualificationAfterLastKeyframe;
			} else {
				timeQualification = kTimeQualificationExistingKeyframe;
			}
		
		} else {
		
			nextKeyframe = [keyframes objectAtIndex: startIndex + 1];
		
			NSInteger nextTime = KEYFRAMETIME(nextKeyframe);
		
			timeBetween = nextTime - startTime;
		
			NSAssert( timeBetween > 0.0, @"time between successive frames > 0.0");
		
			fraction = (playTime - startTime) / timeBetween;

			nearestKeyframe = ( fraction >= 0.5 ) ? nextKeyframe : startKeyframe;

			timeQualification = (playTime == startTime) ? kTimeQualificationExistingKeyframe : kTimeQualificationTween;
		}
	}
	
	OUT_VALUE_RETAIN(outStartKeyframe, startKeyframe);
	OUT_VALUE_RETAIN(outNextKeyframe, nextKeyframe);
	OUT_VALUE_RETAIN(outNearestKeyframe, nearestKeyframe);
	OUT_VALUE_ASSIGN(outTimeBetween, timeBetween);
	OUT_VALUE_ASSIGN(outFraction, fraction);

	return timeQualification;
}

interpolator_t noInterpolator = ^ id (id a, id b, CGFloat fraction) { return fraction == 1 ? b : a; };

interpolator_t simpleInterpolator = ^ id (id a, id b, CGFloat fraction) { return fraction < 0.5 ? a : b; };

interpolator_t bkColorInterpolator = ^ id (id a, id b, CGFloat fraction) { 
	return (id)[BKColor colorWithNSColor: [[a NSColor] blendedColorWithFraction: fraction ofColor: [b NSColor]]];
};

interpolator_t doubleInterpolator = ^ id (id a, id b, CGFloat fraction) { 
	double _a = [a doubleValue]; 
	return [NSNumber numberWithDouble: _a + fraction * ( [b doubleValue] - _a )]; 
};

interpolator_t rotationInterpolator = ^ id (id a, id b, CGFloat fraction) { 
	double _a = [a doubleValue]; 
	double value = _a + fraction * ( [b doubleValue] - _a );
	return [NSNumber numberWithDouble: value]; 
};

interpolator_t pointInterpolator = ^ id (id a, id b, CGFloat fraction) { 
	CGPoint _a = [a CGPointValue], _b = [b CGPointValue];
	return [NSValue valueWithCGPoint: CGPointMake( _a.x + fraction * ( _b.x - _a.x ), _a.y + fraction * ( _b.y - _a.y ) )];
};

interpolator_t sizeInterpolator = ^ id (id a, id b, CGFloat fraction) { 
	CGSize _a = [a CGSizeValue], _b = [b CGSizeValue];
	return [NSValue valueWithCGSize: CGSizeMake( _a.width + fraction * ( _b.width - _a.width ), _a.height + fraction * ( _b.height - _a.height ) )];
};

interpolator_t rectInterpolator = ^ id (id a, id b, CGFloat fraction) { 
	CGRect _a = [a CGRectValue], _b = [b CGRectValue];
	return [NSValue valueWithCGRect: CGRectMake( 
												_a.origin.x + fraction * ( _b.origin.x - _a.origin.x ), _a.origin.y + fraction * ( _b.origin.y - _a.origin.y ),
												_a.size.width + fraction * ( _b.size.width - _a.size.width ), _a.size.height + fraction * ( _b.size.height - _a.size.height ) )];
};


- (NSDictionary *) propertiesForTime: (NSNumber *) theTime stretchFirstAndLast: (BOOL) stretchFirstAndLast timeQualification: (KeyframeAnimationTimeQualification *) outTimeQualification
{
	static NSDictionary *interpolatorsByObjCType = nil;
	static NSDictionary *interpolatorsByKeyPath = nil;
	
	if( nil == interpolatorsByObjCType ) {
	
		interpolator_t autoreleasedDoubleInterpolator = [[doubleInterpolator copy] autorelease];
	
		interpolatorsByKeyPath = [[NSDictionary alloc] initWithObjectsAndKeys:		
			[[noInterpolator copy] autorelease], @"easing",
			[[rotationInterpolator copy] autorelease], @"rotation",
//			[[simpleInterpolator copy] autorelease], @"propertyNameToBeSwitchedInTheMiddle",
			nil];
	
		interpolatorsByObjCType = [[NSDictionary alloc] initWithObjectsAndKeys:
						 [[simpleInterpolator copy] autorelease], @"SIMPLE", 
						 [[bkColorInterpolator copy] autorelease], @"BKColor", 
						 [[simpleInterpolator copy] autorelease], [NSString stringWithUTF8String: @encode(BOOL)],
						 [[noInterpolator copy] autorelease], @"NSCFString",
  						 autoreleasedDoubleInterpolator, [NSString stringWithUTF8String: @encode(int16_t)],
						 autoreleasedDoubleInterpolator, [NSString stringWithUTF8String: @encode(uint16_t)],
  						 autoreleasedDoubleInterpolator, [NSString stringWithUTF8String: @encode(int32_t)],
						 autoreleasedDoubleInterpolator, [NSString stringWithUTF8String: @encode(uint32_t)],
  						 autoreleasedDoubleInterpolator, [NSString stringWithUTF8String: @encode(int64_t)],
						 autoreleasedDoubleInterpolator, [NSString stringWithUTF8String: @encode(uint64_t)],
  						 autoreleasedDoubleInterpolator, [NSString stringWithUTF8String: @encode(float_t)],
						 autoreleasedDoubleInterpolator, [NSString stringWithUTF8String: @encode(double_t)],
						 [[pointInterpolator copy] autorelease], [NSString stringWithUTF8String: @encode(CGPoint)],
						 [[sizeInterpolator copy] autorelease], [NSString stringWithUTF8String: @encode(CGSize)],
						 [[rectInterpolator copy] autorelease], [NSString stringWithUTF8String: @encode(CGRect)],
						 nil];
	}

	KeyframeMO *startKeyframe = nil;
	KeyframeMO *nextKeyframe = nil;
	KeyframeMO *nearestKeyframe = nil;

	NSTimeInterval timeBetween = 0.0;
	CGFloat fraction = 0.0;

	KeyframeAnimationTimeQualification timeQualification = [self getStartKeyframe: &startKeyframe nextKeyframe: &nextKeyframe nearestKeyframe: &nearestKeyframe timeBetween: &timeBetween fraction: &fraction forTime: theTime];

	if( debug) { NSLog(@"time: %@ qualified as %ld", theTime, (long)timeQualification); }

	OUT_VALUE_ASSIGN(outTimeQualification, timeQualification);

	BOOL isTimeInsideKeyframes = KeyframeAnimationIsTimeQualificationInsideKeyframes( timeQualification );

	if( NO == isTimeInsideKeyframes ) {
		if( debug) { NSLog(@"time: %@ is out of any Keyframes prop: nil", theTime); }

		if( timeQualification == kTimeQualificationUnrelated || NO == stretchFirstAndLast ) {
			return nil;
		} else {
			return nearestKeyframe.properties;
		}
	}

	NSDictionary *startProperties = startKeyframe.properties;
	NSDictionary *nextProperties = nil;

	if( KeyframeAnimationIsTimeQualificationOnKeyframe( timeQualification ) ) {
		if( debug ) { NSLog(@"time: %@ is on keyframe - props: %@", theTime, startProperties); }
		return startProperties;
	}

	NSAssert( nil != nextKeyframe, @"reached interpolation without a next keyframe - serious bug");

	nextProperties = nextKeyframe.properties;

	if( debug ) { NSLog(@"time: %@ is between start: %.3lf end: %.3lf (%.3lfs) fraction: %.3lf - startProps: %@ nextProps: %@",
		theTime, KEYFRAMETIME(startKeyframe), KEYFRAMETIME(nextKeyframe), timeBetween, fraction, startProperties, nextProperties); }
	
	NSMutableDictionary *currentProperties = [NSMutableDictionary dictionaryWithDictionary: startProperties];

	for( NSString *keyPath in nextProperties ) { 
		NSValue *startValue = [startProperties valueForKeyPath: keyPath];
		NSValue *nextValue = [nextProperties valueForKeyPath: keyPath];

		if( nil != nextValue ) {

			interpolator_t interpolator = NULL;

			const char *valueType = NULL;
			
			interpolator = [interpolatorsByKeyPath objectForKey: keyPath];
			
			if( nil == interpolator ) {
			
				valueType = [startValue isKindOfClass: [NSValue class]] ? [startValue objCType] : [NSStringFromClass([startValue class]) UTF8String];

				if( debug > 1 ) { NSLog(@"kp: %@ valueClass: %@ valueType: %s = %@", keyPath, [startValue class], valueType, startValue); }

				interpolator = [interpolatorsByObjCType objectForKey: valueType ? [NSString stringWithUTF8String: valueType] : @"SIMPLE"];
			} else {
				valueType = "keyPath";
			}

			id currentValue = interpolator ? interpolator(startValue, nextValue, fraction) : nil;
			
			if(nil == currentValue) {
				NSLog(@"currentValue is nil for class: %@ type: %s keyPath: %@ startValue: %@ nextValue: %@\ninterp: %@", 
					[startValue class], valueType, keyPath, startValue, nextValue, interpolatorsByObjCType);
				NSAssert( currentValue != nil, @"currentValue undefined" );			
			}
												
			[currentProperties setValue: currentValue forKeyPath: keyPath];
		}
	}

	return currentProperties;
}

- (NSDictionary *) propertiesForTime: (NSNumber *) theTime stretchFirstAndLast: (BOOL) stretchFirstAndLast
{
	return [self propertiesForTime: theTime stretchFirstAndLast: stretchFirstAndLast timeQualification: nil];
}

- (NSDictionary *) propertiesForTime: (NSNumber *) theTime
{
	return [self propertiesForTime: theTime stretchFirstAndLast: NO timeQualification: nil];
}

- (KeyframeMO *) ensureKeyframeForTime: (NSNumber *) newTime timeQualification: (KeyframeAnimationTimeQualification *) outTimeQualification
{
	KeyframeMO *startKeyframe = nil;
	KeyframeMO *nextKeyframe = nil;
	KeyframeMO *newKeyframe = nil;
	
	NSTimeInterval timeBetween = 0.0;
	CGFloat fraction = 0.0;
	

	KeyframeAnimationTimeQualification timeQualification = [self getStartKeyframe:&startKeyframe nextKeyframe: &nextKeyframe nearestKeyframe: nil timeBetween: &timeBetween fraction: &fraction forTime: newTime];

	NSNumber *tweenTime = nil;

	if(debug) { NSLog(@"%@ ensure at %@ qualifies as %ld", [self class], newTime, (long) timeQualification); }

	if( KeyframeAnimationIsTimeQualificationInsideKeyframes( timeQualification ) ) {
	
		if( KeyframeAnimationIsTimeQualificationOnKeyframe( timeQualification ) ) {
			if( debug ) { NSLog(@"%@ ensured an existing keyframe at %@", [self class], newTime); }

			OUT_VALUE_ASSIGN(outTimeQualification, timeQualification);

			return startKeyframe;
		}
		
		tweenTime = newTime;
		if(debug) { NSLog(@"%@ using tweened properties at %@", [self class], tweenTime); }
		
	} else {

		NSArray *orderedKeyframeTimes = [self valueForKeyPath: @"orderedKeyframes.time"];

		NSNumber *firstKeyframeTime = ( 0 != [orderedKeyframeTimes count] ) ? [orderedKeyframeTimes objectAtIndex: 0] : nil;
	
		if( nil == firstKeyframeTime ) {
			tweenTime = nil;
		} else {

			if( NSOrderedAscending == [newTime compare: firstKeyframeTime] ) {
				tweenTime = firstKeyframeTime;
				if( debug ) { NSLog(@"%@ using properties from first keyframe at %@", [self class], tweenTime); }
			} else {
				tweenTime = [orderedKeyframeTimes lastObject];
				if( debug ) { NSLog(@"%@ using properties from last keyframe at %@", [self class], tweenTime); }
			}
		}
	}

	newKeyframe = (KeyframeMO *) [NSEntityDescription insertNewObjectForEntityForName: @"Keyframe" inManagedObjectContext: [self managedObjectContext]];
	newKeyframe.time = newTime;

	if( nil != tweenTime ) { // we have no keyframe covering the new point in time
		newKeyframe.properties = [NSMutableDictionary dictionaryWithDictionary: [self propertiesForTime: tweenTime]];
	} else {
		newKeyframe.properties = [[newKeyframe class] defaultProperties];
	}

	[[self mutableSetValueForKey: @"keyframes"] addObject: newKeyframe];

	if( debug ) {
		//NSLog(@"%@ created keyframe at %@ with %@ properties: %@", [self class], newTime, tweenTime ? @"derived" : @"default", newKeyframe.properties);			
		NSLog(@"%@ created keyframe at %@ with %@ properties", [self class], newTime, tweenTime ? @"derived" : @"default");			
	}

	OUT_VALUE_ASSIGN(outTimeQualification, timeQualification);

	return newKeyframe;
}

- (KeyframeMO *) ensureKeyframeForTime: (NSNumber *) newTime
{
	return [self ensureKeyframeForTime: newTime timeQualification: nil];
}

- (BOOL) scaleGeometricPropertiesBy: (CGSize) scale 
{
	if( 0 == scale.width || 0 == scale.height ) {
		NSLog(@"not patching KeyFrameAnimation because of zero scale dimension");
		return NO;
	}
	
	if( 1.0 == scale.width && 1.0 == scale.height ) {
		return YES;
	}

	for( KeyframeMO *keyframe in self.keyframes) {
		[keyframe scaleGeometricPropertiesBy: scale];
	}

	return YES;
}

@end
