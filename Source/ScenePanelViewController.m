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

#import "ScenePanelViewController.h"
#import "MyDocument.h"
#import "TransitionMO.h"
#import "Pair.h"
#import "FloatTransformer.h"

@interface ScenePanelViewController ()
- (void)_updateSelectedScene;
- (void)_updateSettingsView;
- (MyDocument*)currentDocument;
@end


@implementation ScenePanelViewController

@synthesize selectedScene=_selectedScene;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)init{
	if (self = [super initWithNibName:@"ScenePropertiesPanel" bundle:nil]){

	}
	return self;
}

- (void)awakeFromNib{
	_currentSettingsView = nil;
	_selectedScene = nil;
	[self _updateSelectedScene];
	[[self currentDocument].sceneArrayController addObserver:self forKeyPath:@"selection" options:0 
											   context:NULL];
}

- (void)dealloc{
	[[self currentDocument].sceneArrayController removeObserver:self forKeyPath:@"selection"];
	[_selectedScene removeObserver:self forKeyPath:@"transitionToNext.transitionType"];
	[_selectedScene release];
	_selectedScene = nil;
	[super dealloc];
}

- (MyDocument*)currentDocument {
	return [[NSApp delegate] currentDocument];
}

#pragma mark -
#pragma mark Public methods

- (void)setSelectedScene:(SceneMO *)aScene{
	[_selectedScene removeObserver:self forKeyPath:@"transitionToNext.transitionType"];
	[aScene retain];
	[_selectedScene release];
	_selectedScene = aScene;
	[self _updateSettingsView];
	[_selectedScene addObserver:self forKeyPath:@"transitionToNext.transitionType" 
						options:0 context:NULL];
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
					   context:(void *)context{
	if ([keyPath isEqualToString:@"selection"]){
		[self _updateSelectedScene];
	}else{
		[self _updateSettingsView];
	}
}



#pragma mark -
#pragma mark Private methods

- (void)_updateSelectedScene{
	NSArrayController *sceneArrayController = [[self currentDocument] sceneArrayController];
	NSString *title = nil;
	
	if ([[sceneArrayController selectionIndexes] count] != 1){
		self.selectedScene = nil;
	}else{
		self.selectedScene = [[sceneArrayController selectedObjects] objectAtIndex:0];
		title = [self.selectedScene.name stringByAppendingString:@" (Szene)"];
	}
	[self setTitle:title];
}

- (void)_updateSettingsView{
	NSView *newView = nil;
	TransitionMO *transition = [_selectedScene valueForKey:@"transitionToNext"];
	int type = [transition.transitionType intValue];
	switch (type){
		case kTransitionTypeFade:
			newView = _fadeSettingsView;
			break;
		case kTransitionTypeFadeThroughColor:
			newView = _fadeThroughColorSettingsView;
			break;
	}
	[_currentSettingsView removeFromSuperview];
	NSRect frame = (newView!=nil)?[newView frame]:NSZeroRect;
	frame.origin.x = 255.0f;
	[newView setFrame:frame];
	[[self view] addSubview:newView];
	_currentSettingsView = newView;
}

- (NSArray*)loopPopupButtonContent {
	NSArray *content = [NSArray arrayWithObjects:
						[[[Pair alloc] initWithName:@"Keine Wiederholung" value: [NSNumber numberWithInt:LoopNone]] autorelease],
						[[[Pair alloc] initWithName:@"Endlos" value: [NSNumber numberWithInt:LoopEndless]] autorelease],
						[[[Pair alloc] initWithName:@"PingPong" value: [NSNumber numberWithInt:LoopPingPong]] autorelease],
						nil];
	return content;
}

@end
