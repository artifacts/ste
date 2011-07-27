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

#import "CanvasSceneView.h"
#import <EngineRoom/CrossPlatform_Utilities.h>
#import "AssetEditor.h"
#import "ModelAccess.h"
#import "MediaContainer.h"
#import "CALayer+VisualEffects.h"


#define MODEL_KEYPATH(base, rest)  [[@"representedObject." stringByAppendingString: (base) ] stringByAppendingString: (rest)]
#define SELECTED_ITEM() [self valueForKeyPath: MODEL_KEYPATH(kModelAccessAssetSelectionKeyPath, @".self")] 
#define SELECTED_ITEMS [self valueForKeyPath:MODEL_KEYPATH(kModelAccessSelectedAssetsKeyPath, @"")]
#define SET_SELECTED_ITEMS(items) [self setValue: (items) forKeyPath: MODEL_KEYPATH(kModelAccessSelectedAssetsKeyPath, @"")]
#define SET_SELECTED_ITEM(item) ({ id __item = (item); SET_SELECTED_ITEMS( __item ? [NSArray arrayWithObject: __item] : [NSArray array] ); })

#define kItemsKeyPath kModelAccessAssetsKeyPath
#define kSelectedItemsKeyPath kModelAccessSelectedAssetsKeyPath
#define kAssetInStagePadding 10.0f
#define kMoveDistanceTresholdXWhileHoldingShift 10
#define kMoveDistanceTresholdYWhileHoldingShift 10

@interface CanvasSceneView (Private)
- (CanvasSceneLayer *)_layerWithItem:(id)item;
- (NSArray *)_layersWithItems:(NSArray *)items;
- (void)_selectLayer:(CanvasSceneLayer *)layer;
- (void)_createLayersWithItems:(NSSet *)items;
- (void)_removeLayersWithItems:(NSSet *)items;
- (void)_performRotateAction:(NSEvent *)theEvent;
- (void)_performRotateMultipleAction:(NSEvent *)theEvent;
- (void)_performResizeAction:(NSEvent *)theEvent;
- (void)_performResizeMultipleAction:(NSEvent *)theEvent;
- (void)_performMoveAction:(NSEvent *)theEvent;
- (void)_performMoveMultipleAction:(NSEvent *)theEvent;
- (void)_selectItemsInRect:(CGRect)rect;
- (void) _itemsChanged: (NSArray *) items;
- (void) _itemSelectionChanged: (NSArray *) selectedItems;
@end


@implementation CanvasSceneView

@synthesize currentTime=m_currentTime;
@synthesize representedObject = _modelAccess;
@synthesize delegate = m_delegate;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id) setup
{
	if( ( self = [super setup] ) ) {
		m_selectedLayer = nil;
		m_multipleSelectionProxy = nil;
		m_spaceButtonDown = NO;
		m_transformLayer = [[CanvasSceneTransformControlLayer alloc] init];
		m_transformLayer.name = @"_transform";
		[self registerForDraggedTypes:[NSArray arrayWithObjects:kSTEAssetDragType, kSTECMSContentDragType, 
									   NSFilenamesPboardType, nil]];
		m_trackingArea = nil;
		[self updateTrackingAreas];
		[self setModelAccessObservingState:YES];
	}
	return self;
}

- (void) dealloc
{
	NSLog(@"dealloc CanvasSceneView for %@ %p", [self class], self);
	[self setModelAccessObservingState: NO];
	[m_trackingArea release];
	[m_multipleSelectionProxy release];
	[super dealloc];
}


#pragma mark -
#pragma mark Public methods


#pragma mark -
#pragma mark Events

- (void)mouseEntered:(NSEvent *)theEvent{
	[[self window] makeFirstResponder:self];
	m_mouseInside = YES;
}

- (void)mouseMoved:(NSEvent *)theEvent{
	if (!m_mouseInside || ![m_transformLayer superlayer])
		return;
	CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
											   fromView:nil]);
	point = [[m_transformLayer superlayer] convertPoint:point fromLayer:[self layer]];
	
	if ([m_transformLayer hitTest:point] != nil){
		[[m_transformLayer cursorAtPoint:point] set];
	}else{
		[[NSCursor arrowCursor] set];
	}
}

- (void)mouseExited:(NSEvent *)theEvent{
	[[NSCursor arrowCursor] set];
	m_mouseInside = NO;
}

- (void)updateTrackingAreas{
	[m_trackingArea release];
	NSTrackingAreaOptions trackingOptions = NSTrackingCursorUpdate | 
		NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited |
		NSTrackingActiveInActiveApp | NSTrackingMouseMoved;
	// Yes, that's sort of cheating but the negative bounds got me so confused that I couldn't 
	// help but attach the TrackingArea to the ScrollView. In any way that shouldn't be a problem, 
	// plus the TrackingArea is finally where it is supposed to be and doesn't intersect with 
	// other views
	NSScrollView *scrollView = [self enclosingScrollView];
	m_trackingArea = [[NSTrackingArea alloc] initWithRect:[[scrollView contentView] bounds] 
		options:trackingOptions owner:self userInfo:nil];
	[scrollView addTrackingArea:m_trackingArea];
}

- (CanvasSceneLayer *)assetLayerAtPoint:(CGPoint)aPoint {
	CGPoint assetPoint = [self.assetsLayer.superlayer convertPoint:aPoint fromLayer:self.layer];

	CALayer *clickedLayer = [self.assetsLayer hitTest:assetPoint];
	if ([clickedLayer isKindOfClass:[CanvasSceneLayer class]]){
		return (CanvasSceneLayer *)clickedLayer;
	}
	return nil;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSArray *selectedItems = [[NSArray alloc] initWithArray:SELECTED_ITEMS];
	// get clicked asset
	CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]);	
	
	CanvasSceneLayer *clickedAssetLayer = [self assetLayerAtPoint:point];
	AssetMO *clickedAsset = [clickedAssetLayer representedObject];
	
	// create context menu
	NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Asset"] autorelease];
	[theMenu setAutoenablesItems:NO];
	NSMenuItem* menuItem;
	BOOL enabled;
	
	// group item
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Gruppieren" action:@selector(groupAction:) keyEquivalent:@""];
	[theMenu insertItem:menuItem atIndex:0];
	enabled = ([selectedItems count] >= 2 && [_modelAccess itemsMayBeGrouped:selectedItems]);
	
	[menuItem setEnabled:enabled];
	[menuItem release];	
	
	// ungroup item
	menuItem = [[NSMenuItem alloc] initWithTitle:@"Gruppierung aufheben" action:@selector(ungroupAction:) keyEquivalent:@""];
	[theMenu insertItem:menuItem atIndex:1];
	enabled = ([selectedItems count] >= 2) && [clickedAsset hasSameParentAsAssetInArray:selectedItems];
	[menuItem setEnabled:enabled];	
	[menuItem release];
	
	//	[theMenu insertItem:[NSMenuItem separatorItem] atIndex:6];
	
	[selectedItems release];
	return theMenu;
}

- (void)mouseDown:(NSEvent *)theEvent{
	CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
											   fromView:nil]);
	
	BOOL transformLayerClicked = NO;	
	
	// TransformLayer is currently attached
	CGPoint auxPoint = [m_transformLayer.superlayer convertPoint:point fromLayer:self.layer];
	if ([m_transformLayer superlayer] && [m_transformLayer hitTest:auxPoint]){
		transformLayerClicked = YES;
	}

	// Next up: See if an asset was clicked
	CanvasSceneLayer *clickedAssetLayer = [self assetLayerAtPoint:point];
	
	if (transformLayerClicked){
		CanvasTransformAction action;
		[m_transformLayer action:&action edge:NULL atPoint:auxPoint];
		BOOL clickedAssetLayerIsEditing = clickedAssetLayer == m_transformLayer.target || 
		[m_multipleSelectionProxy.layers containsObject:clickedAssetLayer];
		
		if (action == kCanvasTransformActionResize || action == kCanvasTransformActionRotate || 
			!clickedAssetLayer || clickedAssetLayerIsEditing){
			[self performSelector:@selector(_beginTransformAction:) withObject:theEvent 
					   afterDelay:0.0];
			return;
		}
	}
	
	NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	if ([currentDefaults boolForKey:kSTEAssetSelectionOnStageLocked] == YES) {
		if (!([NSEvent modifierFlags] & NSCommandKeyMask)) {
            NSMutableArray *selectedItems = [[[NSMutableArray alloc] initWithArray:SELECTED_ITEMS] autorelease];
            clickedAssetLayer = [self _layerWithItem: [selectedItems lastObject]]; // lastObject is nil when array is empty
        }
	}	

	if (clickedAssetLayer){
		if ([NSEvent modifierFlags] & NSShiftKeyMask){
			NSMutableArray *selectedItems = [[NSMutableArray alloc] initWithArray:SELECTED_ITEMS];
			[selectedItems addObject:[clickedAssetLayer representedObject]];
			SET_SELECTED_ITEMS(selectedItems);
			[selectedItems release];		
		} else {			
			SET_SELECTED_ITEM([clickedAssetLayer representedObject]);
			[self performSelector:@selector(_beginTransformAction:) withObject:theEvent 
					   afterDelay:0.0];
		}
		return;
	}
	
	// Still no match. So we deselect all and let the user draw a selection rect
	SET_SELECTED_ITEM(nil);
	[self performSelector:@selector(_beginSelection:) withObject:theEvent afterDelay:0.0];
}

- (void)keyDown:(NSEvent *)theEvent{
	NSString *characters = [theEvent characters];
	if( 0 == [characters length] ) {
		NSBeep();
		return;
	}
	
	NSMutableArray *selectedItems = [[[NSMutableArray alloc] initWithArray:SELECTED_ITEMS] autorelease];
	
	unichar key = [[theEvent characters] characterAtIndex:0];
	
	if (key == 0x20){ // space
		m_spaceButtonDown = YES;
		return;
	}
	if ([selectedItems count] == 0) {
		NSBeep();
		return;
	}
	
	CGSize offset = CGSizeZero;
	if (key == NSUpArrowFunctionKey)
		offset.height = 1.0f;
	else if (key == NSDownArrowFunctionKey)
		offset.height = -1.0f;
	else if (key == NSLeftArrowFunctionKey)
		offset.width = -1.0f;
	else if (key == NSRightArrowFunctionKey)
		offset.width = 1.0f;
	else if (key == 0x7F){ // backspace
		for (id asset in selectedItems) {
			//CanvasItem *target = [layer representedObject];
			[self.delegate removeCanvasItem:asset];
		}
		return;
	}else{
		NSBeep();
		return;
	}
	
	if ([NSEvent modifierFlags] & NSShiftKeyMask){
		offset.width *= 10.0f;
		offset.height *= 10.0f;
	}

	for (AssetMO *asset in selectedItems) {
		KeyframeAnimationMO *keyframeAnimation = asset.keyframeAnimation;
		KeyframeMO *keyframe = [keyframeAnimation ensureKeyframeForTime:self.currentTime];
				
		CGPoint position = [[keyframe valueForKey:@"position"] CGPointValue];
		
		//CGPoint position = [asset.position CGPointValue];
		position.x += offset.width;
		position.y -= offset.height;

		[keyframe setValue:[NSValue valueWithCGPoint:position] forKey:@"position"];
	}
	
	// update selected assets rect
	if ([selectedItems count] > 1) {
		[self _selectLayers:[self _layersWithItems:selectedItems]];
	}
	
}

- (void)keyUp:(NSEvent *)theEvent{
	NSString *characters = [theEvent characters];
	
	if( 0 == [characters length] ) {
		NSBeep();
		return;
	}
	
	unichar key = [[theEvent characters] characterAtIndex:0];
	if (key == 0x20){ // space
		m_spaceButtonDown = NO;
	}
}

#pragma mark -
#pragma mark grouping

- (IBAction)groupAction:(id)sender {
	NSArray *selectedItems = [[NSArray alloc] initWithArray:SELECTED_ITEMS];
	[_modelAccess createAssetContainingChildren:selectedItems withName:@"Neue Gruppe"];
	[selectedItems release];
}

- (IBAction)ungroupAction:(id)sender {
}

#pragma mark -
#pragma mark NSView hook methods

- (BOOL)canBecomeKeyView{
	return YES;
}

- (BOOL)acceptsFirstResponder{
	return YES;
}

#pragma mark -
#pragma mark Private methods

- (void)_selectLayer:(CanvasSceneLayer *)layer{
	[m_multipleSelectionProxy release];
	m_multipleSelectionProxy = nil;
	
	if (m_selectedLayer){
		[m_selectedLayer setSelected:NO];
	}
	
	if ([m_transformLayer superlayer]){
		[m_transformLayer removeFromSuperlayer];
		m_transformLayer.target = nil;
	}
	
	m_selectedLayer = layer;
	
	if (m_selectedLayer == nil)
		return;
	if (CGRectIsEmpty([m_selectedLayer frame])) 
		return; // don't draw a selection for layers with zero dimensions (e.g. groups)

	[m_selectedLayer setSelected:YES];
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	[self.auxLayer addSublayer:m_transformLayer];
	m_transformLayer.target = m_selectedLayer;
	m_transformLayer.zPosition = 1001;
	[CATransaction commit];
}

- (void)_selectLayers:(NSArray *)layers{
	[m_multipleSelectionProxy release];
	m_multipleSelectionProxy = nil;
	
	m_transformLayer.zPosition = 1001;
	m_multipleSelectionProxy = [[CanvasSceneLayerMultipleSelectionProxy alloc] 
								initWithLayers:layers];
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	[self.auxLayer addSublayer:m_transformLayer];
	m_transformLayer.target = (CanvasSceneLayer *)m_multipleSelectionProxy;
	m_transformLayer.zPosition = 1001;
	[CATransaction commit];
}

- (void)_createLayersWithItems:(NSSet *)items{
	for (CanvasItem *item in items){
		//NSLog(@"%@: adding layer for %@", [self class], [item valueForKey: @"name"]);
		
		CanvasSceneLayer *layer = [CanvasSceneLayer layerWithItem:item currentTimeProvider: self];
		[self.assetsLayer addSublayer:layer];
	}
}

- (void)_removeLayersWithItems:(NSSet *)items{
	NSArray *currentLayers = [NSArray arrayWithArray: self.assetsLayer.sublayers];
	for (CanvasSceneLayer *layer in currentLayers){
		if ([items containsObject:layer.representedObject]){
			//NSLog(@"%@: removing layer for %@", [self class], [layer.representedObject valueForKey: @"name"]);
			
			if (m_transformLayer.target == layer) {
				[self _selectLayer:nil];
			}
			[layer removeFromSuperlayer];
		}
	}
}

- (CanvasSceneLayer *)_layerWithItem:(id)item{
	for(CanvasSceneLayer *layer in self.assetsLayer.sublayers) {
		if( layer.representedObject == item ) {
			return layer;
		}
	}
	
	return nil;
}

- (NSArray *)_layersWithItems:(NSArray *)items{
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[items count]];
	CanvasSceneLayer *layer = nil;
	for (id item in items){
		layer = [self _layerWithItem:item];
		if (layer != nil) [arr addObject:layer];
	}
	return arr;
}

- (void)_selectItemsInRect:(CGRect)rect{
	NSArray *allItems = [_modelAccess 
						 valueForKeyPath:@"assetArrayController.arrangedObjects"];
	NSMutableArray *itemsInRect = [NSMutableArray array];
	for (AssetMO *item in allItems){
		NSDictionary *currentProperties = [item.keyframeAnimation propertiesForTime:
										   [self valueForKey:@"currentTime"]];
		CGFloat rotation = [[currentProperties valueForKey:@"rotation"] floatValue];
		CGRect itemRect = (CGRect){[[currentProperties valueForKey:@"position"] CGPointValue], 
			[[currentProperties valueForKey:@"bounds"] CGRectValue].size};
		itemRect = NSMRectByRotatingRectAroundPoint(itemRect, 
													(CGPoint){CGRectGetMidX(itemRect), CGRectGetMidY(itemRect)}, rotation);
		if (CGRectIntersectsRect(itemRect, rect)){
			[itemsInRect addObject:item];
		}
	}
	if ([itemsInRect count] == 0){
		[self _selectLayer:nil];
		return;
	}
	[self _selectLayers:[self _layersWithItems:itemsInRect]];
	NSMutableArray *selectedItems = [[NSMutableArray alloc] initWithArray:SELECTED_ITEMS];
	for (AssetMO *asset in itemsInRect) {
		[selectedItems addObject:asset];
	}
	SET_SELECTED_ITEMS(selectedItems);
	[selectedItems release];		
	
}

- (void)_beginSelection:(NSEvent *)theEvent{
	if ([[[NSApplication sharedApplication] currentEvent] type] == NSLeftMouseUp)
		return;
	
	CGPoint startPoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
													fromView:nil]);
	CGSize dragDist = CGSizeZero;
	
	CGColorRef borderColor = CGColorCreateGenericRGB(0.31f, 0.5f, 1.0f, 1.0f);
	CALayer *selectionLayer = [CALayer layer];
	selectionLayer.zPosition = 1000;
	selectionLayer.borderColor = borderColor;
	selectionLayer.borderWidth = 1.0f;
	CGColorRelease(borderColor);
	
	CGColorRef fillColor = CGColorCreateGenericRGB(0.31f, 0.5f, 1.0f, 0.2f);
	selectionLayer.backgroundColor = fillColor;
	CGColorRelease(fillColor);
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	[self.auxLayer addSublayer:selectionLayer];
	[CATransaction commit];
	
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
											 inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
												   fromView:nil]);
		dragDist = (CGSize){point.x - startPoint.x, point.y - startPoint.y};
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		selectionLayer.frame = (CGRect){startPoint, dragDist};
		[CATransaction commit];
		[pool release];
	}
	[selectionLayer removeFromSuperlayer];
	
	[self _selectItemsInRect:(CGRect){startPoint, dragDist}];
}

- (void)_beginTransformAction:(NSEvent *)theEvent{
	if ([[[NSApplication sharedApplication] currentEvent] type] == NSLeftMouseUp)
		return;
	
	CGPoint startPoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
													fromView:nil]);
	CanvasTransformAction action;
	[m_transformLayer action:&action edge:NULL atPoint:startPoint];
	
	if (action == kCanvasTransformActionRotate){
		if (m_multipleSelectionProxy != nil){
			[self _performRotateMultipleAction:theEvent];
		}else{
			[self _performRotateAction:theEvent];
		}
	}else if (action == kCanvasTransformActionResize){
		if (m_multipleSelectionProxy != nil){
			[self _performResizeMultipleAction:theEvent];
		}else{
			[self _performResizeAction:theEvent];
		}
	}else if (action == kCanvasTransformActionMove){
		if (m_multipleSelectionProxy != nil){
			[self _performMoveMultipleAction:theEvent];
		}else{
			[self _performMoveAction:theEvent];
		}
	}
}

- (void)_performRotateAction:(NSEvent *)theEvent{
	AssetEditor *assetEditor = [[NSApp delegate] valueForKeyPath:
								@"assetEditorController.selection.self"];
	
	CGPoint startPoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
													fromView:nil]);
	CGRect targetFrame = (CGRect){[[assetEditor valueForKey:@"position"] CGPointValue], 
		[[assetEditor valueForKey:@"bounds"] CGRectValue].size};
	CGPoint centerPoint = (CGPoint){CGRectGetMidX(targetFrame), CGRectGetMidY(targetFrame)};
	CGFloat startRotation = [[assetEditor valueForKey:@"rotation"] floatValue];
	CGPoint vec = (CGPoint){startPoint.x - centerPoint.x, startPoint.y - centerPoint.y};
	CGFloat startAngle = atan2f(vec.y, vec.x);
	
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;		
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
											 inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
												   fromView:nil]);
		vec = (CGPoint){point.x - centerPoint.x, point.y - centerPoint.y};
		CGFloat angle = atan2f(vec.y, vec.x);
		angle = (angle - startAngle + startRotation);
		
		if ([theEvent modifierFlags] & NSShiftKeyMask){
			CGFloat allowedDiff = M_PI / 9.0f; // 20 degrees
			CGFloat step = M_PI / 4.0f; // 45 degree steps
			int numSteps = (int)(M_PI / step);
			CGFloat testedAngle = 0.0f;
			for (int i = 0; i <= numSteps; i++){
				CGFloat diff = ABS(ABS(testedAngle) - ABS(angle));
				if (diff <= allowedDiff){
					angle = testedAngle * (angle < 0 ? -1.0f : 1.0f);
					break;
				}
				testedAngle += step;
			}
		}
		
		[assetEditor setValue:[NSNumber numberWithFloat:angle] 
					   forKey:@"rotation"];
		
		[pool release];
	}
}

- (void)_performRotateMultipleAction:(NSEvent *)theEvent{
	CGPoint startPoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
													fromView:nil]);
	CGRect targetFrame = m_multipleSelectionProxy.frame;
	CGPoint centerPoint = (CGPoint){CGRectGetMidX(targetFrame), CGRectGetMidY(targetFrame)};
	CGFloat startRotation = 0.0f;
	CGPoint vec = (CGPoint){startPoint.x - centerPoint.x, startPoint.y - centerPoint.y};
	CGFloat startAngle = atan2f(vec.y, vec.x);
	
	NSMutableArray *startRects = [NSMutableArray arrayWithCapacity:
								  [m_multipleSelectionProxy.layers count]];
	NSMutableArray *startRotations = [NSMutableArray arrayWithCapacity:
									  [m_multipleSelectionProxy.layers count]];
	for (CanvasSceneLayer *layer in m_multipleSelectionProxy.layers){
		AssetMO *asset = [layer representedObject];
		KeyframeAnimationMO *keyframeAnimation = asset.keyframeAnimation;
		KeyframeMO *keyframe = [keyframeAnimation ensureKeyframeForTime:self.currentTime];
		CGPoint position = [[keyframe valueForKey:@"position"] CGPointValue];
		CGRect bounds = [[keyframe valueForKey:@"bounds"] CGRectValue];
		CGFloat rotation = [[keyframe valueForKey:@"rotation"] floatValue];
		[startRects addObject:[NSValue valueWithCGRect:(CGRect){position, bounds.size}]];
		[startRotations addObject:[NSNumber numberWithFloat:rotation]];
	}
	
	
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;		
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
											 inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
												   fromView:nil]);
		vec = (CGPoint){point.x - centerPoint.x, point.y - centerPoint.y};
		CGFloat angle = atan2f(vec.y, vec.x);
		angle = (angle - startAngle + startRotation);
		
		if ([theEvent modifierFlags] & NSShiftKeyMask){
			CGFloat allowedDiff = M_PI / 9.0f; // 20 degrees
			CGFloat step = M_PI / 4.0f; // 45 degree steps
			int numSteps = (int)(M_PI / step);
			CGFloat testedAngle = 0.0f;
			for (int i = 0; i <= numSteps; i++){
				CGFloat diff = ABS(ABS(testedAngle) - ABS(angle));
				if (diff <= allowedDiff){
					angle = testedAngle * (angle < 0 ? -1.0f : 1.0f);
					break;
				}
				testedAngle += step;
			}
		}
		
		for (NSInteger i = 0; i < [m_multipleSelectionProxy.layers count]; i++){
			CanvasSceneLayer *layer = [m_multipleSelectionProxy.layers objectAtIndex:i];
			AssetMO *asset = [layer representedObject];
			KeyframeAnimationMO *keyframeAnimation = asset.keyframeAnimation;
			KeyframeMO *keyframe = [keyframeAnimation ensureKeyframeForTime:self.currentTime];
			
			CGRect startRect = [[startRects objectAtIndex:i] CGRectValue];
			CGPoint position = startRect.origin;
			CGFloat itemStartRotation = [[startRotations objectAtIndex:i] floatValue];
			position.x += CGRectGetWidth(startRect) / 2.0f;
			position.y += CGRectGetHeight(startRect) / 2.0f;
			position = NSMPointRotatedAroundPoint(position, centerPoint, angle);
			position.x -= CGRectGetWidth(startRect) / 2.0f;
			position.y -= CGRectGetHeight(startRect) / 2.0f;
			
			[keyframe setValue:[NSNumber numberWithFloat:angle + itemStartRotation] 
						forKey:@"rotation"];
			[keyframe setValue:[NSValue valueWithCGPoint:position] forKey:@"position"];
		}
		
		m_multipleSelectionProxy.rotation = angle;
		[pool release];
	}
	
	// immediately snap back, like illustrator does
	[m_multipleSelectionProxy updateFrame];
}

- (void)_performResizeAction:(NSEvent *)theEvent{
	AssetEditor *assetEditor = [[NSApp delegate] valueForKeyPath:
								@"assetEditorController.selection.self"];
	
	CGPoint startPoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
													fromView:nil]);
	CGRect targetFrame = (CGRect){[[assetEditor valueForKey:@"position"] CGPointValue], 
		[[assetEditor valueForKey:@"bounds"] CGRectValue].size};
	CGFloat rotation = [[assetEditor valueForKey:@"rotation"] floatValue];
	
	CanvasHandleEdge edge;
	[m_transformLayer action:NULL edge:&edge atPoint:startPoint];
	startPoint = NSMPointRotatedAroundPoint(startPoint, (CGPoint){CGRectGetMidX(targetFrame), 
		CGRectGetMidY(targetFrame)}, -rotation);
	
	CGPoint anchors[8] = {
		1.0f, 1.0f, // TL
		0.5f, 1.0f, // T
		0.0f, 1.0f, // TR
		0.0f, 0.5f, // R
		0.0f, 0.0f, // BR
		0.5f, 0.0f, // B
		1.0f, 0.0f, // BL
		1.0f, 0.5f  // L
	};
	
	CGRect newFrame;
	CGPoint anchorPoint;
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;		
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
											 inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		CGPoint anchor = anchors[edge];
		BOOL resizeY = YES;
		BOOL resizeX = YES;
		switch (edge){
			case kCanvasHandleEdgeTop:
			case kCanvasHandleEdgeBottom:
				resizeX = NO;
				break;
			case kCanvasHandleEdgeLeft:
			case kCanvasHandleEdgeRight:
				resizeY = NO;
				break;
		}
		
		if ([theEvent modifierFlags] & NSAlternateKeyMask)
			anchor = (CGPoint){0.5f, 0.5f};
		
		anchorPoint = (CGPoint){CGRectGetMinX(targetFrame) + 
			CGRectGetWidth(targetFrame) * anchor.x, CGRectGetMinY(targetFrame) + 
			CGRectGetHeight(targetFrame) * anchor.y};
		CGSize startDistance = (CGSize){startPoint.x - anchorPoint.x, startPoint.y - anchorPoint.y};
		
		CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
												   fromView:nil]);
		point = NSMPointRotatedAroundPoint(point, (CGPoint){CGRectGetMidX(targetFrame), 
			CGRectGetMidY(targetFrame)}, -rotation);
		
		if ([theEvent modifierFlags] & NSShiftKeyMask && (resizeX && resizeY)){
			CGSize diff = (CGSize){point.x - startPoint.x, point.y - startPoint.y};
			CGPoint ratio = (CGPoint){diff.width / startDistance.width, 
				diff.height / startDistance.height};
			if (ratio.x > ratio.y){
				point.x = startPoint.x + startDistance.width * ratio.y;
			}else{
				point.y = startPoint.y + startDistance.height * ratio.x;
			}
		}
		
		CGSize distance = (CGSize){point.x - anchorPoint.x - startDistance.width, 
			point.y - anchorPoint.y - startDistance.height};
		
		if (startPoint.x < anchorPoint.x)
			distance.width *= -1.0f;
		if (startPoint.y < anchorPoint.y)
			distance.height *= -1.0f;
		
		CGPoint scaleRatio = (CGPoint){1.0f + distance.width / CGRectGetWidth(targetFrame), 
			1.0f + distance.height / CGRectGetHeight(targetFrame)};
		if (!resizeX) scaleRatio.x = 1.0f;
		if (!resizeY) scaleRatio.y = 1.0f;
		
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformTranslate(transform, anchorPoint.x, anchorPoint.y);
		transform = CGAffineTransformScale(transform, scaleRatio.x, scaleRatio.y);
		transform = CGAffineTransformTranslate(transform, -anchorPoint.x, -anchorPoint.y);
		newFrame = CGRectApplyAffineTransform(targetFrame, transform);
		
		CGPoint oldCenter = (CGPoint){CGRectGetMidX(targetFrame), CGRectGetMidY(targetFrame)};
		CGPoint newCenter = (CGPoint){CGRectGetMidX(newFrame), CGRectGetMidY(newFrame)};
		CGPoint diff = (CGPoint){newCenter.x - oldCenter.x, newCenter.y - oldCenter.y};
		newFrame.origin.x -= diff.x;
		newFrame.origin.y -= diff.y;
		diff = NSMRotatedVector(diff, rotation);
		newFrame.origin.x += diff.x;
		newFrame.origin.y += diff.y;
		
		[assetEditor setValue:[NSValue valueWithCGPoint:newFrame.origin] forKey:@"position"];
		[assetEditor setValue:[NSValue valueWithCGRect:(CGRect){CGPointZero, newFrame.size}] 
					   forKey:@"bounds"];
		
		[pool release];
	}
}

- (void)_performResizeMultipleAction:(NSEvent *)theEvent{
	CGPoint startPoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
													fromView:nil]);
	NSMutableArray *startRects = [NSMutableArray arrayWithCapacity:
								  [m_multipleSelectionProxy.layers count]];
	NSMutableArray *startRotations = [NSMutableArray arrayWithCapacity:
									  [m_multipleSelectionProxy.layers count]];
	for (CanvasSceneLayer *layer in m_multipleSelectionProxy.layers){
		AssetMO *asset = [layer representedObject];
		KeyframeAnimationMO *keyframeAnimation = asset.keyframeAnimation;
		KeyframeMO *keyframe = [keyframeAnimation ensureKeyframeForTime:self.currentTime];
		CGPoint position = [[keyframe valueForKey:@"position"] CGPointValue];
		CGRect bounds = [[keyframe valueForKey:@"bounds"] CGRectValue];
		CGFloat rotation = [[keyframe valueForKey:@"rotation"] floatValue];
		[startRects addObject:[NSValue valueWithCGRect:(CGRect){position, bounds.size}]];
		[startRotations addObject:[NSNumber numberWithFloat:rotation]];
	}
	
	CGRect targetFrame = m_multipleSelectionProxy.frame;
	
	CanvasHandleEdge edge;
	[m_transformLayer action:NULL edge:&edge atPoint:startPoint];
	
	CGPoint anchors[8] = {
		1.0f, 1.0f, // TL
		0.5f, 1.0f, // T
		0.0f, 1.0f, // TR
		0.0f, 0.5f, // R
		0.0f, 0.0f, // BR
		0.5f, 0.0f, // B
		1.0f, 0.0f, // BL
		1.0f, 0.5f  // L
	};
	
	CGRect newFrame;
	CGPoint anchorPoint;
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;		
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
											 inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		CGPoint anchor = anchors[edge];
		BOOL resizeY = YES;
		BOOL resizeX = YES;
		switch (edge){
			case kCanvasHandleEdgeTop:
			case kCanvasHandleEdgeBottom:
				resizeX = NO;
				break;
			case kCanvasHandleEdgeLeft:
			case kCanvasHandleEdgeRight:
				resizeY = NO;
				break;
		}
		
		if ([theEvent modifierFlags] & NSAlternateKeyMask)
			anchor = (CGPoint){0.5f, 0.5f};
		
		anchorPoint = (CGPoint){CGRectGetMinX(targetFrame) + 
			CGRectGetWidth(targetFrame) * anchor.x, CGRectGetMinY(targetFrame) + 
			CGRectGetHeight(targetFrame) * anchor.y};
		CGSize startDistance = (CGSize){startPoint.x - anchorPoint.x, startPoint.y - anchorPoint.y};
		
		CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
												   fromView:nil]);
		
		if ([theEvent modifierFlags] & NSShiftKeyMask && (resizeX && resizeY)){
			CGSize diff = (CGSize){point.x - startPoint.x, point.y - startPoint.y};
			CGPoint ratio = (CGPoint){diff.width / startDistance.width, 
				diff.height / startDistance.height};
			if (ratio.x > ratio.y){
				point.x = startPoint.x + startDistance.width * ratio.y;
			}else{
				point.y = startPoint.y + startDistance.height * ratio.x;
			}
		}
		
		CGSize distance = (CGSize){point.x - anchorPoint.x - startDistance.width, 
			point.y - anchorPoint.y - startDistance.height};
		
		if (startPoint.x < anchorPoint.x)
			distance.width *= -1.0f;
		if (startPoint.y < anchorPoint.y)
			distance.height *= -1.0f;
		
		CGPoint scaleRatio = (CGPoint){1.0f + distance.width / CGRectGetWidth(targetFrame), 
			1.0f + distance.height / CGRectGetHeight(targetFrame)};
		if (!resizeX) scaleRatio.x = 1.0f;
		if (!resizeY) scaleRatio.y = 1.0f;
		
		for (NSInteger i = 0; i < [m_multipleSelectionProxy.layers count]; i++){
			CanvasSceneLayer *layer = [m_multipleSelectionProxy.layers objectAtIndex:i];
			AssetMO *asset = [layer representedObject];
			KeyframeAnimationMO *keyframeAnimation = asset.keyframeAnimation;
			KeyframeMO *keyframe = [keyframeAnimation ensureKeyframeForTime:self.currentTime];
			
			CGRect startRect = [[startRects objectAtIndex:i] CGRectValue];
			
			CGAffineTransform transform = CGAffineTransformIdentity;
			transform = CGAffineTransformTranslate(transform, anchorPoint.x, anchorPoint.y);
			transform = CGAffineTransformScale(transform, scaleRatio.x, scaleRatio.y);
			transform = CGAffineTransformTranslate(transform, -anchorPoint.x, -anchorPoint.y);
			newFrame = CGRectApplyAffineTransform(startRect, transform);
			
			[keyframe setValue:[NSValue valueWithCGRect:(CGRect){CGPointZero, newFrame.size}] 
						forKey:@"bounds"];
			[keyframe setValue:[NSValue valueWithCGPoint:newFrame.origin] forKey:@"position"];
		}
		[m_multipleSelectionProxy updateFrame];
		
		[pool release];
	}
}

- (void)_performMoveAction:(NSEvent *)theEvent{
	AssetEditor *assetEditor = [[NSApp delegate] valueForKeyPath:
								@"assetEditorController.selection.self"];
	
	CGPoint startPoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
													fromView:nil]);
	CGRect targetFrame = (CGRect){[[assetEditor valueForKey:@"position"] CGPointValue], 
		[[assetEditor valueForKey:@"bounds"] CGRectValue].size};
	CGFloat rotation = [[assetEditor valueForKey:@"rotation"] floatValue];
	
	CGRect rotatedFrame = NSMRectByRotatingRectAroundPoint(targetFrame, 
														   (CGPoint){CGRectGetMidX(targetFrame), CGRectGetMidY(targetFrame)}, rotation);
	
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;		
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
											 inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
												   fromView:nil]);
		CGSize distance = (CGSize){point.x - startPoint.x, point.y - startPoint.y};
		
		CGRect newRotatedFrame = rotatedFrame;
		newRotatedFrame.origin.x += distance.width;
		newRotatedFrame.origin.y += distance.height;
		
		// prevent the object from being moved outside the visible bounds
		newRotatedFrame.origin.x = MAX(CGRectGetMinX(newRotatedFrame), 
									   CGRectGetMinX(auxLayer.frame) - CGRectGetWidth(newRotatedFrame) + kAssetInStagePadding);
		newRotatedFrame.origin.y = MAX(CGRectGetMinY(newRotatedFrame), 
									   CGRectGetMinY(auxLayer.frame) - CGRectGetHeight(newRotatedFrame) + kAssetInStagePadding);
		newRotatedFrame.origin.x = MIN(CGRectGetMinX(newRotatedFrame), 
									   CGRectGetMaxX(auxLayer.frame) - kAssetInStagePadding);
		newRotatedFrame.origin.y = MIN(CGRectGetMinY(newRotatedFrame), 
									   CGRectGetMaxY(auxLayer.frame) - kAssetInStagePadding);
		
		distance = (CGSize){CGRectGetMinX(newRotatedFrame) - CGRectGetMinX(rotatedFrame), 
			CGRectGetMinY(newRotatedFrame) - CGRectGetMinY(rotatedFrame)};
		CGPoint newPosition = [[assetEditor valueForKey:@"position"] CGPointValue];
				
		// lock X axis
		if ([NSEvent modifierFlags] & NSAlternateKeyMask) {
			newPosition.y = CGRectGetMinY(targetFrame) + distance.height;
		// lock Y axis
		} else if ([NSEvent modifierFlags] & NSShiftKeyMask) {
			newPosition.x = CGRectGetMinX(targetFrame) + distance.width;
		} else {
			newPosition = (CGPoint){
				CGRectGetMinX(targetFrame) + distance.width, 
				CGRectGetMinY(targetFrame) + distance.height
			};			
		}
		
		[assetEditor setValue:[NSValue valueWithCGPoint:newPosition] forKey:@"position"];
		[pool release];
	}
}

- (void)_performMoveMultipleAction:(NSEvent *)theEvent{	
	CGPoint startPoint = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
													fromView:nil]);
	CGRect targetFrame = m_multipleSelectionProxy.frame;
	
	NSMutableArray *startRects = [NSMutableArray arrayWithCapacity:
								  [m_multipleSelectionProxy.layers count]];
	CGFloat minX = CGRectGetMinX(auxLayer.frame) - CGRectGetWidth(targetFrame) + 
	kAssetInStagePadding;
	CGFloat maxX = CGRectGetMaxX(auxLayer.frame) - kAssetInStagePadding;
	CGFloat minY = CGRectGetMinY(auxLayer.frame) - CGRectGetHeight(targetFrame) + 
	kAssetInStagePadding;
	CGFloat maxY = CGRectGetMaxY(auxLayer.frame) - kAssetInStagePadding;
	
	for (CanvasSceneLayer *layer in m_multipleSelectionProxy.layers){
		AssetMO *asset = [layer representedObject];
		KeyframeAnimationMO *keyframeAnimation = asset.keyframeAnimation;
		KeyframeMO *keyframe = [keyframeAnimation ensureKeyframeForTime:self.currentTime];
		CGPoint position = [[keyframe valueForKey:@"position"] CGPointValue];
		CGRect bounds = [[keyframe valueForKey:@"bounds"] CGRectValue];
		CGRect itemFrame = (CGRect){position, bounds.size};
		[startRects addObject:[NSValue valueWithCGRect:itemFrame]];
		itemFrame = [keyframe rotatedFrame];
		
		CGPoint innerPosition = (CGPoint){CGRectGetMinX(itemFrame) - CGRectGetMinX(targetFrame), 
			CGRectGetMinY(itemFrame) - CGRectGetMinY(targetFrame)};
		minX = MAX(minX, CGRectGetMinX(auxLayer.frame) - CGRectGetWidth(itemFrame) - 
				   innerPosition.x + kAssetInStagePadding);
		maxX = MIN(maxX, CGRectGetMaxX(auxLayer.frame) - kAssetInStagePadding - innerPosition.x);
		minY = MAX(minY, CGRectGetMinY(auxLayer.frame) - CGRectGetHeight(itemFrame) - 
				   innerPosition.y + kAssetInStagePadding);
		maxY = MIN(maxY, CGRectGetMaxY(auxLayer.frame) - kAssetInStagePadding - innerPosition.y);
	}
	
	uint16_t mask = NSLeftMouseDownMask | NSLeftMouseDraggedMask | NSLeftMouseUpMask;		
	while ((theEvent = [NSApp nextEventMatchingMask:mask untilDate:[NSDate distantFuture] 
											 inMode:NSEventTrackingRunLoopMode dequeue:YES]) && ([theEvent type] != NSLeftMouseUp)){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		CGPoint point = NSPointToCGPoint([self convertPoint:[theEvent locationInWindow] 
												   fromView:nil]);
		CGSize distance = CGSizeZero;
		
		// lock X axis
		if ([NSEvent modifierFlags] & NSAlternateKeyMask) {
			distance.height = point.y - startPoint.y;
		// lock Y axis
		} else if ([NSEvent modifierFlags] & NSShiftKeyMask) {
			distance.width = point.x - startPoint.x;
		// no axis lock
		} else {
			distance = (CGSize){point.x - startPoint.x, point.y - startPoint.y};			
		}
		
		CGPoint newPosition = (CGPoint){CGRectGetMinX(targetFrame) + distance.width, 
			CGRectGetMinY(targetFrame) + distance.height};
						
		newPosition.x = MIN(MAX(newPosition.x, minX), maxX);
		newPosition.y = MIN(MAX(newPosition.y, minY), maxY);
		distance = (CGSize){newPosition.x - CGRectGetMinX(targetFrame), 
			newPosition.y - CGRectGetMinY(targetFrame)};
		
		for (NSInteger i = 0; i < [m_multipleSelectionProxy.layers count]; i++){
			CanvasSceneLayer *layer = [m_multipleSelectionProxy.layers objectAtIndex:i];
			AssetMO *asset = [layer representedObject];
			KeyframeAnimationMO *keyframeAnimation = asset.keyframeAnimation;
			KeyframeMO *keyframe = [keyframeAnimation ensureKeyframeForTime:self.currentTime];
			
			CGRect startRect = [[startRects objectAtIndex:i] CGRectValue];
			startRect.origin.x += distance.width;
			startRect.origin.y += distance.height;
			[keyframe setValue:[NSValue valueWithCGPoint:startRect.origin] forKey:@"position"];
		}
		[m_multipleSelectionProxy updateFrame];
		
		[pool release];
	}
}


- (void) _itemsChanged: (NSArray *) items
{
	// NSLog(@"itemsChanged: %@", [items valueForKey: @"name"]);	
	// NSMutableSet *newItems = [NSMutableSet setWithArray: items];
	
	NSSet *currentItems = [NSSet setWithArray: [self.assetsLayer.sublayers valueForKey: @"representedObject"]];
	
	NSMutableSet *itemsRemoved = [NSMutableSet setWithSet: currentItems];
	NSMutableSet *itemsAdded = [NSMutableSet set];
	
	for( id item in items ) {
		if( YES == [currentItems containsObject: item] ) {
			[itemsRemoved removeObject: item];
		} else {
			[itemsAdded addObject: item];
		}
	}
	
	if( 0 != [itemsRemoved count] ) {
		[self _removeLayersWithItems: itemsRemoved];
	}
	
	if( 0 != [itemsAdded count] ) {
		[self _createLayersWithItems: itemsAdded];
	}
}

- (void) _itemSelectionChanged: (NSArray *) selectedItems
{	
	if( [selectedItems count] <= 1 ) {
		[self _selectLayer: [self _layerWithItem: [selectedItems lastObject]]]; // lastObject is nil when array is empty
	} else {
		[self _selectLayers:[self _layersWithItems:selectedItems]];
	}
	
}


#pragma mark -
#pragma mark Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender{
	return NSDragOperationGeneric;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender{
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
	CGPoint point = NSPointToCGPoint([self convertPoint:[sender draggingLocation] 
											   fromView:nil]);
	point.x = roundf(point.x);
	point.y = roundf(point.y);
	
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSArray *types = [NSArray arrayWithObjects:kSTEAssetDragType, kSTECMSContentDragType, NSFilenamesPboardType, nil];
	NSString *desiredType = [pboard availableTypeFromArray:types];
	NSData *carriedData	= [pboard dataForType:desiredType];
	BOOL success = NO;
	
	if (!carriedData){
		return NO;
	}
	
	CGPoint localPoint = [self.assetsLayer.superlayer convertPoint:point fromLayer:self.layer];
	CALayer *dropLayer = [self.assetsLayer hitTest:localPoint];
	AssetMO *dropAsset = nil;
	if ([dropLayer isKindOfClass:[CanvasSceneLayer class]]){
		dropAsset = [(CanvasSceneLayer *)dropLayer representedObject];
	}
	
	if ([desiredType isEqualToString:NSFilenamesPboardType]){
		NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
		for (NSString *filename in filenames){
			BOOL isDir = NO;
			if (![[NSFileManager defaultManager] fileExistsAtPath:filename 
													  isDirectory:&isDir] || isDir){
				continue;
			}
#pragma warning There has to be a better way to check if a path point to a valid image file

			MediaContainer *mediaContainer = [[MediaContainer alloc] initWithURL: [NSURL fileURLWithPath: filename] cache: nil error: nil];
			success = YES;
			
			if (dropAsset){
				dropAsset.name = mediaContainer.name;
				dropAsset.primaryBlob.externalURL = [mediaContainer.URL absoluteString];
				return YES;
			}
			
			AssetDragVO *dragVO = [[AssetDragVO alloc] init];
			dragVO.name = mediaContainer.name;
			dragVO.contentType = nil; // mediaContainer.contentType;
			dragVO.type = [mediaContainer.typeIdentifier isEqualToString: (id)kUTTypeVideo] ? AssetDragVOTypeVideo : AssetDragVOTypeImage;
			dragVO.externalURL = [mediaContainer.URL absoluteString];

			[(id)_modelAccess createAssetFromDragData:dragVO atPoint:point];
			point.x += 10.0f;
			point.y += 10.0f;
			[dragVO release];
		}
	} else if ([desiredType isEqualToString:kSTEAssetDragType]){
		NSArray *dragData = [NSKeyedUnarchiver unarchiveObjectWithData:carriedData];
		for (AssetDragVO *dragVO in dragData){
			if (dropAsset){
				dropAsset.name = dragVO.name;
				dropAsset.primaryBlob.externalURL = dragVO.externalURL;
				dropAsset.primaryBlob.externalId = dragVO.externalId;
				return YES;
			}
			
			[(id)_modelAccess createAssetFromDragData:dragVO atPoint:point];
			point.x += 10.0f;
			point.y += 10.0f;
		}
		success = YES;
	} else if ([desiredType isEqualToString:kSTECMSContentDragType]){
		NSArray *dragData = [NSKeyedUnarchiver unarchiveObjectWithData:carriedData];
		for (AssetDragVO *dragVO in dragData){
			if (dropAsset && [dropAsset.kind intValue] == AssetMOKindImage){
				dropAsset.isButton = [NSNumber numberWithBool:YES];
				dropAsset.buttonTargetType = [NSNumber numberWithInt: ButtonTargetTypeExternalId];
				dropAsset.buttonTargetJumpId = dragVO.externalId;
				[dropLayer flash];
				return YES;
			}			
		}
		success = YES;
	}
	return success;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent{
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender{
}
@end

#pragma mark -
#pragma mark ModelAccess Observing


@implementation CanvasSceneView ( ModelAccessObserver )

- (void) assets: (NSArray *) assets didChange: (NSDictionary *) change
{
	[self _itemsChanged: assets];
}

- (void) selectedAssets: (NSArray *) selectedAssets didChange: (NSDictionary *) change
{
	[self _itemSelectionChanged: selectedAssets];
}

#if 0
- (void) assetsHidden: (NSArray *) assetsHidden didChange: (NSDictionary *) change
{
}

- (void) keyframes: (NSArray *) keyframes didChange: (NSDictionary *) change
{
}

- (void) keyframesTime: (NSArray *) keyframesTime didChange: (NSDictionary *) change
{
}
#endif

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// non-magic - comes from ModelAccess.m - calls selectors like [self selectedAssets:newValue didChange: changeDict]
	if( NO == [self processModelAccessObservationForKeyPath: keyPath ofObject:object change:change context:context] ) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
