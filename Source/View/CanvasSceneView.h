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

#import <Cocoa/Cocoa.h>

#import "ModelAccess.h"
#import "SceneView.h"
#import "CanvasSceneLayer.h"
#import "CanvasSceneTransformControlLayer.h"
#import "CanvasItem.h"
#import "Constants.h"
#import "AssetDragVO.h"
#import "NSMCGFunctions.h"
#import "CALayer+NSMAdditions.h"
#import "NSMFunctions.h"
#import "CanvasSceneLayerMultipleSelectionProxy.h"

@protocol CanvasSceneViewDelegate

- (void) removeCanvasItem:(CanvasItem*)item;

@end

@interface CanvasSceneView : SceneView {
	// this is NSObject instead of id because we use KVO
	NSObject <ModelAccess> *_modelAccess;

	NSMutableSet *m_layers;
	CanvasSceneLayer *m_selectedLayer;
	CanvasSceneTransformControlLayer *m_transformLayer;
	CanvasSceneLayerMultipleSelectionProxy *m_multipleSelectionProxy;
	BOOL m_spaceButtonDown;
	NSTrackingArea *m_trackingArea;
	BOOL m_mouseInside;
	
	NSNumber *m_currentTime;
	
	id<CanvasSceneViewDelegate> m_delegate;
}
@property (nonatomic, retain) NSObject <ModelAccess> *representedObject;
@property (nonatomic, retain) NSNumber *currentTime;
@property (nonatomic, assign) id<CanvasSceneViewDelegate> delegate;

- (void)_selectLayers:(NSArray *)layers;

@end
