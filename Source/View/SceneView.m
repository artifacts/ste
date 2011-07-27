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

#import "SceneView.h"

#import "AssetMO.h"
#import "KeyFrameMO.h"

#import <EngineRoom/CrossPlatform_NSValue_CGGeometry.h>

#define kSceneViewMinimumBorderFraction 0.1

@implementation SceneView

@synthesize scene;
@synthesize borderPercentage;

@synthesize visibleSize;
@synthesize pageBounds;
@synthesize visibleAreaLayer;
@synthesize assetsLayer;
@synthesize auxLayer;
@synthesize maskLayer;
@synthesize testLayer;

- (BOOL) isFlipped
{
	return YES;
}

- (void) awakeFromNib
{
	NSAssert( YES == [self wantsLayer], @"%@ must be layerBacked", self);
}

- (id) setup
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	[self setWantsLayer: YES];
	
	CALayer *rootLayer = self.layer;
	
	visibleSize = NSZeroSize;
	pageBounds = NSZeroRect;
	
	rootLayer.name = @"_root";
	rootLayer.masksToBounds = YES;
	rootLayer.backgroundColor = UTIL_AUTORELEASE_CF(CGColorCreateGenericGray(0.78f, 1.0f));
	rootLayer.geometryFlipped = [self isFlipped];

	visibleAreaLayer = [[CALayer layer] retain];
	visibleAreaLayer.name = @"_visibleArea";
	visibleAreaLayer.anchorPoint = CGPointZero;
	visibleAreaLayer.shadowRadius = 2.0f;
	visibleAreaLayer.shadowOpacity = 0.3f;
	visibleAreaLayer.shadowOffset = CGSizeZero;
	visibleAreaLayer.shadowColor = UTIL_AUTORELEASE_CF(CGColorCreateGenericGray(0.0f, 1.0f));
	visibleAreaLayer.backgroundColor = UTIL_AUTORELEASE_CF(CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 1.0f));

	auxLayer = [[CALayer layer] retain];
	auxLayer.name = @"_aux";
	auxLayer.anchorPoint = CGPointZero;
	//auxLayer.backgroundColor = UTIL_AUTORELEASE_CF( CGColorCreateGenericRGB(1, 0.5, 0, 0.7));

	assetsLayer = [[CALayer layer] retain];
	assetsLayer.name = @"_assets";
	assetsLayer.anchorPoint = CGPointZero;
	// assetsLayer.borderColor = UTIL_AUTORELEASE_CF( CGColorCreateGenericRGB(1, 0, 0, 1));
	// assetsLayer.backgroundColor = UTIL_AUTORELEASE_CF( CGColorCreateGenericRGB(1, 0.5, 0, 1.0));
	// assetsLayer.borderWidth = 1;

	assetsLayer.anchorPoint = CGPointZero;

	maskLayer = [[CALayer layer] retain];
	maskLayer.name = @"_mask";
	maskLayer.anchorPoint = CGPointZero;
	maskLayer.delegate = self;
	maskLayer.needsDisplayOnBoundsChange = YES;

	testLayer = [[CALayer layer] retain];
	testLayer.anchorPoint = CGPointZero;
	testLayer.name = @"_test";
	testLayer.borderColor = UTIL_AUTORELEASE_CF( CGColorCreateGenericRGB(1, 1, 0, 1));
	testLayer.borderWidth = 4;

	testLayer.position = CGPointMake(50,50);
	testLayer.bounds = CGRectMake(0,0,25,25);
	
	
	
	rootLayer.zPosition = kLayerZPositionRoot;
	visibleAreaLayer.zPosition = kLayerZPositionVisibleArea;
	auxLayer.zPosition = kLayerZPositionAux; 
	assetsLayer.zPosition = kLayerZPositionAssets;
	maskLayer.zPosition = kLayerZPositionMask;
	testLayer.zPosition = kLayerZPositionTest;

	[rootLayer addSublayer: visibleAreaLayer];
	[rootLayer addSublayer: auxLayer];
	[rootLayer addSublayer: assetsLayer];
	[rootLayer addSublayer: maskLayer];

	_defaultsKeys = [[NSArray alloc] initWithObjects:
		kSTECanvasShowsStageBorder, 
 		kSTECanvasShowsPageBorder, 
		kSTECanvasMasked, 
		kSTECanvasMaskOpacity, 
		nil];
	for (NSString *key in _defaultsKeys){
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
			forKeyPath:[NSString stringWithFormat:@"values.%@", key] options:0 context:NULL];
	}

	// [auxLayer addSublayer: testLayer];

	// NSLog(@"vislayer: %@ f: %@ b: %@", visibleAreaLayer.name, NSStringFromRect(NSRectFromCGRect(visibleAreaLayer.frame)), NSStringFromRect(NSRectFromCGRect(visibleAreaLayer.bounds)));
	
	[CATransaction commit];
	return self;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
		name:NSViewFrameDidChangeNotification object:[self superview]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewBoundsDidChange:) 
		name:NSViewFrameDidChangeNotification object:newSuperview];
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	return [self setup]; 
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	return [self setup];
}

- (void) dealloc
{
	// relying on extra work done by accessor
	self.scene = nil;
	
	[assetsLayer release];
	[visibleAreaLayer release];
	[auxLayer release];
	[testLayer release];
	
	for (NSString *key in _defaultsKeys){
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self 
			forKeyPath:[NSString stringWithFormat:@"values.%@", key]];
	}
	[_defaultsKeys release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (void) updateFrameAndBoundsForVisibleSize
{

	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	NSScrollView *enclosingScrollView = [self enclosingScrollView];

	NSSize availableSize = enclosingScrollView ? [enclosingScrollView contentSize] : [[self superview] bounds].size;

	// NSLog(@"enclosingScrollView: %@ superViewSize: %@", enclosingScrollView, NSStringFromSize(availableSize));

	NSSize visSize = self.visibleSize;

	CGFloat minBorder = floorf(MAX(visSize.width, visSize.height) * kSceneViewMinimumBorderFraction);
	CGFloat borderX = minBorder;
	CGFloat borderY = minBorder;

	// try to avoid unneccessary scrollbars and blank areas
	if( visSize.width + 2 * minBorder < availableSize.width) {
		borderX = floorf((availableSize.width - visSize.width) / 2.0);
	}	

	if( visSize.height + 2 * minBorder < availableSize.height) {
		borderY = floorf((availableSize.height - visSize.height) / 2.0);
	}
				
	NSSize frameSize = NSMakeSize(floorf(visSize.width + 2 * borderX), floorf(visSize.height + 2 * borderY));
	[self setFrameSize: frameSize];

	// the coordinate system for the view is such that 0,0 is the origin of the (end-result) visible stage area
	self.bounds = NSMakeRect(-borderX, -borderY, frameSize.width, frameSize.height);
	
	visibleAreaLayer.position = CGPointZero;
	visibleAreaLayer.bounds = CGRectMake(0, 0, visSize.width, visSize.height);
 
	assetsLayer.position = CGPointMake(-borderX, -borderY);
	assetsLayer.bounds = NSRectToCGRect(self.bounds);
	
	auxLayer.position = CGPointMake(-borderX, -borderY);
	auxLayer.bounds = NSRectToCGRect(self.bounds);
	
	maskLayer.position = CGPointMake(-borderX, -borderY);
	maskLayer.bounds = NSRectToCGRect(self.bounds);
	
	testLayer.position = CGPointMake(10,10);

	[CATransaction commit];

#if 0
NSLog(@"UPDATE V: f:%@ b:%@ r: f:%@ b:%@ v: f:%@ b:%@ a: f:%@ b:%@", 
NSStringFromRect(self.frame), NSStringFromRect(self.bounds), 
NSStringFromRect(NSRectFromCGRect(rootLayer.frame)), NSStringFromRect(NSRectFromCGRect(rootLayer.bounds)),
NSStringFromRect(NSRectFromCGRect(visibleAreaLayer.frame)), NSStringFromRect(NSRectFromCGRect(visibleAreaLayer.bounds)),
NSStringFromRect(NSRectFromCGRect(assetsLayer.frame)), NSStringFromRect(NSRectFromCGRect(assetsLayer.bounds))
);
#endif

}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
	if (layer != maskLayer){
		[super drawLayer:layer inContext:ctx];
		return;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	BOOL maskStage = [defaults boolForKey: kSTECanvasMasked];
	BOOL showStageBorder = [defaults boolForKey: kSTECanvasShowsStageBorder];
	BOOL showPageBorder = [defaults boolForKey: kSTECanvasShowsPageBorder];

	CGFloat opacity = [defaults floatForKey: kSTECanvasMaskOpacity];

	CGColorRef maskColor = CGColorCreateGenericGray(0.0f, opacity);
	CGColorRef stageBorderColor = CGColorCreateGenericRGB(0.0f, 1.0f, 1.0f, 1.0f);
	CGColorRef pageBorderColor = CGColorCreateGenericRGB(0.0f, 1.0f, 0.0f, 0.5f);
	
	CGRect innerRect = visibleAreaLayer.frame;
	
	CGContextSaveGState(ctx);
	if (maskStage){
		CGContextSetFillColorWithColor(ctx, maskColor);
		CGContextBeginPath(ctx);
		CGContextMoveToPoint(ctx, CGRectGetMinX(layer.bounds), CGRectGetMinY(layer.bounds));
		CGContextAddLineToPoint(ctx, CGRectGetMaxX(layer.bounds), CGRectGetMinY(layer.bounds));
		CGContextAddLineToPoint(ctx, CGRectGetMaxX(layer.bounds), CGRectGetMaxY(layer.bounds));
		CGContextAddLineToPoint(ctx, CGRectGetMinX(layer.bounds), CGRectGetMaxY(layer.bounds));
		CGContextAddLineToPoint(ctx, CGRectGetMinX(layer.bounds), CGRectGetMinY(layer.bounds));
		
		CGContextMoveToPoint(ctx, CGRectGetMinX(innerRect), CGRectGetMinY(innerRect));
		CGContextAddLineToPoint(ctx, CGRectGetMinX(innerRect), CGRectGetMaxY(innerRect));
		CGContextAddLineToPoint(ctx, CGRectGetMaxX(innerRect), CGRectGetMaxY(innerRect));
		CGContextAddLineToPoint(ctx, CGRectGetMaxX(innerRect), CGRectGetMinY(innerRect));
		CGContextAddLineToPoint(ctx, CGRectGetMinX(innerRect), CGRectGetMinY(innerRect));
		CGContextClosePath(ctx);
		CGContextFillPath(ctx);
	}
	
	if (showStageBorder){
		CGContextSetStrokeColorWithColor(ctx, stageBorderColor);
		CGContextStrokeRect(ctx, CGRectInset(innerRect, -0.5f, -0.5f));
	}
	
	if (showPageBorder){
		
		CGRect pageBorderRect = NSRectToCGRect(self.pageBounds);

		lpdebug(pageBorderRect);
		
		if( NO == CGRectIsEmpty(pageBorderRect) ) {
			
			CGContextSetStrokeColorWithColor(ctx, pageBorderColor);
			CGContextSetLineWidth(ctx, 3.0);
			
			static CGFloat pageBorderDashes[] = { 4, 4 };
			CGContextSetLineDash(ctx, 0.5, pageBorderDashes, sizeof( pageBorderDashes ) / sizeof( CGFloat ));
			CGContextSetLineCap(ctx, kCGLineCapButt);
	
			CGContextStrokeRect(ctx, CGRectInset(pageBorderRect, -0.5f, -0.5f));
		}
	}
		
	CGContextRestoreGState(ctx);
	
	CGColorRelease(maskColor);
	CGColorRelease(stageBorderColor);
	CGColorRelease(pageBorderColor);
}

- (NSNumber *) width {	return [NSNumber numberWithFloat: self.visibleSize.width]; }

- (NSNumber *) height { return [NSNumber numberWithFloat: self.visibleSize.height]; }

- (void) setWidth: (NSNumber *) width
{
	NSSize currentVisibleSize = self.visibleSize;
	currentVisibleSize.width = width ? floorf([width floatValue]) : 0.0;
	self.visibleSize = currentVisibleSize;
	[self updateFrameAndBoundsForVisibleSize];
}

- (void) setHeight: (NSNumber *) height
{
	NSSize currentVisibleSize = self.visibleSize;
	currentVisibleSize.height = height ? floorf([height floatValue]) : 0.0;
	self.visibleSize = currentVisibleSize;
	[self updateFrameAndBoundsForVisibleSize];
}

- (NSNumber *) pageWidth {	return [NSNumber numberWithFloat: NSWidth(self.pageBounds)]; }

- (NSNumber *) pageHeight { return [NSNumber numberWithFloat: NSHeight(self.pageBounds)]; }

- (void) setPageWidth: (NSNumber *) width
{
	NSRect currentPageBounds = self.pageBounds;
	currentPageBounds.size.width = width ? floorf([width floatValue]) : 0.0;
	self.pageBounds = currentPageBounds;
	[self.maskLayer setNeedsDisplay];
}

- (void) setPageHeight: (NSNumber *) height
{
	NSRect currentPageBounds = self.pageBounds;
	currentPageBounds.size.height = height ? floorf([height floatValue]) : 0.0;
	self.pageBounds = currentPageBounds;
	[self.maskLayer setNeedsDisplay];
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context{
	[maskLayer setNeedsDisplay];
}



#pragma mark -
#pragma mark Notifications

- (void)viewBoundsDidChange:(NSNotification *)notification{
	[self updateFrameAndBoundsForVisibleSize];
}
@end
