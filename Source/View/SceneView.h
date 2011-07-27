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
#import <QuartzCore/QuartzCore.h>

#import "SceneMO.h"
#import <EngineRoom/EngineRoom.h>
#import "Constants.h"

#define kLayerZPositionRoot (-100)
#define kLayerZPositionVisibleArea (-30)
#define kLayerZPositionAux (100)
#define kLayerZPositionAssets (10)
#define kLayerZPositionMask (99)
#define kLayerZPositionTest (10000)


@interface SceneView : NSView {
	SceneMO *scene;
	NSInteger borderPercentage;

	CALayer *visibleAreaLayer;
	CALayer *assetsLayer;
	CALayer *auxLayer;
	CALayer *maskLayer;
	CALayer *testLayer;

	NSSize visibleSize;
	NSRect pageBounds;
	NSArray *_defaultsKeys;
}

@property(nonatomic, retain) SceneMO *scene;
@property(nonatomic, assign) NSInteger borderPercentage;

@property(nonatomic, retain) NSNumber *width;
@property(nonatomic, retain) NSNumber *height;

@property(nonatomic, retain) NSNumber *pageWidth;
@property(nonatomic, retain) NSNumber *pageHeight;

@property(nonatomic, assign) NSRect pageBounds;
@property(nonatomic, assign) NSSize visibleSize;

@property(nonatomic, retain) CALayer *visibleAreaLayer;
@property(nonatomic, retain) CALayer *assetsLayer;
@property(nonatomic, retain) CALayer *auxLayer;
@property(nonatomic, retain) CALayer *maskLayer;
@property(nonatomic, retain) CALayer *testLayer;

- (id) setup;

@end
