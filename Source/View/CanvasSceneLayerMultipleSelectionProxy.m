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

#import "CanvasSceneLayerMultipleSelectionProxy.h"

@implementation CanvasSceneLayerMultipleSelectionProxy

@synthesize layers=_layers, 
			frame=_frame, 
			rotation=_rotation;


#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithLayers:(NSArray *)layers{
	if (self = [super init]){
		_layers = [layers retain];
		[self updateFrame];
	}
	return self;
}

- (void)dealloc{
	[_layers release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)setLayers:(NSArray *)theLayers{
	NSAssert([theLayers count] > 0, @"Layers count must be greater than zero");
	[theLayers retain];
	[_layers release];
	_layers = theLayers;
	[self updateFrame];
}

- (CGPoint)position{
	return _frame.origin;
}

- (CGRect)bounds{
	return (CGRect){CGPointZero, _frame.size};
}

- (CGPoint)anchorPoint{
	return CGPointZero;
}

- (BOOL)hidden{
	return NO;
}

- (CGPoint)rotationCenter{
	CGPoint anchor = (CGPoint){0.5f, 0.5f};
	return (CGPoint){CGRectGetWidth(self.bounds) * anchor.x, 
		CGRectGetHeight(self.bounds) * anchor.y};
}

- (void)updateFrame{
	[self willChangeValueForKey:@"bounds"];
	for (NSInteger i = 0; i < [_layers count]; i++){
		CanvasSceneLayer *layer = [_layers objectAtIndex:i];
		CGRect itemFrame = layer.frame;
		if (i == 0){
			_frame = itemFrame;
		}else{
			_frame = CGRectUnion(_frame, itemFrame);
		}
	}
	[self didChangeValueForKey:@"bounds"];
	self.rotation = 0.0f;
}
@end
