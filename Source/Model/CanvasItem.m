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

#import "CanvasItem.h"


@implementation CanvasItem

@synthesize frame, backgroundImage, cornerRadius, backgroundColor, backgroundImagePosition, 
	shadowColor, shadowOpacity, shadowRadius, shadowXOffset, shadowYOffset;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super init]){
		self.backgroundColor = [NSColor darkGrayColor];
		self.shadowColor = [NSColor blackColor];
		self.shadowOpacity = 0.5;
		self.shadowXOffset = 3.0;
		self.shadowYOffset = -3.0;
		self.shadowRadius = 5.0;
		self.backgroundImagePosition = CGPointZero;
	}
	return self;
}

- (void)dealloc{
	[backgroundImage release];
	[backgroundColor release];
	[shadowColor release];
	[super dealloc];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	NSSet *affectedKeys = nil;
	
    if ([key isEqualToString:@"xPosition"] || 
		[key isEqualToString:@"yPosition"] || 
		[key isEqualToString:@"position"]){
		affectedKeys = [NSSet setWithObjects:@"xPosition", @"yPosition", @"position", @"frame", nil];
	}else if ([key isEqualToString:@"frameWidth"] || 
		[key isEqualToString:@"frameHeight"] || 
		[key isEqualToString:@"size"]){
		affectedKeys = [NSSet setWithObjects:@"frameWidth", @"frameHeight", @"size", @"frame", nil];
	}else if ([key isEqualToString:@"frame"]){
		affectedKeys = [NSSet setWithObjects:@"frameWidth", @"frameHeight", @"size", 
			@"xPosition", @"yPosition", @"position", nil];
	}else if ([key isEqualToString:@"shadowColor"] ||
		[key isEqualToString:@"shadowOpacity"] || 
		[key isEqualToString:@"shadowXOffset"] || 
		[key isEqualToString:@"shadowYOffset"] || 
		[key isEqualToString:@"shadowRadius"]){
		affectedKeys = [NSSet setWithObjects:@"shadowColor", @"shadowOpacity", @"shadowXOffset", 
			@"shadowYOffset", @"shadowRadius", nil];
	}
	
	affectedKeys = [affectedKeys objectsPassingTest:^BOOL(id obj, BOOL *stop){
		return ![obj isEqualToString:key];}];
	keyPaths = [keyPaths setByAddingObjectsFromSet:affectedKeys];
	return keyPaths;
}

- (CGFloat)frameWidth{
	return frame.size.width;
}

- (void)setFrameWidth:(CGFloat)width{
	self.size = (CGSize){width, frame.size.height};
}

- (CGFloat)frameHeight{
	return frame.size.height;
}

- (void)setFrameHeight:(CGFloat)height{
	self.size = (CGSize){frame.size.width, height};
}

- (CGFloat)xPosition{
	return frame.origin.x;
}

- (void)setXPosition:(CGFloat)xPos{
	self.position = (CGPoint){xPos, frame.origin.y};
}

- (CGFloat)yPosition{
	return frame.origin.y;
}

- (void)setYPosition:(CGFloat)yPos{
	self.position = (CGPoint){frame.origin.x, yPos};
}

- (void)setSize:(CGSize)size{
	[self willChangeValueForKey:@"size"];
	frame.size = size;
	[self didChangeValueForKey:@"size"];
}

- (CGSize)size{
	return frame.size;
}

- (void)setPosition:(CGPoint)position{
	[self willChangeValueForKey:@"position"];
	frame.origin = position;
	[self didChangeValueForKey:@"position"];
}

- (CGPoint)position{
	return frame.origin;
}

- (void)setFrame:(CGRect)aFrame{
	[self willChangeValueForKey:@"frame"];
	frame = CGRectStandardize(aFrame);
	[self didChangeValueForKey:@"frame"];
}

- (NSXMLNode *)xmlRepresentation{
	return nil;
}
@end
