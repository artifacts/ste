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

#import "PreviewController+Physics.h"
#import "Constants.h"
#import <EngineRoom/EngineRoom.h>
#import <EngineRoom/CrossPlatform_Utilities.h>

@implementation PreviewController (Physics)

- (NSString*)renderSceneAsPhysicsXML:(SceneMO*)scene baseURL:(NSString*)baseURL preview:(BOOL)previewMode {

	CGRect originAssetBounds = CGRectZero;
	NSError *error = nil;
//	NSString *XSDPath = [[NSBundle mainBundle] pathForResource:@"story-telling.xsd" ofType:nil];
//	NSURL *XSDURL = [NSURL fileURLWithPath:XSDPath];
	CGPoint stagePosition = CGPointZero;
	stagePosition.x = 0;
	stagePosition.y = 0;
	StageMO *stage = scene.scenario.stage;
	
	NSXMLElement *rootElement = [NSXMLNode elementWithName:@"stage" children:nil attributes:[NSArray arrayWithObjects:
																							 [NSXMLNode attributeWithName:@"xmlns" stringValue:kXMLNamespacePhysics],
																							 //[NSXMLNode attributeWithName:@"xmlns:xsi" stringValue:@"http://www.w3.org/2001/XMLSchema-instance"],																							
																							 //[NSXMLNode attributeWithName:@"xsi:schemaLocation" stringValue:[NSString stringWithFormat:@"%@ %@", kXMLNamespace, [XSDURL absoluteString]]],
																							 //[NSXMLNode attributeWithName:@"xsi:noNamespaceSchemaLocation" stringValue:[XSDURL absoluteString]],
																							 //[NSXMLNode attributeWithName:@"id" stringValue:@"stage"],
																							 //[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%d", (int)stagePosition.x]],
																							 //[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%d", (int)stagePosition.y]],
																							 [NSXMLNode attributeWithName:@"width" stringValue:[stage.width stringValue]],
																							 [NSXMLNode attributeWithName:@"height" stringValue:[stage.height stringValue]],
																							 [NSXMLNode attributeWithName:@"gravity" stringValue:[stage.gravity stringValue]],
																							 nil]];
	
	if ([baseURL length]>0) {
		[rootElement addAttribute:[NSXMLNode attributeWithName:@"baseURL" stringValue:baseURL]];
	}
	
		
	CGPoint originAssetPosition = CGPointZero;
	BOOL physicsEnabled = NO;
	CGFloat mass = 0;
	CGFloat friction = 0;
	CGFloat rotation = 0;
	BOOL staticBody = NO;
	CGFloat shapeOffset = -0.1;
	
	NSString *assetID = nil;
	NSSortDescriptor *viewPositionSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"viewPosition" ascending:NO];
	NSArray *sortDescriptors = [NSArray arrayWithObject:viewPositionSortDescriptor];
	NSArray *assets = [[scene.assets allObjects] sortedArrayUsingDescriptors:sortDescriptors];	
	for (AssetMO *asset in assets) {			
		if ([asset.hidden boolValue] == YES) continue;
		NSArray *orderedKeyframes = asset.keyframeAnimation.orderedKeyframes;
			
		assetID = [self xmlIDForManagedObject:asset];
			
		for (KeyframeMO *kf in orderedKeyframes) {
			originAssetPosition = [[kf valueForKey: @"position"] CGPointValue];
			NSImage *img = [[NSImage alloc] initWithData:[[asset primaryBlob] cachedData]];
			originAssetBounds = [[kf valueForKey: @"bounds"] CGRectValue]; //NSSizeToCGSize([img size]);
			
			[img release];
			
			physicsEnabled = [[kf valueForKey: @"physicsEnabled"] boolValue];
			mass = [[kf valueForKey: @"mass"] floatValue];
			friction = [[kf valueForKey: @"friction"] floatValue];
			id shapeOffsetValue = [kf valueForKey: @"shapeOffset"];
			if (shapeOffsetValue == nil) {
				shapeOffset = -0.1;
			} else {
				shapeOffset = [shapeOffsetValue floatValue];
			}
			staticBody = [[kf valueForKey: @"staticBody"] boolValue];
			rotation = [[kf valueForKey: @"rotation"] floatValue];
			break;
		}
		if (physicsEnabled == NO) continue;
					
		// HACK ***
		if (previewMode == YES) {
			originAssetPosition.y += originAssetBounds.size.height;
		}
		// *****
		
		MediaContainer *mediaContainer = asset.primaryBlob.mediaContainer;
		
		// take rendered urls from mediacontainer for preview (we want to read the compressed images from the cache)
		// for export, take orginal image urls, to do not break the mapping between the ImportExport xml and the BIPStageXML
		// this is more or less a workaroung, TODO: better concept for image urls in XML Export and get rid of the two xmls
		// evaluate if the preview xml rendering part would better be done in XSLT...
				
		NSURL *renderedURL = (previewMode==YES)?mediaContainer.renderedURL:[NSURL URLWithString:[asset primaryBlob].externalURL];
		NSString *renderedURLString = [renderedURL absoluteString]; 
		
		NSXMLElement *spriteElement = [NSXMLNode elementWithName:@"sprite" children:nil attributes:[NSArray arrayWithObjects:
																									//[NSXMLNode attributeWithName:@"id"			stringValue:assetID],																									  
																									//[NSXMLNode attributeWithName:@"z"			stringValue:[asset.viewPosition stringValue]],
																									[NSXMLNode attributeWithName:@"x"			stringValue:[NSString stringWithFormat:@"%d", (int)originAssetPosition.x]],
																									[NSXMLNode attributeWithName:@"y"			stringValue:[NSString stringWithFormat:@"%d", (int)originAssetPosition.y]],
																									[NSXMLNode attributeWithName:@"width"		stringValue:[NSString stringWithFormat:@"%d", (int)originAssetBounds.size.width]],
																									[NSXMLNode attributeWithName:@"height"		stringValue:[NSString stringWithFormat:@"%d", (int)originAssetBounds.size.height]],
																									[NSXMLNode attributeWithName:@"rotation"	stringValue:[NSString stringWithFormat:@"%f", rotation]],
																									[NSXMLNode attributeWithName:@"mass"		stringValue:[NSString stringWithFormat:@"%f", mass]],
																									[NSXMLNode attributeWithName:@"friction"	stringValue:[NSString stringWithFormat:@"%f", friction]],
																									[NSXMLNode attributeWithName:@"shapeOffset" stringValue:[NSString stringWithFormat:@"%f", shapeOffset]],
																									[NSXMLNode attributeWithName:@"static"		stringValue:[NSString stringWithFormat:@"%@", (staticBody==YES)?@"true":@"false"]],
																									[NSXMLNode attributeWithName:@"imageURL"	stringValue: renderedURLString],
																									nil]];
		[rootElement addChild:spriteElement];
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

@end
