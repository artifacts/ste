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

#import "ModelAccess.h"

static const char *kCoalescedSelectorPrefix = "coalesced";

@implementation NSObject (StoryTellingModelObserver)

- (NSString *) modelAccessKeyPath 
{
	return @"representedObject";
}

- (NSDictionary *) modelAccessObservations
{
	NSString *cacheKey = NSStringFromClass([self class]);

	static NSMutableDictionary *cachedObservations = nil;
	
	if( nil == cachedObservations ) {
		cachedObservations = [[NSMutableDictionary alloc] init];
	}

	NSDictionary *observationsForClass = [cachedObservations objectForKey: cacheKey];

	if( nil == observationsForClass ) {
	
		NSString *modelAccessKeyPath = [self modelAccessKeyPath];

		/* if a selector starts with "coalesced" (kCoalescedSelectorPrefix) 
		 * then it is first canceled from the runloop, then added with a delay of 0.0 (and a nil argument) to coalesce it
		 * therefore: no : in colaesced selectors
		 */

		observationsForClass = [NSDictionary dictionaryWithObjectsAndKeys:
			@"coalescedStageDidChange:", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessStageSelectionKeyPath, nil),
			@"assetsParent:didChange:", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessAssetsKeyPath, @"parent"),
			@"assets:didChange:", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessAssetsKeyPath, nil),
			@"assetsHidden:didChange:", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessAssetsKeyPath, @"hidden"),
			@"selectedAssets:didChange:", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessSelectedAssetsKeyPath, nil),
			@"keyframes:didChange:", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessKeyframesKeyPath, nil),
			@"keyframesTime:didChange:", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessKeyframesKeyPath, @"time"),
			@"selectedKeyframes:didChange:", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessSelectedKeyframesKeyPath, nil),
			@"coalescedUnionOfSceneKeyframesTimeDidChange", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessUnionOfSceneKeyframesKeyPath, @"time"),
			@"coalescedSceneKeyframesPropertiesDidChange", GENERIC_MODEL_KEYPATH(modelAccessKeyPath, kModelAccessUnionOfSceneKeyframesKeyPath, @"properties"),
		nil];

		[cachedObservations setObject: observationsForClass forKey: cacheKey];
	}
	
	return observationsForClass;
}

- (void) setModelAccessObservingState: (BOOL) doObserve
{
	NSDictionary *observations = [self modelAccessObservations];

	for( NSString *modelAccessKeyPath in [self modelAccessObservations] ) {

		NSString *selectorName = [observations objectForKey: modelAccessKeyPath];
		SEL selector = NSSelectorFromString(selectorName);
		
		//NSLog(@"%@ checking for %@", [self class], selectorName);

		if( [self respondsToSelector: selector] ) {
		
			//NSLog(@"%@ %@observing %@", [self class], doObserve ? @"" : @"un-", modelAccessKeyPath);		
		
			if( doObserve ) {
				[self addObserver:self forKeyPath: modelAccessKeyPath options: NSKeyValueObservingOptionInitial context: selector];
			} else {
				[self removeObserver:self forKeyPath: modelAccessKeyPath];
			}
		}
	}
}

- (BOOL) processModelAccessObservationForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if( nil == [[self modelAccessObservations] objectForKey: keyPath] ) {
		return NO;
	}

	SEL selector = (SEL) context;

	//NSLog(@"%@ process: %@ kind %@ - %@ SEL: %@", [self class], keyPath, [change valueForKey: NSKeyValueChangeKindKey], change, NSStringFromSelector(selector));

	const char *selName = sel_getName( selector );

	if( NULL != selName && 0 == strncmp( selName, kCoalescedSelectorPrefix, sizeof(kCoalescedSelectorPrefix) - 1 ) ) {
		NSLog(@"coalesced trigger of %s", selName);
		[[self class] cancelPreviousPerformRequestsWithTarget: self selector: selector object: nil];
		[self performSelector: selector withObject: nil afterDelay: 0.0];
	} else {
		NSLog(@"immediate trigger of %s", selName);
		[self performSelector: selector withObject: [self valueForKeyPath: keyPath] withObject: change];
	}

	return YES;
}

@end

