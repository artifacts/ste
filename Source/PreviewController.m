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

#define WORKAROUND_FLIP_ROTATION_FOR_PREVIEW_XML 1

#import <EngineRoom/EngineRoom.h>
#import "RegexKitLite.h"
#import "BKColor.h"

@interface NSValue(WeCanNotIncludeEngineRoomsCrossPlatformHHereBecauseItCollidesWithSTEnginesCommonHButWeNeedTheDeclarations)
- (CGRect) CGRectValue;
- (CGPoint) CGPointValue;
- (CGSize) CGSizeValue;
@end

#import "PreviewController.h"
#import <AFCache/AFCacheLib.h>
#import "NSManagedObject_DictionaryRepresentation.h"
#import "Constants.h"
#import "PreviewController+Physics.h"
#import "MediaContainer.h"
#import "NSWindow+Util.h"

@implementation PreviewController

@synthesize panel, stageArrayController, scenesArrayController, contentView, closeButton, xmlPanel, xmlTestBed;
#ifdef USE_ST_ENGINE
//@synthesize root;
#endif

/* ================================================================================================
 * Internal methods
 * ================================================================================================ */

- (void)_initViewControllers
{
#ifdef USE_ST_ENGINE	
    [BIPViewController addViewControllerClass:[BIPStageController class] forModelClass:[BIPStage class]];
    [BIPViewController addViewControllerClass:[BIPSceneController class] forModelClass:[BIPScene class]];
    [BIPViewController addViewControllerClass:[BIPImageController class] forModelClass:[BIPImageWidget class]];
    [BIPViewController addViewControllerClass:[BIPButtonController class] forModelClass:[BIPButton class]];
#endif
}

/* ================================================================================================
 * Init
 * ================================================================================================ */

- (void)awakeFromNib {
    [self _initViewControllers];
	[panel setBackgroundColor:[NSColor blackColor]];
}

/* ================================================================================================
 * Show warning if content urls are file URLs
 * ================================================================================================ */

- (void)ensureContentURLSAreAvailableShowWarning:(BOOL)doShowWarning {
	
	NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	BOOL showWarningPreference = [[currentDefaults objectForKey:kSTEShowAssetURLSNotPublicWarning] boolValue];	

	NSDate *now = [NSDate date];
	NSMutableArray *assetsWithUnpublishedURLs = [NSMutableArray array];
	for (SceneMO *scene in [scenesArrayController arrangedObjects]) {
		for (AssetMO *asset in scene.assets) {
			MediaContainer *mediaContainer = asset.primaryBlob.mediaContainer;
			NSURL *renderedURL = mediaContainer.renderedURL;
			
			if( nil == mediaContainer ) {
				lperror("no mediaContainer");
			}
			
			
			if( nil == renderedURL ) {
				lperror("no renderedURL");
			}
			
			if( YES == [[renderedURL scheme] isEqualToString: @"file"] ) {
				lpwarning("importing image into AFCache", renderedURL);
				
				AFCacheableItem *item = [[AFCacheableItem alloc] initWithURL:renderedURL lastModified:now expireDate:[now dateByAddingTimeInterval:300]];
                int retryCount = 0;
                // mm, 2011/03/21, HACK: We have a race contition here.
                // Before trying to import the cacheableItem, there's already a request pending, triggered by the mediaContainer.
                // importCacheableItem: won't import items for URLs that are currently beeing processed in order not to overwrite files that are beeing downloaded
                // or f*cking up the download queue.
                // I think we seriously need synchroneuous requests or some clever way to ensure that we have all the data we need when proceeding.
                // Maybe we should add apply the concept of a Future to AFCacheableItem and add the methods wait, get and waitUntil:
                // In cases like this, the above accessor which implicitly triggers the loading could wait until finished.
                // See: http://en.wikipedia.org/wiki/Future_(programming)
                
                // There's another Problem: UI reponsiveness. When one Thread has to wait for an URL reponse, the user should be informed if it takes
                // longer than e.g. 3 seconds
                
				while (NO == [[AFCache sharedInstance] importCacheableItem:item withData: mediaContainer.renderedData] && retryCount < 10) {
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                    lperror(@"Failed to import cacheableItem. Maybe there's a download running. Retrying...", retryCount);
                    retryCount++;
                }
				[assetsWithUnpublishedURLs addObject:asset.name];
			}
		}
	}
	if (doShowWarning && showWarningPreference == YES && [assetsWithUnpublishedURLs count] > 0) {

		NSMutableString *errorMessage = [NSMutableString stringWithString:@"Folgende Assets sind nicht online verfügbar:\n\n"];
		for (NSString *name in assetsWithUnpublishedURLs) {
			[errorMessage appendFormat:@"%@\n", name];
		}
		[errorMessage appendString:@"\nBitte ändern Sie die Quellen der Assets bevor sie das StoryTelling exportieren."];

		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Unpublizierte Inhalte"];
		[alert setInformativeText:errorMessage];
		[alert setShowsSuppressionButton:YES];
		[[alert suppressionButton] setTitle:@"Diese Meldung nicht wieder anzeigen"];
		
		[alert runModal];
		if ([[alert suppressionButton] state] == NSOnState) {
			// Suppress this alert from now on.
			[currentDefaults setBool:NO forKey:kSTEShowAssetURLSNotPublicWarning];
		}
		[alert release];
	}
}

/* ================================================================================================
 * Preview Button pressed
 * ================================================================================================ */

- (IBAction)previewAction:(id)sender {	
	[self ensureContentURLSAreAvailableShowWarning:NO];
	StageMO *stage = [stageArrayController valueForKeyPath:@"selection.self"];
	
	BOOL physicsEnabled = [[stage valueForKey:@"physicsEnabled"] boolValue];
	NSString *xml = nil;
	
	if (physicsEnabled == YES) {
		SceneMO *scene = [scenesArrayController valueForKeyPath:@"selection.self"];
		xml = [self renderSceneAsPhysicsXML:scene baseURL:nil preview:YES];
		[self playPhysics:xml];
	} else {
		StageMO *stage = [stageArrayController valueForKeyPath:@"selection.self"];
		xml = [self renderStageAsXML:stage baseURL:nil startingAtScene:nil variableSpeed: YES preview: YES];
		[self playStoryTelling:xml];
	}
}

/* ================================================================================================
 * Show preview starting at selected scene
 * ================================================================================================ */

- (IBAction)previewStartAtSelectedSceneAction:(id)sender {
	[self ensureContentURLSAreAvailableShowWarning:NO];
	StageMO *stage = [stageArrayController valueForKeyPath:@"selection.self"];
	SceneMO *scene = [scenesArrayController valueForKeyPath:@"selection.self"];
	NSString *xml = [self renderStageAsXML:stage baseURL:nil startingAtScene:scene variableSpeed: YES preview: YES];	
	[self playStoryTelling:xml];
}

/* ================================================================================================
 * Render XML for StoryTellingEngine
 * ================================================================================================ */

- (IBAction)renderXMLAction:(id)sender {
	[self ensureContentURLSAreAvailableShowWarning:YES];

	StageMO *stage = [stageArrayController valueForKeyPath:@"selection.self"];
	BOOL physicsEnabled = [[stage valueForKey:@"physicsEnabled"] boolValue];
	NSString *xml = nil;
	
	if (physicsEnabled == YES) {
		SceneMO *scene = [scenesArrayController valueForKeyPath:@"selection.self"];
		xml = [self renderSceneAsPhysicsXML:scene baseURL:nil preview:NO];
	} else {
		StageMO *stage = [stageArrayController valueForKeyPath:@"selection.self"];
		xml = [self renderStageAsXML:stage baseURL:nil startingAtScene:nil variableSpeed: NO preview: NO];
	}
	
	[self createXMLTempFileForXML:xml];	
}

/* ================================================================================================
 * Show XML
 * ================================================================================================ */

- (IBAction)openXMLPanelAction:(id)sender {
	StageMO *stage = [stageArrayController valueForKeyPath:@"selection.self"];
	SceneMO *scene = [scenesArrayController valueForKeyPath:@"selection.self"];
	NSString *xml = [self renderStageAsXML:stage baseURL:nil startingAtScene:scene variableSpeed: YES preview: YES];	
	[xmlPanel makeKeyAndOrderFront:sender];
	[xmlTestBed setString:xml];
}

/* ================================================================================================
 * Test Button pressed
 * ================================================================================================ */

- (IBAction)testXMLAction:(id)sender {
	[self playStoryTelling:[xmlTestBed plaintext]];
}

/* ================================================================================================
 * Returns a coredata object id, but without any suspicious characters
 * ================================================================================================ */

- (NSString*)xmlIDForManagedObject:(NSManagedObject*)managedObject {
	NSString *objID = [[[managedObject objectID] URIRepresentation] absoluteString];
	NSString *xmlID = [objID stringByReplacingOccurrencesOfRegex:@"[^A-Za-z0-9]" withString:@"_"];
	return xmlID;
}

/* ================================================================================================
 * Create temp file for XML output
 * ================================================================================================ */

- (NSString*)createXMLTempFileForXML:(NSString*)XML {
	NSString *XMLFile = [NSTemporaryDirectory() stringByAppendingFormat: @"stage-%.1lf.xml", [NSDate timeIntervalSinceReferenceDate]];
	
	NSError *error = nil;
	
	if( NO == [XML writeToFile: XMLFile atomically: YES encoding: NSUTF8StringEncoding error: &error] ) {
		[NSApp presentError: error];
	} else {
		[[NSWorkspace sharedWorkspace] openFile: XMLFile];
	}
	return XMLFile;
}

/* ================================================================================================
 * Resize Panel to correct height
 * ================================================================================================ */

- (void)_resizePanel:(NSPanel*)thePanel toSize:(NSSize)size animate:(BOOL)bFlag{
	NSRect windowFrame = [thePanel frame];
	int toolbarHeight = NSHeight(windowFrame) - NSHeight([[thePanel contentView] frame]);
	int neededWindowSize = size.height + toolbarHeight;
	int sizeOffset = NSHeight([thePanel frame]) - neededWindowSize;
	windowFrame.origin.y += sizeOffset;
	windowFrame.size.height = neededWindowSize;
	windowFrame.size.width = size.width == -1 ? windowFrame.size.width : size.width;
	[thePanel setFrame:windowFrame display:YES animate:bFlag];
}

/* ================================================================================================
 * Play StoryTelling XML in preview
 * ================================================================================================ */

- (void)playStoryTelling:(NSString*)xml {
#ifdef USE_ST_ENGINE	
	for (NSView *view in [panel.contentView subviews]) {
		[view removeFromSuperview];
	}
    NSData* xmlData = [xml dataUsingEncoding:NSUTF8StringEncoding];
    BIPTreeNode* theRoot = [BIPTreeNode treeNodeWithXMLData:xmlData];
	
    BIPWidget *root = [NSObject objectWithTreeNode:theRoot];
    ((BIPStage*)root).baseURL = [[NSBundle mainBundle] resourceURL];
    BIPStageController *stageController = [[BIPStageController alloc] initWithWidget:root]; // autorelease];
    [stageController.view.layer setMasksToBounds:YES];

	CGSize size;
	size.width = ((BIPStage*)root).width;
	size.height = ((BIPStage*)root).height;

	if (size.width > 0 && size.height > 0) {
		[self _resizePanel:panel toSize:size animate:YES];
	}
    [panel.contentView addSubview:stageController.view];
	
	stageController.view.frame = [panel.contentView bounds];
	
	[panel makeKeyAndOrderFront:nil];	
	
    [stageController start];
#endif
}


#pragma mark -
#pragma mark physics

/* ================================================================================================
 * Play Physics XML in preview
 * ================================================================================================ */

- (void)playPhysics:(NSString*)xml {
#ifdef USE_ST_ENGINE	
	for (NSView *view in [panel.contentView subviews]) {
		[view removeFromSuperview];
	}
	CGSize size = CGSizeZero;
    NSData* xmlData = [xml dataUsingEncoding:NSUTF8StringEncoding];
	NSLog(@"playPhysics: with XML: %@", xml);
    	
	size.width = [[[stageArrayController selection] valueForKey:@"width"] floatValue];
	size.height = [[[stageArrayController selection] valueForKey:@"height"] floatValue];
    
    BIPTreeNode* treeNode = [[BIPTreeNode alloc] init];
	//[treeNode.attributes setObject:[[[NSBundle mainBundle] URLForResource:@"teststage.xml" withExtension:nil]absoluteString] forKey:@"stageURL"];
    BIPPhysicsEngineWidget* physicsWidget = [[BIPPhysicsEngineWidget alloc] initWithTreeNode:treeNode];
	physicsWidget.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
	BIPPhysicsEngineController* controller = [[BIPPhysicsEngineController alloc] initWithWidget:physicsWidget];
	[controller loadStageWithXMLData:xmlData];	
		
	
	if (size.width > 0 && size.height > 0) {
		[self _resizePanel:panel toSize:size animate:YES];
	}
    [panel.contentView addSubview:controller.view];
	
	controller.view.frame = [panel.contentView bounds];
	
	[panel makeKeyAndOrderFront:nil];	
	
//    [controller start];
#endif
}


/* ================================================================================================
 * Render stage as XML conforming story-telling.xsd
 * ================================================================================================ */

- (NSString*)renderStageAsXML:(StageMO*)stage baseURL:(NSString*)baseURL startingAtScene:(SceneMO*)startScene variableSpeed:(BOOL)variableSpeed preview:(BOOL)previewMode {
	CGFloat fps = kFPSForExport;

	if (variableSpeed == YES) {
		fps  = kFPSForExport * [[[NSUserDefaults standardUserDefaults] 
									valueForKey:kSTEPreviewFPSMultiplier] floatValue];
	}
		
	CGRect originAssetBounds = CGRectZero;
	NSError *error = nil;
	NSString *XSDPath = [[NSBundle mainBundle] pathForResource:@"story-telling.xsd" ofType:nil];
	NSURL *XSDURL = [NSURL fileURLWithPath:XSDPath];
	CGPoint stagePosition = CGPointZero;
	stagePosition.x = 0;
	stagePosition.y = 0;
	
	NSString *userInteractionEnabledStringValue = [stage.userInteractionEnabled boolValue]?@"true":@"false";
	NSXMLElement *rootElement = [NSXMLNode elementWithName:@"stage" children:nil attributes:[NSArray arrayWithObjects:
																							 [NSXMLNode attributeWithName:@"xmlns" stringValue:kXMLNamespace],
																							 [NSXMLNode attributeWithName:@"xmlns:xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"],																							
																							 //[NSXMLNode attributeWithName:@"xsi:schemaLocation" stringValue:[NSString stringWithFormat:@"%@ %@", kXMLNamespace, [XSDURL absoluteString]]],
																							 [NSXMLNode attributeWithName:@"xsi:noNamespaceSchemaLocation" stringValue:[XSDURL absoluteString]],
																							 [NSXMLNode attributeWithName:@"id" stringValue:@"stage"],
																							 [NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%d", (int)stagePosition.x]],
																							 [NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%d", (int)stagePosition.y]],
																							 [NSXMLNode attributeWithName:@"width" stringValue:[stage.width stringValue]],
																							 [NSXMLNode attributeWithName:@"height" stringValue:[stage.height stringValue]],
																							 [NSXMLNode attributeWithName:@"userInteractionEnabled" stringValue:userInteractionEnabledStringValue],																							 
																							 nil]];
	
	if ([baseURL length]>0) {
		[rootElement addAttribute:[NSXMLNode attributeWithName:@"baseURL" stringValue:baseURL]];
	}
	
	BOOL isLastScene = NO;
	TransitionMO *transitionToNext = nil;
	BOOL startSceneRendered = NO;
	NSString *sceneID = nil;
	for (SceneMO *scene in [scenesArrayController arrangedObjects]) {
		CGFloat sceneDuration = 0;

		startSceneRendered = startSceneRendered || (startScene == scene);
		if (startScene != nil && !startSceneRendered) continue;
		if (scene == [[scenesArrayController arrangedObjects] lastObject]) isLastScene = YES;
		if ([scene.hidden boolValue] == YES) continue;
		
		CGPoint scenePosition;
		scenePosition.x = 0;
		scenePosition.y = 0;
		sceneID = [self xmlIDForManagedObject:scene];
						
		// determine scene duration by searching for the keyframe with the highest time value
		CGFloat lastKeyframeTime = 0;
		for (AssetMO *asset in scene.assets) {
			if ([asset.hidden boolValue] == YES) continue;
			lastKeyframeTime = (float)[[[asset.keyframeAnimation.orderedKeyframes lastObject] time] intValue] / fps;
			sceneDuration = fmax(sceneDuration, lastKeyframeTime);
		}
		NSLog(@"sceneDuration: %f", sceneDuration);
		
		NSXMLElement *sceneElement = [NSXMLNode elementWithName:@"scene" children:nil attributes:[NSArray arrayWithObjects:
																								  [NSXMLNode attributeWithName:@"duration" stringValue:[NSString stringWithFormat:@"%f", sceneDuration]],
																								  [NSXMLNode attributeWithName:@"id" stringValue:sceneID],
																								  [NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%d", (int)scenePosition.x]],
																								  [NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%d", (int)scenePosition.y]],
																								  [NSXMLNode attributeWithName:@"width" stringValue:[stage.width stringValue]],
																								  [NSXMLNode attributeWithName:@"height" stringValue:[stage.height stringValue]],																								  
																								  //[NSXMLNode attributeWithName:@"trigger" stringValue:sceneTrigger],																								
																								  nil]];
		CGRect bounds = CGRectZero;
		CGPoint originAssetPosition = CGPointZero;
		NSString *jumpToSceneID = @"";
		NSString *jumpToWidgetID = @"";
		NSString *assetID = nil;
		for (AssetMO *asset in scene.assets) {			
			if ([asset.hidden boolValue] == YES) continue;
			NSArray *orderedKeyframes = asset.keyframeAnimation.orderedKeyframes;

			MediaContainer *mediaContainer = asset.primaryBlob.mediaContainer;

			// take rendered urls from mediacontainer for preview (we want to read the compressed images from the cache)
			// for export, take orginal image urls, to do not break the mapping between the ImportExport xml and the BIPStageXML
			// this is more or less a workaroung, TODO: better concept for image urls in XML Export and get rid of the two xmls
			// evaluate if the preview xml rendering part would better be done in XSLT...
			
			NSURL *renderedURL = (previewMode==YES)?mediaContainer.renderedURL:[NSURL URLWithString:[asset primaryBlob].externalURL];
			NSString *renderedURLString = [renderedURL absoluteString]; 
			
			assetID = [self xmlIDForManagedObject:asset];
			SceneMO *triggeredScene = asset.triggeredScene;
			
			jumpToSceneID = [self xmlIDForManagedObject:triggeredScene];
			
			// don't allow triggering our own scene if the transition would occur automatically -> results in endless loop of the engine -> crash. we not want crash.
			if (triggeredScene == scene) {
				if ([scene.transitionToNext.trigger intValue] == kTransitionTriggerTypeAutomatic) {
					jumpToSceneID = nil;
				}
			}
			
			jumpToWidgetID = asset.buttonTargetJumpId;
			NSInteger buttonType = [asset.buttonTargetType integerValue];
			
			for (KeyframeMO *kf in orderedKeyframes) {
				originAssetPosition = [[kf valueForKey: @"position"] CGPointValue];
				originAssetBounds.size = NSSizeToCGSize([mediaContainer.renderedBitmapImageRep size]);
				break; // just the first
			}
			
			NSString *assetElementName = nil;
			NSXMLNode *urlAttribute = nil;
			NSXMLNode *inactiveImageURLAttribute = nil;
			NSXMLElement *activateElement = nil;
			NSXMLNode *buttonGroupAttr = nil;
			NSInteger lastKeyTime = 0;
			
			// asset is a BUTTON
			if ([asset.isButton boolValue] == YES) {
				assetElementName = @"button";
				urlAttribute = [NSXMLNode attributeWithName:@"activeImageURL" stringValue: renderedURLString];
				if (asset.inactiveButtonImage.externalURL != nil) {
					inactiveImageURLAttribute = [NSXMLNode attributeWithName:@"inactiveImageURL" stringValue:asset.inactiveButtonImage.externalURL];
				}
				
				switch (buttonType) {
					// jump to scene
					case ButtonTargetTypeScene:
						if ([jumpToSceneID length] == 0) goto fallback;
						NSXMLElement *jumpToSceneElement = [NSXMLNode elementWithName:@"jumpToScene" children:nil attributes: [NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"sceneID" stringValue:jumpToSceneID], nil]];
						activateElement = [NSXMLNode elementWithName:@"activate" children:[NSArray arrayWithObject:jumpToSceneElement] attributes: nil];										
						break;
					// jump to widget
					case ButtonTargetTypeExternalId:
						if ([jumpToWidgetID length] == 0) goto fallback;
						NSXMLElement *jumpToWidgetElement = [NSXMLNode elementWithName:@"open" children:nil attributes: [NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"targetID" stringValue:jumpToWidgetID], nil]];
						activateElement = [NSXMLNode elementWithName:@"activate" children:[NSArray arrayWithObject:jumpToWidgetElement] attributes: nil];										
						break;
					// button target is invalid, export as image. todo: maybe we should display an error message?
					default:
					fallback:						
						assetElementName = @"image";
						inactiveImageURLAttribute = nil;
						urlAttribute = [NSXMLNode attributeWithName:@"imageURL" stringValue: renderedURLString];
						break;
				}
				NSString *group = asset.parent.name;
				if ([group length] > 0) buttonGroupAttr = [NSXMLNode attributeWithName:@"group" stringValue:group];					
			}
			// asset is no button
			else {
				NSInteger assetType = [asset.kind intValue];
				switch (assetType) {
					case AssetMOKindImage:
						assetElementName = @"image";
						urlAttribute = [NSXMLNode attributeWithName:@"imageURL" stringValue: renderedURLString];						
						break;
					case AssetMOKindVideo:
						assetElementName = @"video";
						urlAttribute = [NSXMLNode attributeWithName:@"contentURL" stringValue: renderedURLString];						
						break;
				}
			}
			
			NSXMLElement *assetElement = [NSXMLNode elementWithName:assetElementName children:nil attributes:[NSArray arrayWithObjects:
																											  [NSXMLNode attributeWithName:@"id" stringValue:assetID],																									  
																											  [NSXMLNode attributeWithName:@"z" stringValue:[asset.viewPosition stringValue]],
																											  [NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%d", (int)originAssetPosition.x]],
																											  [NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%d", (int)originAssetPosition.y]],
																											  [NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%d", (int)originAssetBounds.size.width]],
																											  [NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%d", (int)originAssetBounds.size.height]],																											  
																											  nil]];
			if (urlAttribute) [assetElement addAttribute:urlAttribute];
			if (inactiveImageURLAttribute) [assetElement addAttribute:inactiveImageURLAttribute];
			if (buttonGroupAttr) [assetElement addAttribute:buttonGroupAttr];
			
			NSXMLElement *eventElement = [NSXMLNode elementWithName:@"event" children:nil attributes:[NSArray arrayWithObjects:
																									  [NSXMLNode attributeWithName:@"type" stringValue:@"enter"],
																									  nil]];
			lastKeyTime = [[[orderedKeyframes lastObject] time] integerValue];
			float duration = (float)lastKeyTime / fps;

			// looping
			NSString *loopValue = nil;
			switch ([asset.keyframeAnimation.loop intValue]) {
				case LoopEndless:
					loopValue = @"endless";				
					break;
				case LoopPingPong:
					loopValue = @"pingpong";				
					break;
				default:
					loopValue = @"none";
					break;
			}
			
			NSXMLElement *kfAniElement = [NSXMLNode elementWithName:@"keyFrameAnimation" children:nil attributes:[NSArray arrayWithObjects:
																												  [NSXMLNode attributeWithName:@"timingFunction" stringValue:@"ease-in-out"],
																												  [NSXMLNode attributeWithName:@"duration" stringValue:[NSString stringWithFormat:@"%f", duration]],
																												  [NSXMLNode attributeWithName:@"loop" stringValue:loopValue],
																												  nil]];
			CGFloat rotation = 0;
			CGFloat scaleX = 0;
			CGFloat scaleY = 0;
			CGPoint translation;
			CGPoint currentPosition;
			CGPoint initialPosition;
			CGPoint offset;
			BOOL isFirstKeyframe = NO;
			BOOL isLastKeyframe = NO;
			
			for (KeyframeMO *kf in orderedKeyframes) {
				isFirstKeyframe = ([orderedKeyframes indexOfObject:kf] == 0)?YES:NO;
				isLastKeyframe = (kf == [orderedKeyframes lastObject])?YES:NO;
				// get asset bounds
				bounds = [[kf valueForKey: @"bounds"] CGRectValue];
				
				if (isFirstKeyframe == YES) {
					initialPosition = [[kf valueForKey: @"position"] CGPointValue];
				}
				
				// calculate rotation
				rotation = (RAD2DEG([[kf valueForKey: @"rotation"] floatValue]));
#if WORKAROUND_FLIP_ROTATION_FOR_PREVIEW_XML==1
				if (previewMode == YES) {
					rotation *= -1;
				}
#endif
				// get current position and calculate translation
				currentPosition = [[kf valueForKey: @"position"] CGPointValue];								
				translation.x = currentPosition.x - initialPosition.x;
				translation.y = currentPosition.y - initialPosition.y;

				// take scaling into account when calculating translation
				offset.x = (originAssetBounds.size.width - bounds.size.width) * 0.5;
				offset.y = (originAssetBounds.size.height - bounds.size.height) * 0.5;				
				translation.x -= offset.x;
				translation.y -= offset.y;
				
				// calculate scaling
				scaleX = bounds.size.width / originAssetBounds.size.width;
				scaleY = bounds.size.height / originAssetBounds.size.height;
				
				/* --------------------------------------------------------------------------------
				 * if first keyframe's time is > 0, add two additional keyframes to hide asset
				 * --------------------------------------------------------------------------------*/
				if (isFirstKeyframe == YES && [kf.time intValue] > 0) {
					NSXMLElement *kfElement = [self keyFrameElementWithTime:0 
															   translationX:(int)((isFirstKeyframe == YES)?0:translation.x)
															   translationY:(int)((isFirstKeyframe == YES)?0:translation.y)
																	 scaleX:scaleX
																	 scaleY:scaleY
																   rotation:rotation
																	 easing:[[kf.properties valueForKey:@"easing"] intValue]
																	  alpha:0];
					[kfAniElement addChild:kfElement];
					kfElement = [self keyFrameElementWithTime:((float)[kf.time intValue] / fps - 0.00000000001) // 1.0/61.0) 
												 translationX:(int)((isFirstKeyframe == YES)?0:translation.x)
												 translationY:(int)((isFirstKeyframe == YES)?0:translation.y)
													   scaleX:scaleX
													   scaleY:scaleY
													 rotation:rotation
													   easing:[[kf.properties valueForKey:@"easing"] intValue]
														alpha:0];
					[kfAniElement addChild:kfElement];						
				}
				
				float alpha = [[kf valueForKey: @"opacity"] floatValue];
				NSXMLElement *kfElement = [self keyFrameElementWithTime:((float)[kf.time intValue] / fps) 
														   translationX:translation.x
														   translationY:translation.y
																 scaleX:scaleX
																 scaleY:scaleY
															   rotation:rotation
																 easing:[[kf.properties valueForKey:@"easing"] intValue]
																  alpha:alpha];
				[kfAniElement addChild:kfElement];
				
				/* ----------------------------------------------------------------------------------------
				 * if last keyframe's time is < scene duration, add an additional keyframe to hide asset
				 * ----------------------------------------------------------------------------------------*/
				NSInteger kfTime = [kf.time integerValue];
				//float kfTimeSecs = (float)kfTime / fps;
				if (isLastKeyframe == YES && kfTime < (int)(sceneDuration*fps)) {
					NSXMLElement *kfElement = [self keyFrameElementWithTime:(float)[kf.time intValue]/fps + 0.00000000001 // 1.0/61.0
															   translationX:(int)((isFirstKeyframe == YES)?0:translation.x)
															   translationY:(int)((isFirstKeyframe == YES)?0:translation.y)
																	 scaleX:scaleX
																	 scaleY:scaleY
																   rotation:rotation
																	 easing:[[kf.properties valueForKey:@"easing"] intValue]
																	  alpha:0];
					[kfAniElement addChild:kfElement];
				}
			}
			// workaround to avoid flickering:
			// only 1 keyframe - duplicate kf and set time of kf to 0.000001, alpha of first kf to 0
			if ([[kfAniElement children] count] == 1) {
				NSXMLElement *soleKeyframe = [[kfAniElement children] objectAtIndex:0];
				float keyTime = [[[soleKeyframe attributeForName:@"keyTime"] stringValue] floatValue];
				if (keyTime == 0) {
					NSXMLElement *dupKeyframe = [soleKeyframe copy];
					// set alpha of first kf to 0
					for (int i = 0; i<[[soleKeyframe children] count]; i++) {
						if ([[[[soleKeyframe children] objectAtIndex:i] name] isEqualToString:@"alpha"]) {
							[soleKeyframe removeChildAtIndex:i];
						}
					}
					[soleKeyframe addChild:[NSXMLElement elementWithName:@"alpha" children:nil attributes:[NSArray arrayWithObject:[NSXMLElement attributeWithName:@"value" stringValue:@"0"]]]];

					// set keyTime to 0.0000001
					[dupKeyframe removeAttributeForName:@"keyTime"];
					[dupKeyframe addAttribute:[NSXMLElement attributeWithName:@"keyTime" stringValue:@"0.0000001"]];
					
					[kfAniElement addChild:dupKeyframe];
					[dupKeyframe release];
				}
			}
			[eventElement addChild:kfAniElement];
			[assetElement addChild:eventElement];
			if (activateElement) [assetElement addChild:activateElement];
			[sceneElement addChild:assetElement];
			transitionToNext = scene.transitionToNext;
		}
		[rootElement addChild:sceneElement];

		// render transition element
		NSArray *fadeAttributes = nil;
		if (transitionToNext) {
			NSString *typeName = nil;
			int transitionTypeInt = [transitionToNext.transitionType intValue];
			NSString *fadeThroughGenericRGBA = nil;
			NSNumber *fadeDuration = [transitionToNext duration];
			NSNumber *fadeOffset = [transitionToNext.properties objectForKey:@"offset"];

			if (fadeOffset == nil) fadeOffset = [NSNumber numberWithFloat:0];
			if (fadeDuration == nil) fadeDuration = [NSNumber numberWithFloat:0];
			
			switch (transitionTypeInt) {					
				case kTransitionTypeNone:
					typeName = @"switchTransition";
					fadeAttributes = [NSArray arrayWithObjects:
									  [NSXMLNode attributeWithName:@"trigger" stringValue:[self triggerForTransition:transitionToNext]], nil];
					break;
				case kTransitionTypeFade:
					typeName = @"crossFadeTransition";
					fadeAttributes = [NSArray arrayWithObjects:
									  [NSXMLNode attributeWithName:@"duration" stringValue:[fadeDuration stringValue]],
									  [NSXMLNode attributeWithName:@"offset" stringValue:[fadeOffset stringValue]],
									  [NSXMLNode attributeWithName:@"trigger" stringValue:[self triggerForTransition:transitionToNext]], nil];
					break;
				case kTransitionTypeFadeThroughColor:
					typeName = @"fadeThroughColorTransition";
					fadeThroughGenericRGBA = [[transitionToNext valueForKey: @"backgroundColor"] genericRGBAString];
					fadeThroughGenericRGBA = fadeThroughGenericRGBA ? [fadeThroughGenericRGBA substringToIndex: 7] : @"#ffffff";
					fadeAttributes = [NSArray arrayWithObjects:
									  [NSXMLNode attributeWithName:@"fadeOutTime" stringValue:[fadeDuration stringValue]],
									  [NSXMLNode attributeWithName:@"fadeInTime" stringValue:[fadeDuration stringValue]],
									  [NSXMLNode attributeWithName:@"color" stringValue: fadeThroughGenericRGBA],									  
									  [NSXMLNode attributeWithName:@"trigger" stringValue:[self triggerForTransition:transitionToNext]], nil];
					break;
			}
			if ([typeName length] > 0) {
				NSXMLElement *transitionElement = [NSXMLNode elementWithName:typeName children:nil attributes:fadeAttributes];
				[rootElement addChild:transitionElement];
			}
		}
	}
	
	NSXMLDocument *xmlDoc = [[NSXMLDocument alloc]
							 initWithRootElement:rootElement];
	
	int options = 0;
	NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
	if ([[currentDefaults objectForKey:kSTEPrettyPrintXML] boolValue] == YES) {
		options = NSXMLNodePrettyPrint;
	}
	
	NSData *data = [xmlDoc XMLDataWithOptions:options];
	NSString *XMLString = [[[NSString alloc] initWithBytes:[data bytes] 
													length:[data length] 
												  encoding: NSUTF8StringEncoding] autorelease];
	
	// validate against XSD
	BOOL isValid = [xmlDoc validateAndReturnError:&error];	
	if (isValid) {
		NSLog(@"document is valid");
	} else {
		NSLog(@"document is invalid: %@", [error localizedDescription]);	
	}
	
	[xmlDoc release];
	return XMLString;	
}

/* ================================================================================================
 * Helper method to create a keyframe element
 * ================================================================================================ */

- (NSXMLElement*)keyFrameElementWithTime:(CGFloat)time 
							translationX:(int)translationX
							translationY:(int)translationY
								  scaleX:(CGFloat)scaleX
								  scaleY:(CGFloat)scaleY
								rotation:(CGFloat)rotation 
								  easing:(int)easing
								   alpha:(CGFloat)alpha 
{
	NSString *easingFunction = nil;
	switch (easing) {
		case EasingFunctionIn:
			easingFunction = @"ease-in";
			break;
		case EasingFunctionOut:
			easingFunction = @"ease-out";
			break;
		case EasingFunctionInOut:			
			easingFunction = @"ease-in-out";
			break;
		case EasingFunctionLinear:
		default:
			easingFunction = @"linear";
			break;
	}
	NSXMLElement *kfElement = [NSXMLNode elementWithName:@"keyFrame" children:nil attributes:[NSArray arrayWithObjects:
																							  [NSXMLNode attributeWithName:@"keyTime" stringValue:[NSString stringWithFormat:@"%f", time]],
																							  [NSXMLNode attributeWithName:@"timingFunction" stringValue:easingFunction],
																							  nil]];
	NSNumber *scaleXNumber = [NSNumber numberWithFloat:scaleX];
	NSNumber *scaleYNumber = [NSNumber numberWithFloat:scaleY];
	
	if (isnan(scaleX) || isnan(scaleY)) {
		NSAlert *alert = [NSAlert alertWithMessageText:@"Interner Fehler"
										 defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Es ist ein interner Fehler aufgetreten (scaleX or scaleY is NaN). Bitte den Hersteller kontaktieren!"];
		[alert runModal];
	}
	NSXMLElement *transformElement = [NSXMLNode elementWithName:@"transform" children:nil attributes:[NSArray arrayWithObjects:
																									  [NSXMLNode attributeWithName:@"scaleX" stringValue:[scaleXNumber stringValue]],
																									  [NSXMLNode attributeWithName:@"scaleY" stringValue:[scaleYNumber stringValue]],
																									  [NSXMLNode attributeWithName:@"rotate" stringValue:[NSString stringWithFormat:@"%f", rotation]],
																									  [NSXMLNode attributeWithName:@"translateX" stringValue:[NSString stringWithFormat:@"%d", translationX]],																												  
																									  [NSXMLNode attributeWithName:@"translateY" stringValue:[NSString stringWithFormat:@"%d", translationY]],
																									  nil]];
	NSXMLElement *alphaElement = [NSXMLNode elementWithName:@"alpha" children:nil attributes:[NSArray arrayWithObjects:
																							  [NSXMLNode attributeWithName:@"value" stringValue:[NSString stringWithFormat:@"%f", alpha]],
																							  nil]];				
	[kfElement addChild:alphaElement];				
	[kfElement addChild:transformElement];				
	return kfElement;
}

/* ================================================================================================
 * Returns the triggerType attribute value for a given TransitionMO entity
 * ================================================================================================ */

- (NSString*)triggerForTransition:(TransitionMO*)transition {
	int trigger = [transition.trigger intValue];
	switch (trigger) {
		case kTransitionTriggerTypeTap:
			return @"tap";
		case kTransitionTriggerTypeWait:
			return @"wait";
		case kTransitionTriggerTypeAutomatic:
		default:
			return @"automatic";
	}
}

/* ================================================================================================
 * Object management
 * ================================================================================================ */

- (void) dealloc
{
	[xmlPanel release];
	[xmlTestBed release];
	[stageArrayController release];
	[scenesArrayController release];
	[contentView release];
	[panel release];
	[super dealloc];
}

@end
