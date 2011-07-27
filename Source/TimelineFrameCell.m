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

#import "TimelineFrameCell.h"

@interface TimelineFrameCell ()
- (void)_drawInRect:(NSRect)aRect withLightColor:(CGColorRef)lightColor 
	darkColor:(CGColorRef)darkColor highlightColor:(CGColorRef)highlightColor 
	context:(CGContextRef)ctx;
- (void)_drawKeyframeIndicatorInRect:(NSRect)aRect color:(CGColorRef)color 
	shadowColor:(CGColorRef)shadowColor;
@end


static NSMutableArray *g_imageCache = nil;

enum{
	kStateDragging, 
	kStateHighlighted, 
	kStateFirstResponder, 
	kStateNormal
};

CGContextRef CreateBitmapContext(NSSize size, BOOL hasAlpha){
	int bytesPerRow = size.width * 4;
	size_t bitsPerComponent = hasAlpha ? 8 : 5;
	CGBitmapInfo bitmapInfo = hasAlpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNoneSkipFirst;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGContextRef ctx = CGBitmapContextCreate(NULL, size.width, size.height, bitsPerComponent, 
		bytesPerRow, colorSpace, bitmapInfo);
	CGColorSpaceRelease(colorSpace);
	return ctx;
}


@implementation TimelineFrameCell

@synthesize framePosition=_framePosition, 
			keyframe=_keyframe, 
			enclosingLayerIsDragged=_enclosingLayerIsDragged;

#pragma mark -
#pragma mark Initialization

- (id)init{
	if (self = [super init]){
		_framePosition = kFramePositionMiddle;
		_keyframe = NO;
		_enclosingLayerIsDragged = NO;
	}
	return self;
}



#pragma mark -
#pragma mark NSCell methods

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view{
	CGColorRef lightColor, darkColor, highlightColor;
	BOOL isFirstResponder = [[view window] firstResponder] == view && [[view window] isKeyWindow];
	CGFloat alpha = 1.0;
	if ([self isEnabled]==NO) alpha = 0.5;
	
	uint8_t state;
	frame.size.width += 1.0f;
	if (_enclosingLayerIsDragged){
		state = kStateDragging;
	}else if (![self isHighlighted]){
		state = kStateHighlighted;
	}else{
		state = isFirstResponder ? kStateFirstResponder : kStateNormal;
	}
	
	if (!g_imageCache){
		g_imageCache = [[NSMutableArray alloc] initWithObjects:
			[NSMutableArray array], // kStateDragging
			[NSMutableArray array], // kStateHighlighted
			[NSMutableArray array], // kStateFirstResponder
			[NSMutableArray array], // kStateNormal
			nil];
	}
	
	NSMutableArray *cacheForState = [g_imageCache objectAtIndex:state];
	if ([cacheForState count] == 0){
		[cacheForState addObjectsFromArray:[NSArray arrayWithObjects:
			[NSNull null], // kFramePositionLeft
			[NSNull null], // kFramePositionMiddle
			[NSNull null], // kFramePositionRight
			[NSNull null], // kFramePositionSingle
			nil]];
	}
	
	NSImage *imageToDraw = [cacheForState objectAtIndex:_framePosition];
	if ((id)imageToDraw != [NSNull null]){
		goto drawImage;
	}
	
	switch (state){
		case kStateDragging:
			lightColor = CGColorCreateGenericRGB(0.443f, 0.490f, 0.541f, 1.0f);
			darkColor = CGColorCreateGenericRGB(0.325f, 0.361f, 0.408f, 1.0f);
			highlightColor = CGColorCreateGenericRGB(0.557f, 0.596f, 0.635f, 1.0f);
			break;
			
		case kStateHighlighted:
			lightColor = CGColorCreateGenericRGB(0.706f, 0.706f, 0.706f, 1.0f);
			darkColor = CGColorCreateGenericRGB(0.724f, 0.724f, 0.724f, 1.0f);
			highlightColor = CGColorCreateGenericRGB(0.600f, 0.600f, 0.600f, 1.0f);
			break;
			
		case kStateFirstResponder:
//			lightColor = CGColorCreateGenericRGB(1.0f, 0.627f, 0.259f, 1.0f);
//			darkColor = CGColorCreateGenericRGB(1.0f, 0.498f, 0.008f, 1.0f);
//			highlightColor = CGColorCreateGenericRGB(1.0f, 0.698f, 0.408f, 1.0f);
//			break;
			
		case kStateNormal:
			lightColor = CGColorCreateGenericRGB(0.62f, 0.62f, 0.62f, alpha);
			darkColor = CGColorCreateGenericRGB(0.57f, 0.57f, 0.57f, alpha);
			highlightColor = CGColorCreateGenericRGB(0.41f, 0.41f, 0.41f, alpha);
	}
	
	
	CGContextRef ctx = CreateBitmapContext(frame.size, YES);
	if (ctx == NULL){
		NSLog(@"Could not create context!");
		return;
	}
	
	[self _drawInRect:(NSRect){NSZeroPoint, frame.size} withLightColor:lightColor darkColor:darkColor 
		highlightColor:highlightColor context:ctx];
	
	CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
	imageToDraw = [[NSImage alloc] initWithCGImage:cgImage size:frame.size];
	[cacheForState replaceObjectAtIndex:_framePosition withObject:imageToDraw];
	[imageToDraw release];
	CGImageRelease(cgImage);
	CGContextRelease(ctx);
	
	CGColorRelease(lightColor);
	CGColorRelease(darkColor);
	CGColorRelease(highlightColor);
	
drawImage:
	[imageToDraw drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver 
		fraction:alpha respectFlipped:NO hints:nil];
	
	if (!_keyframe)
		return;
		
	CGColorRef indicatorColor, indicatorShadowColor;
	if (![self isHighlighted]){
		indicatorColor = CGColorCreateGenericRGB(0.243f, 0.243f, 0.243f, alpha);
		indicatorShadowColor = CGColorCreateGenericRGB(0.192f, 0.192f, 0.192f, alpha);
	}else{
//		if (isFirstResponder){
			indicatorColor = CGColorCreateGenericRGB(0.827f, 0.2f, 0.051f, alpha);
			indicatorShadowColor = CGColorCreateGenericRGB(0.329f, 0.157f, 0.035f, alpha);
//		}else{
//			indicatorColor = CGColorCreateGenericRGB(0.2f, 0.2f, 0.2f, 1.0f);
//			indicatorShadowColor = CGColorCreateGenericRGB(0.1f, 0.1f, 0.1f, alpha);
//		}
	}
	
	[self _drawKeyframeIndicatorInRect:frame color:indicatorColor shadowColor:indicatorShadowColor];
	
	CGColorRelease(indicatorColor);
	CGColorRelease(indicatorShadowColor);
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view{
	[self drawInteriorWithFrame:frame inView:view];
}



#pragma mark -
#pragma mark Private methods

- (void)_drawInRect:(NSRect)aRect withLightColor:(CGColorRef)lightColor 
	darkColor:(CGColorRef)darkColor highlightColor:(CGColorRef)highlightColor 
	context:(CGContextRef)ctx{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGFloat *radii = nil;
	NSRect innerRect = aRect;
	switch (_framePosition){
		case kFramePositionLeft:
			radii = (CGFloat[]){0.0f, 0.0f, 3.0f, 3.0f};
			innerRect.origin.x += 1.0f;
			innerRect.size.width -= 1.0f;
			innerRect.origin.y += 1.0f;
			innerRect.size.height -= 1.0f;
			break;
		
		case kFramePositionRight:
			radii = (CGFloat[]){3.0f, 3.0f, 0.0f, 0.0f};
			innerRect.size.width -= 1.0f;
			innerRect.origin.y += 1.0f;
			innerRect.size.height -= 1.0f;
			break;
		
		case kFramePositionMiddle:
			radii = (CGFloat[]){0.0f, 0.0f, 0.0f, 0.0f};
			innerRect.origin.y += 1.0f;
			innerRect.size.height -= 1.0f;
			break;
			
		case kFramePositionSingle:
			radii = (CGFloat[]){3.0f, 3.0f, 3.0f, 3.0f};
			innerRect = NSInsetRect(aRect, 0.5f, 0.5f);
			break;
	}
	
	CGContextSaveGState(ctx);
	CGMutablePathRef path = CGPathCreateMutable();
	NSMCGPathAddRoundRectWithRadii(path, NSRectToCGRect(aRect), radii);
	CGContextAddPath(ctx, path);
	CGContextEOClip(ctx);
	
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, 
		(CFArrayRef)[NSArray arrayWithObjects:(id)highlightColor, darkColor, nil], NULL);
	CGContextDrawLinearGradient(ctx, gradient, (CGPoint){NSMinX(aRect), NSMinY(aRect)}, 
		(CGPoint){NSMinX(aRect), NSMaxY(aRect)}, 0);
	CGGradientRelease(gradient);
	
	CGPathRelease(path);
	path = CGPathCreateMutable();
	NSMCGPathAddRoundRectWithRadii(path, NSRectToCGRect(innerRect), radii);
	CGContextAddPath(ctx, path);
	CGContextEOClip(ctx);
	
	gradient = CGGradientCreateWithColors(colorSpace, 
		(CFArrayRef)[NSArray arrayWithObjects:(id)lightColor, (id)darkColor, nil], NULL);
	
	CGContextDrawLinearGradient(ctx, gradient, (CGPoint){NSMinX(aRect), NSMinY(aRect)}, 
		(CGPoint){NSMinX(aRect), NSMaxY(aRect)}, 0);
	CGContextRestoreGState(ctx);
	
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
	CGPathRelease(path);
}

- (void)_drawKeyframeIndicatorInRect:(NSRect)aRect color:(CGColorRef)color 
	shadowColor:(CGColorRef)shadowColor{
	CGFloat padding = 2.0f;
	CGFloat ellipseWidth = NSWidth(aRect) - padding * 2.0f;
	CGRect ellipseRect = (CGRect){NSMinX(aRect) + padding, 
		ceilf(NSMidY(aRect) - ellipseWidth / 2.0f) + 1.0f, 
		ellipseWidth, ellipseWidth};
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	
	CGContextSaveGState(ctx);
	CGContextAddEllipseInRect(ctx, ellipseRect);
	CGContextEOClip(ctx);
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, 
		(CFArrayRef)[NSArray arrayWithObjects:(id)shadowColor, (id)color, nil], NULL);
	CGContextDrawLinearGradient(ctx, gradient, (CGPoint){CGRectGetMinX(ellipseRect), 
		CGRectGetMinY(ellipseRect)}, (CGPoint){CGRectGetMinX(ellipseRect), 
		CGRectGetMinY(ellipseRect)}, 0);
	CGContextRestoreGState(ctx);

	CGContextSaveGState(ctx);
	CGContextSetFillColorWithColor(ctx, color);
	CGContextFillEllipseInRect(ctx, CGRectInset(ellipseRect, 0.5f, 0.5f));	
	CGContextRestoreGState(ctx);
	
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
}
@end
