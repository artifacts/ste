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

#import "PanelWindowController.h"

enum{
	kDocumentObservingContext, 
};


@implementation PanelWindowController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super initWithWindowNibName:@"PanelWindow"]){
		_currentDocument = nil;
	}
	return self;
}

- (void)dealloc{
	[_dimensionsPanel release];
//	[_physicsPanel release];
	[_openDocumentsPanel release];
	[_scenePanel release];
	[[NSApp delegate] removeObserver:self forKeyPath:@"currentDocument"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

- (void)awakeFromNib{
	[[NSApp delegate] addObserver:self forKeyPath:@"currentDocument" 
						  options:0 context:(void *)kDocumentObservingContext];
	[self _updateCurrentDocument];
}


#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
					   context:(void *)context{
	if ((NSInteger)context == kDocumentObservingContext){
		[self _updateCurrentDocument];
	}
}



#pragma mark -
#pragma mark Private methods

- (void)_updateCurrentDocument{	
	_currentDocument = [[NSApp delegate] currentDocument];
}

#pragma mark -
#pragma mark NSWindowController methods

- (void)windowDidLoad{
	_openDocumentsPanel = [[OpenDocumentsPanelViewController alloc] init];
//	_physicsPanel = [[PhysicsPanelViewController alloc] init];
	_scenePanel = [[ScenePanelViewController alloc] init];
	_dimensionsPanel = [[AssetDimensionsPanelViewController alloc] initWithDocument:[[NSApp delegate] valueForKey: @"currentDocument"]];
	
	[_outlineView addView:[_openDocumentsPanel view] withImage:nil label:@"Geöffnete Dokumente" expanded:NO];
	[_outlineView addView:[_dimensionsPanel view] withImage:nil label:@"Eigenschaften" expanded:YES];
	//[_outlineView addView:[_physicsPanel view] withImage:nil label:@"Physik" expanded:NO];
	[_outlineView addView:[_scenePanel view] withImage:nil label:@"Aktuelle Szene" expanded:NO];
}

#pragma mark -
#pragma mark NSWindow Delegate Methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	NSUndoManager *undoManager = [[[NSApp delegate] valueForKey: @"currentDocument"] undoManager];
	return undoManager;
}


@end
