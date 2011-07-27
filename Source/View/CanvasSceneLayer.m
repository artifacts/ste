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

#import "CanvasSceneLayer.h"

#import <EngineRoom/CrossPlatform_Utilities.h>
#import "BKColor.h"
#import "AssetMO.h"
#import "MediaContainer.h"

@interface CanvasSceneLayer (Private)
- (void)_updateProperties;
@end

@implementation CanvasSceneLayer

@synthesize representedObject=m_representedObject, 
			selected=m_selected,
			currentTimeProvider=m_currentTimeProvider, 
			rotation=m_rotation;
			
+ (id)layerWithItem:(id)item currentTimeProvider: (id) currentTimeProvider
{
	CanvasSceneLayer *layer = [self layer];

	layer.currentTimeProvider = currentTimeProvider;

	layer.representedObject = item;
	layer.name = [item valueForKey: @"name"];
	layer.anchorPoint = CGPointZero;
	//NSLog(@"%@ construct layer %p %@", [layer class], layer, layer.name);
	return layer;
}

- (void) shutdown
{
	// otherwise we would operate on layers being deallocated
	[self setRepresentedObject: nil update: NO];
}

- (void) removeFromSuperlayer
{
	//NSLog(@"remove from superlayer: %@", self.name);
	[self shutdown];
	[super removeFromSuperlayer];
}

- (void)dealloc{
	// may also happen for internal copies made by CA
	//NSLog(@"%@ dealloc layer %p %@", [self class], self, self.name);
	[self shutdown];
	[m_currentTimeProvider release];
	[super dealloc];
}

- (void)setSelected:(BOOL)bFlag{
	m_selected = bFlag;
}

- (void)setRepresentedObject:(id) item
{
	[self setRepresentedObject: item update: YES];
}

- (void)setRepresentedObject:(id) item update: (BOOL) doUpdate
{
	NSArray *observedKeys = [NSArray arrayWithObjects: 
		@"hidden", 
		@"viewPosition", 
// observing anything primaryBlob is problematic during willTurnIntoFault of the blob
// 		@"primaryBlob.cachedData",
//		@"primaryBlob.renderQuality",
// 		@"primaryBlob.mediaContainer.renderedCGImage", 
		 @"keyframeAnimation.keyframes", 
		nil]; 

	if (nil != m_representedObject) {

		NSLog(@"un-observing asset %@ %p (pBlob: %@)", [m_representedObject valueForKey: @"name"], m_representedObject, [m_representedObject valueForKey: @"primaryBlob"]);

		[self.currentTimeProvider removeObserver: self forKeyPath: @"currentTime"];
	
		[[NSNotificationCenter defaultCenter] removeObserver: self];

		for (NSString *key in observedKeys) {
			[m_representedObject removeObserver:self forKeyPath:key];
		}

		[m_representedObject autorelease];
	}

	m_representedObject = [item retain];

	if (item != nil) {

		NSLog(@"observing asset %@ %p (pBlob: %@)", [m_representedObject valueForKey: @"name"], m_representedObject, [m_representedObject valueForKey: @"primaryBlob"]);
	
		for (NSString *key in observedKeys) {
			[m_representedObject addObserver:self forKeyPath:key options:0 context:NULL];
		}

		[self.currentTimeProvider addObserver:self forKeyPath:@"currentTime" options:0 context:NULL];

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(propertiesAffected:) name: kModelAccessPropertiesAffectedNotification object: nil];

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(objectsDidChange:) name: NSManagedObjectContextObjectsDidChangeNotification object: nil];
	}

	if( doUpdate ) {
		[self _updateProperties];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context
{
	NSLog(@"%@ (%@) propertyChange: %@", [self class], self.name, keyPath);
	[self _updateProperties];
}

- (void) objectsDidChange: (NSNotification *) n
{
	NSLog(@"objectsDidChange: received for %p - %@", [n object], [n userInfo]);
	[self _updateProperties];
}

- (void) propertiesAffected: (NSNotification *) n
{
	id sender = [n object];

	//NSLog(@"PropertiesAffected received for %p", sender);
	if( nil == sender || [[self.representedObject valueForKeyPath: @"keyframeAnimation.keyframes"] containsObject: sender] ) {
		//NSLog(@"our keyframe, updating");
		[self _updateProperties];
	} else {
		//NSLog(@"not our keyframe");
	}
}

- (CGPoint)rotationCenter{
	CGPoint anchor = (CGPoint){0.5f, 0.5f};
	return (CGPoint){CGRectGetWidth(self.bounds) * anchor.x, 
		CGRectGetHeight(self.bounds) * anchor.y};
}

- (void)_updateProperties{

	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	AssetMO *item = self.representedObject;
	
	if( nil == item ) {
		
		self.hidden = YES;
		
	} else {
		
		//NSLog(@"layer %@ z: %f h: %d", self.name, self.zPosition, self.hidden);
		
		NSNumber *currentTime = [self.currentTimeProvider valueForKey: @"currentTime"];
		
		NSDictionary *currentProperties = [item.keyframeAnimation propertiesForTime: currentTime];
		
		if( nil == currentProperties ) { // out of keyframe covered region
			
			self.hidden = YES; 
			
		} else {
			
			ExternalDataMO *BLOB = item.primaryBlob;
			
			MediaContainer *mediaContainer = BLOB.mediaContainer;
			
			if( YES == mediaContainer.loaded ) {
				
				CGImageRef newImage = [mediaContainer renderedCGImage];
				
				if( (void*) newImage != self.contents ) {
					lpkdebug("mediaContainer", newImage, mediaContainer.renderQuality);
					self.contents = (void*) newImage;
					
					if( NULL != newImage ) {
						
						[item obtainInitialAttributesIfNeeded];
						
						currentProperties = [item.keyframeAnimation propertiesForTime: currentTime];
						
					} // non null image
					
				} else {
					lpkdebug("mediaContainer", "image unchanged", mediaContainer.renderQuality);
				} // different image?
				
			} // media loaded?
			
			self.affineTransform = CGAffineTransformIdentity;
			
			self.hidden = [[item valueForKey: @"hidden"] boolValue];
			self.position = [[currentProperties valueForKey: @"position"] CGPointValue];
			self.bounds = [[currentProperties valueForKey: @"bounds"] CGRectValue];
			self.zPosition = [[item valueForKey: @"viewPosition"] floatValue];
			self.opacity = [[currentProperties valueForKey: @"opacity"] floatValue];
			self.backgroundColor = [(BKColor *)[currentProperties 
												valueForKey:@"backgroundColor"] CGColor];
			
			CGPoint anchor = self.rotationCenter;			
			[self willChangeValueForKey:@"rotation"];
			m_rotation = [[currentProperties valueForKey:@"rotation"] floatValue];
			CGAffineTransform transform = CGAffineTransformMakeTranslation(
																		   anchor.x, anchor.y);
			/*BOOL clockwiseRotation = [[currentProperties valueForKey: @"clockwiseRotation"] boolValue];

			if (clockwiseRotation == NO) {
				transform = CGAffineTransformRotate(transform, m_rotation * -1);
			} else {
				transform = CGAffineTransformRotate(transform, m_rotation);			
			}*/

			transform = CGAffineTransformRotate(transform, m_rotation);			
			transform = CGAffineTransformTranslate(transform, -anchor.x, 
												   -anchor.y);
			self.affineTransform = transform;
			[self didChangeValueForKey:@"rotation"];
		}
	}
	[CATransaction commit];	
}

@end

