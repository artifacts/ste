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

#import "AssetEditor.h"
#import <EngineRoom/EngineRoom.h>
#import "BKColor.h"

@implementation AssetEditor

@synthesize currentTime = _currentTime;
@synthesize currentAsset = _currentAsset;
@synthesize changeCount = _changeCount;


- (id) init
{
	if( ( self = [super init] ) ) {
		_changeCount = 0;

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(objectsDidChange:) name: NSManagedObjectContextObjectsDidChangeNotification object: nil];
	}

	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[_currentTime release];
	[_currentAsset release];
	[super dealloc];
}

- (void) objectsDidChange: (NSNotification *) n
{
	self.changeCount++;
	//NSLog(@"changeCount: %ld", (long) self.changeCount);
}


+ (BOOL) isAssetKey: (NSString *) key
{
	static NSSet *cachedAssetKeys = nil;
	if( nil == cachedAssetKeys ) {
		cachedAssetKeys = [[NSSet alloc] initWithObjects: @"name", @"blobRefs", @"hidden", @"viewPosition", nil];
	}

	return [cachedAssetKeys containsObject: key] ? YES : NO;
}

+ (NSSet *) keyPathsForValuesAffectingCurrentTimeIsOnKeyframe 
{ 
	return [NSSet setWithObjects: @"currentTime", @"currentAsset", @"changeCount", nil];
}

- (BOOL) currentTimeIsOnKeyframe
{
	AssetMO *theAsset = self.currentAsset;
	NSNumber *theTime = self.currentTime;
	
	if( nil == theTime || nil == theAsset || NSIsControllerMarker( theAsset ) ) {
		return NO;
	}
	
	return [theAsset.keyframeAnimation keyframeForTime: theTime] ? YES : NO;
}


+ (NSSet *) keyPathsForValuesAffectingValueForKey: (NSString *)key
{
	NSSet *ourOwnKeys = [NSSet setWithObjects: @"currentTime", @"currentAsset", @"changeCount", @"hidden", nil];

	NSSet *superKeys = [super keyPathsForValuesAffectingValueForKey: key];

	NSSet *result = nil;

	if( [ourOwnKeys containsObject: key] ) { // no dependencies
		result = superKeys;
	} else {
	
		if([self isAssetKey: key]) {
			result = [NSSet setWithObject: [@"currentAsset" stringByAppendingPathExtension: key]];
		} else {
			NSSet *keysIncludingKeyFrame = [ourOwnKeys setByAddingObjectsFromSet: [KeyframeMO keyPathsForValuesAffectingValueForKey: key]];

			result = [superKeys setByAddingObjectsFromSet: keysIncludingKeyFrame];
		}
	}

	// NSLog(@"%@: %@ depends on %@", self, key, [[result description] stringByReplacingOccurrencesOfString:@"\n" withString: @" "]);

	return result;
}

- (void) setValue: (id) value forUndefinedKey: (NSString *)key
{
	if( [[self class] isAssetKey: key] ) {
		[self.currentAsset setValue: value forKey: key];
		return;
	} 

	KeyframeAnimationMO *keyframeAnimation = self.currentAsset.keyframeAnimation;

	KeyframeMO *keyframe = [keyframeAnimation ensureKeyframeForTime: self.currentTime];

	[keyframe setValue: value forKey: key];
}

// internal feature: if key is nil, we return the timedProperties - do not use externally
- (id) valueForUndefinedKey: (NSString *)key
{
	NSNumber *theTime = self.currentTime;
	AssetMO *theAsset = self.currentAsset;	

	//NSLog(@"ASK: %@ for %@ @ %@", key, self.currentAsset.name, self.currentTime);

	if( nil == theAsset ) {
		//NSLog(@"ret: a nil");
		return nil;
	}

	if( NSNotApplicableMarker == theAsset ) {
		//NSLog(@"ret: a N/A");
		return NSNotApplicableMarker;
	}
	
	if( NSNoSelectionMarker == theAsset || NSMultipleValuesMarker == theAsset ) {
		//NSLog(@"ret: a %@", theAsset == NSNoSelectionMarker ? @"NoSel" : @"Multi");
		return theAsset;
	}
	
	if( nil != key && [[self class] isAssetKey: key] ) {
		return [theAsset valueForKey: key];
	} 

	if( nil == theTime ) {
		// NSLog(@"ret: t nil");
		return nil;
	}

	NSDictionary *timedProperties = [theAsset.keyframeAnimation propertiesForTime: theTime stretchFirstAndLast: YES];
	
	return timedProperties ? ( key ? [timedProperties valueForKey: key] : timedProperties ) : nil;
}

- (NSDictionary *) currentTimedProperties
{
	// using internal voodoo-feature
	return [self valueForUndefinedKey: nil];
}

@end
