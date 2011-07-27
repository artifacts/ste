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

#import "KeyframeMO.h"
#import <EngineRoom/CrossPlatform_Utilities.h>
#import "BKColor.h"

@implementation KeyframeMO

@dynamic time;

// fix for the "easing" property, which was added in RC3.5. Will add the property to older ST-Documents.
- (void) thawProperties
{
	[super thawProperties];
	if ([self.properties objectForKey:@"easing"] == nil) {
		[self.properties setObject:[NSNumber numberWithInt:0] forKey:@"easing"];
	}
}


- (NSSet *) keysToExcludeFromDictionaryRepresentationInContext: (void *) context
{
	return [NSSet setWithObjects: @"keyframeAnimation", nil];
}

+ (NSMutableDictionary *) defaultProperties
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[BKColor colorWithGenericRGBAString: @"#ffffff00"], @"backgroundColor",
		[NSNumber numberWithFloat: 1.0], @"opacity",
		[NSNumber numberWithFloat: 0.0], @"rotation",			
		[NSValue valueWithCGRect: CGRectZero], @"bounds",
		[NSValue valueWithCGPoint: CGPointZero], @"position",
	nil];
}

- (CGRect)rotatedFrame{
	CGRect frame = (CGRect){[[self valueForKey:@"position"] CGPointValue], 
		[[self valueForKey:@"bounds"] CGRectValue].size};
	CGFloat rotation = [[self valueForKey:@"rotation"] floatValue];
	CGPoint anchor = (CGPoint){0.5f, 0.5f};
	CGPoint center = (CGPoint){CGRectGetMinX(frame) + CGRectGetWidth(frame) * anchor.x,	
		CGRectGetMinY(frame) + CGRectGetHeight(frame) * anchor.y};
	frame = NSMRectByRotatingRectAroundPoint(frame, center, rotation);
	return frame;
}

- (BOOL) scaleGeometricPropertiesBy: (CGSize) scale 
{
	if( 0 == scale.width || 0 == scale.height ) {
		NSLog(@"not patching KeyFrame because of zero scale dimension");
		return NO;
	}
	
	if( 1.0 == scale.width && 1.0 == scale.height ) {
		return YES;
	}
	
	CGRect bounds = [[self valueForKey: @"bounds"] CGRectValue];
	CGPoint position = [[self valueForKey: @"position"] CGPointValue];
	
	bounds.origin.x *= scale.width;
	bounds.origin.y *= scale.height;
	bounds.size.width *= scale.width;
	bounds.size.height *= scale.height;
	
	position.x *= scale.width;						
	position.y *= scale.height;		
	
	[self setValue: [NSValue valueWithCGRect: bounds] forKey: @"bounds"];
	[self setValue: [NSValue valueWithCGPoint: position] forKey: @"position"];

	return YES;
}	


@end
