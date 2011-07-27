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

#define USE_ST_ENGINE

#import <Cocoa/Cocoa.h>
#import <StoryTelling/viewutil.h>
#import "XMLTextView.h"

#ifdef USE_ST_ENGINE
#import <StoryTelling/BIPWidget.h>
#import <StoryTelling/BIPStage.h>
#import <StoryTelling/BIPScene.h>
#import <StoryTelling/BIPTreeNode.h>
#import <StoryTelling/BIPImageWidget.h>
#import <StoryTelling/BIPButton.h>
#import <StoryTelling/BIPViewController.h>
#import <StoryTelling/BIPStageController.h>
#import <StoryTelling/BIPSceneController.h>
#import <StoryTelling/BIPImageController.h>
#import <StoryTelling/BIPButtonController.h>

#import <StoryTelling/BIPTreeNode+NSObject.h>

#import <PhysicsEngine/BIPPhysicsEngineController.h>
#import <PhysicsEngine/BIPPhysicsEngineWidget.h>
#endif

#import "StageMO.h"
#import "SceneMO.h"
#import "AssetMO.h"
#import "KeyframeMO.h"

#define kXMLNamespace @"http:///www.storytellingeditor.org/storytelling/"
#define kXMLNamespacePhysics @"http://www.storytellingeditor.org/storytelling/physics"

#define kFPSForExport 25.0

@interface PreviewController : NSObject <NSTextViewDelegate> {
#ifdef USE_ST_ENGINE
    //BIPWidget*              root;
    //BIPStageController*     stageController;
#endif
	NSArrayController*		stageArrayController;
	NSView*					contentView;	
	NSButton*				closeButton;
	NSArrayController*		scenesArrayController;
	NSPanel*				panel;
	NSPanel*				xmlPanel;
	XMLTextView*				xmlTestBed;
}

#ifdef USE_ST_ENGINE
//@property (nonatomic, retain) BIPWidget *root;
//@property (nonatomic, retain) BIPStageController* stageController;

#endif
@property (nonatomic, retain) IBOutlet NSPanel *panel;
@property (nonatomic, retain) IBOutlet NSPanel *xmlPanel;
@property (nonatomic, retain) IBOutlet NSArrayController* stageArrayController;
@property (nonatomic, retain) IBOutlet NSArrayController* scenesArrayController;
@property (nonatomic, retain) IBOutlet NSView *contentView;
@property (nonatomic, retain) IBOutlet NSButton* closeButton;
@property (nonatomic, retain) IBOutlet XMLTextView* xmlTestBed;

- (void)playStoryTelling:(NSString*)xml;
- (void)playPhysics:(NSString*)xml;

- (NSString*)renderStageAsXML:(StageMO*)stage baseURL:(NSString*)baseURL startingAtScene:(SceneMO*)startScene variableSpeed:(BOOL)variableSpeed preview:(BOOL)previewMode;
- (IBAction)previewAction:(id)sender;
- (IBAction)previewStartAtSelectedSceneAction:(id)sender;
- (IBAction)renderXMLAction:(id)sender;
- (IBAction)openXMLPanelAction:(id)sender;
- (IBAction)testXMLAction:(id)sender;

- (NSString*)createXMLTempFileForXML:(NSString*)XML;

- (NSString*)triggerForTransition:(TransitionMO*)transition;
- (NSXMLElement*)keyFrameElementWithTime:(CGFloat)time 
							translationX:(int)translationX
							translationY:(int)translationY
								  scaleX:(CGFloat)scaleX
								  scaleY:(CGFloat)scaleY
								rotation:(CGFloat)rotation
								  easing:(int)easing
								   alpha:(CGFloat)alpha;
- (void)ensureContentURLSAreAvailableShowWarning:(BOOL)doShowWarning;
- (NSString*)xmlIDForManagedObject:(NSManagedObject*)managedObject;

@end
