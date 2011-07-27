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

#import "GeometryTransformers.h"

#import <EngineRoom/CrossPlatform_Utilities.h>

@implementation CGPointValueToDictionaryTransformer

+ (Class)transformedValueClass { return [NSDictionary class]; }

+ (BOOL)allowsReverseTransformation { return YES; }

- (id)transformedValue:(id)value {

	if( nil == value || NSIsControllerMarker( value ) ) {
		return value;
	}

	NSDictionary *dict = UTIL_AUTORELEASE_CF_AS_ID( CGPointCreateDictionaryRepresentation( [value CGPointValue] ) ); 

	return dict;
}

- (id)reverseTransformedValue:(id)dict {

	if( nil == dict ) {
		return nil;
	}

	NSValue *value = nil;
	CGPoint point;

	if( YES == CGPointMakeWithDictionaryRepresentation( (CFDictionaryRef) dict, &point ) ) {
		value = [NSValue valueWithCGPoint: point];
	}

	return value;
}

@end


@implementation CGRectValueToDictionaryTransformer

+ (Class)transformedValueClass { return [NSDictionary class]; }

+ (BOOL)allowsReverseTransformation { return YES; }

- (id)transformedValue:(id)value {

	if( nil == value || NSIsControllerMarker( value ) ) {
		return value;
	}

	NSDictionary *dict = UTIL_AUTORELEASE_CF_AS_ID( CGRectCreateDictionaryRepresentation( [value CGRectValue] ) ); 

	return dict;
}

- (id)reverseTransformedValue:(id)dict {

	if( nil == dict ) {
		return nil;
	}

	NSValue *value = nil;
	CGRect rect;

	if( YES == CGRectMakeWithDictionaryRepresentation( (CFDictionaryRef) dict, &rect ) ) {
		value = [NSValue valueWithCGRect: rect];
	}

	return value;
}
@end


@implementation RadiansToDegreesTransformer

+ (Class)transformedValueClass{
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation{
	return YES;
}

- (id)transformedValue:(id)value{
	if (value == nil)
		return [NSNumber numberWithFloat:0.0f];
	CGFloat radians = [(NSNumber *)value floatValue];
//	if (radians < 0) radians = M_PI * 2 + radians;
	return [NSNumber numberWithFloat:NSMRadToDeg(radians)];
}

- (id)reverseTransformedValue:(id)value{
	if (value == nil)
		return [NSNumber numberWithFloat:0.0f];
	CGFloat degrees = [(NSNumber *)value floatValue];
/*	if (degrees > 180) degrees = -degrees;
    /180 * -pi
    * -pi / 180
*/    
	return [NSNumber numberWithFloat:NSMDegToRad(degrees)];
}

@end
