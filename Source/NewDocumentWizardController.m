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

#import "NewDocumentWizardController.h"
#import "StoryTellingEditorAppDelegate.h"

enum TableRows {
	TableRowNewDocument = 0,
};

@implementation NewDocumentWizardController

@synthesize versionLabel=_versionLabel;
@synthesize table=_table;
@synthesize tableRecentDocuments=_tableRecentDocuments;
@synthesize lastRecentlyUsedDocuments=_lastRecentlyUsedDocuments;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	if (aTableView == _tableRecentDocuments) {
		return [_lastRecentlyUsedDocuments count];
	}
	return 1;
}

- (void)awakeFromNib {
	[_table setRowHeight:45];
	[_table setDoubleAction:@selector(didSelectRowInOptionsTable:)];
	[_tableRecentDocuments setDoubleAction:@selector(didSelectRowInLRUTable:)];
	[_table setTarget:self];	
	[_tableRecentDocuments setTarget:self];	
	NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	[_versionLabel setStringValue:[NSString stringWithFormat:@"%@", version]];
}

- (id)initWithWindowNibName:(NSString *)windowNibName {
	self = [super initWithWindowNibName:windowNibName];
	
	if (self != nil) {
		_lastRecentlyUsedDocuments = [[NSMutableArray alloc] init];
		id dc = [NSDocumentController sharedDocumentController];
		NSString *path = nil;
	
		if ([[dc recentDocumentURLs] count] > 0) {
			for (NSURL *url in [dc recentDocumentURLs]) {
				path = [url path]; //[[[dc recentDocumentURLs] objectAtIndex:0] path];
				if ([[NSFileManager defaultManager] fileExistsAtPath:path] &&
					[[path stringByDeletingPathExtension] hasSuffix:@"~"] == NO) {
					[_lastRecentlyUsedDocuments addObject:path];
				}
			}
		}
	}
	
	return self;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if (aTableView == _tableRecentDocuments) {
		return [_lastRecentlyUsedDocuments objectAtIndex:rowIndex];		
	} else {
		switch (rowIndex) {
			case TableRowNewDocument:
				if ([@"image" isEqualToString:[aTableColumn identifier]]) {
					NSImage *newDocumentIcon = [NSImage imageNamed:@"documentWizardNewDocument"];
					return newDocumentIcon;
				} else {
					return @"Neues Dokument erstellen";					
				}		
			default:
				return nil;
		}							
	}
	return nil;
}

- (IBAction)didSelectRowInOptionsTable:(id)sender {
//	NSInteger row = [_tableRecentDocuments clickedRow];
	StoryTellingEditorAppDelegate *appDelegate = [NSApp delegate];
	[appDelegate.documentController newDocument:self];
	[self fadeOut];
}

- (IBAction)didSelectRowInLRUTable:(id)sender {
	NSInteger row = [_tableRecentDocuments clickedRow];
	NSString *path = [_lastRecentlyUsedDocuments objectAtIndex:row];		
	StoryTellingEditorAppDelegate *appDelegate = [NSApp delegate];
	NSURL *url = [NSURL fileURLWithPath:path];
	NSError *error = nil;
	[appDelegate.documentController openDocumentWithContentsOfURL:url display:YES error:&error];
	[self fadeOut];
}

- (void)fadeOut {
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.window , NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect,NSViewAnimationEffectKey,nil];	
	NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:dict]];	
	[animation startAnimation];
	[animation release];
	[self.window performSelector:@selector(close) withObject:nil afterDelay:0.5];
}

- (void) dealloc
{
	[_lastRecentlyUsedDocuments release];
	[_table release];
	[_tableRecentDocuments release];
	[_versionLabel release];
	[super dealloc];
}

@end
