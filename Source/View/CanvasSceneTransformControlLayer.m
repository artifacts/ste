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

// if set to 1 the transform layer becomes invisible
// when the target is out of keyframe coverage 
// BK: you can pry the 0 setting from my cold dead hands
#define TRANSFORM_CONTROL_LAYER_HIDES_WITH_TARGET 0

#import "CanvasSceneTransformControlLayer.h"

@interface CanvasSceneTransformControlLayer (Private)
- (void)_createHandles;
- (CALayer *)_makeHandle:(NSString *)type size:(CGFloat)size;
- (void)_update;
@end

@implementation CanvasSceneTransformControlLayer

@synthesize target=m_target;


#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super init]){
		[self _createHandles];
		[self setNeedsDisplay];
		self.anchorPoint = CGPointZero;
		m_target = nil;
	}
	return self;
}

- (void)dealloc{
	// need accessor side effects
	self.target = nil;
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)setTarget:(CanvasSceneLayer *)newTarget{
	if (m_target == newTarget)
		return;
	
	NSMutableSet *keys = [NSMutableSet setWithObjects:@"position", @"bounds", @"anchorPoint", 
		@"rotation", nil];
	#if TRANSFORM_CONTROL_LAYER_HIDES_WITH_TARGET
		[keys addObject:@"hidden"];
	#endif
	
	for (NSString *key in keys){
		[m_target removeObserver:self forKeyPath:key];
		[newTarget addObserver:self forKeyPath:key options:0 context:NULL];
	}
	
	[m_target release];
	m_target = [newTarget retain];
	[self _update];
}

- (NSCursor *)cursorAtPoint:(CGPoint)point{
	return [NSCursor arrowCursor];
/*	imgs missing
	CanvasTransformAction action;
	CanvasHandleEdge edge;
	[self action:&action edge:&edge atPoint:point];
	
	if (action == kCanvasTransformActionMove){
		return [NSCursor openHandCursor];
	}if (action == kCanvasTransformActionResize && edge > 3){
		edge -= 4;
	}
	
	NSString *imgName = [NSString stringWithFormat:@"%@%d.tiff", 
		(action == kCanvasTransformActionResize ? @"Resize" : @"Rotate"), edge];
	NSImage *img = [NSImage imageNamed:imgName];
	return [[[NSCursor alloc] initWithImage:img hotSpot:(NSPoint){[img size].width / 2.0f, 
		[img size].height / 2.0f}] autorelease];
*/
}

- (void)action:(CanvasTransformAction *)action edge:(CanvasHandleEdge *)edge 
	atPoint:(CGPoint)point{
	CALayer *hitLayer = [self hitTest:point];
	if (!hitLayer || hitLayer == self){
		if (action != NULL) *action = kCanvasTransformActionNone;
	}else if (hitLayer == m_boundsLayer){
		if (action != NULL) *action = kCanvasTransformActionMove;
	}else{
		if (edge != NULL) *edge = [hitLayer.name intValue];
		if (action != NULL){
			*action = [hitLayer superlayer] == m_rotationHandlesLayer 
				? kCanvasTransformActionRotate 
				: kCanvasTransformActionResize;
		}
	}
}



#pragma mark -
#pragma mark CALayer methods

- (CALayer *)hitTest:(CGPoint)thePoint{
	CALayer *hitLayer = [m_resizeHandlesLayer 
		hitTest:[self convertPoint:thePoint fromLayer:[self superlayer]]];
	if (hitLayer && hitLayer != m_resizeHandlesLayer)
		return hitLayer;
	
	hitLayer = [m_boundsLayer 
		hitTest:[self convertPoint:thePoint fromLayer:[self superlayer]]];
	if (hitLayer)
		return m_boundsLayer;
	
	hitLayer = [m_rotationHandlesLayer 
		hitTest:[self convertPoint:thePoint fromLayer:[self superlayer]]];
	if (hitLayer && hitLayer != m_rotationHandlesLayer)
		return hitLayer;
	
	return nil;
}

- (void)layoutSublayers{
	CGRect bounds = m_target.bounds;
	
	CGSize size = bounds.size;
	CGFloat rotation = m_target.rotation;
	size_t numHandles = 8;
	
	CGPoint points[8] = {
		0, 0, 
		floorf(size.width / 2), 0, 
		size.width, 0, 
		size.width, floorf(size.height / 2), 
		size.width, size.height, 
		floorf(size.width / 2), size.height, 
		0, size.height, 
		0, floorf(size.height / 2)
	};
	
	CGPoint center = m_target.rotationCenter;
	CGPoint *rotatedPoints = malloc(sizeof(CGPoint) * 8);
	memcpy(rotatedPoints, points, sizeof(CGPoint) * 8);
	NSMRotatePointsAroundPoint(rotatedPoints, center, rotation, numHandles);
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	for (int i = 0; i < numHandles; i++){
		CGPoint point = points[i];
		point.x = floorf(point.x);
		point.y = floorf(point.y);
		CGPoint rotatedPoint = rotatedPoints[i];
		rotatedPoint.x = floorf(rotatedPoint.x);
		rotatedPoint.y = floorf(rotatedPoint.y);
		
		CALayer *layer = [[m_rotationHandlesLayer sublayers] objectAtIndex:i];
		layer.position = point;
		layer = [[m_resizeHandlesLayer sublayers] objectAtIndex:i];
		layer.position = point;
		layer = [[m_handlesLayer sublayers] objectAtIndex:i];
		layer.position = rotatedPoint;
	}
	[CATransaction commit];
	
	free(rotatedPoints);
}



#pragma mark -
#pragma mark Private methods

- (void)_createHandles{
	m_rotationHandlesLayer = [CALayer layer];
	m_rotationHandlesLayer.anchorPoint = CGPointZero;
	[self addSublayer:m_rotationHandlesLayer];
	
	CGColorRef boundsBorderColor = CGColorCreateGenericRGB(0.0f, 1.0f, 1.0f, 1.0f);
	m_boundsLayer = [CALayer layer];
	m_boundsLayer.anchorPoint = CGPointZero;
	m_boundsLayer.borderWidth = 1.0f;
	m_boundsLayer.borderColor = boundsBorderColor;
	[self addSublayer:m_boundsLayer];
	CGColorRelease(boundsBorderColor);
	
	m_resizeHandlesLayer = [CALayer layer];
	m_resizeHandlesLayer.anchorPoint = CGPointZero;
	[self addSublayer:m_resizeHandlesLayer];
	
	m_handlesLayer = [CALayer layer];
	m_handlesLayer.anchorPoint = CGPointZero;
	[self addSublayer:m_handlesLayer];
	
	CGColorRef indicatorFillColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f);
	CGColorRef indicatorBorderColor = CGColorCreateGenericRGB(0.31f, 0.5f, 1.0f, 1.0f);
	
	for (int i = 0; i < 8; i++){
		NSString *type = [[NSNumber numberWithInt:i] stringValue];
		
		// rotation handle
		CALayer *handle = [self _makeHandle:type size:25.0f];
		[m_rotationHandlesLayer addSublayer:handle];
		
		// resize handle
		handle = [self _makeHandle:type size:10.0f];
		[m_resizeHandlesLayer addSublayer:handle];
		
		// handle indicator
		handle = [self _makeHandle:type size:6.0f];
		handle.backgroundColor = indicatorFillColor;
		handle.borderColor = indicatorBorderColor;
		handle.borderWidth = 1.0f;
		[m_handlesLayer addSublayer:handle];
	}
	
	CGColorRelease(indicatorFillColor);
	CGColorRelease(indicatorBorderColor);
}

- (CALayer *)_makeHandle:(NSString *)type size:(CGFloat)size{
	CGRect frame = (CGRect){0, 0, size, size};
	CALayer *handle = [CALayer layer];
	handle.frame = frame;
	handle.name = type;
	return handle;
}


- (void)_update{
	CGRect bounds = m_target.bounds;
	bounds.size.width = floorf(bounds.size.width);
	bounds.size.height = floorf(bounds.size.height);
	
	CGPoint position = (CGPoint){floorf(m_target.position.x), floorf(m_target.position.y)};
	CGPoint center = m_target.rotationCenter;
	CGFloat rotation = m_target.rotation;
	
	CGAffineTransform transform = CGAffineTransformMakeTranslation(center.x, center.y);
	transform = CGAffineTransformRotate(transform, rotation);
	transform = CGAffineTransformTranslate(transform, -center.x, -center.y);
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	self.position = position;
	self.bounds = m_resizeHandlesLayer.bounds = m_rotationHandlesLayer.bounds = 
		m_boundsLayer.bounds = bounds;
	m_resizeHandlesLayer.affineTransform = m_rotationHandlesLayer.affineTransform = 
		m_boundsLayer.affineTransform = transform;
	[CATransaction commit];
	
	m_currentCenterLayer.position = m_target.rotationCenter;
	m_realCenterLayer.position = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
	
	[self setNeedsLayout];
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context{
	[self _update];
}
@end
