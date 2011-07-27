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

#import "OpenDocumentsPanelViewController.h"
#import "StoryTellingEditorAppDelegate.h"

@implementation OpenDocumentsPanelViewController

@synthesize tableView=_tableView;
@synthesize documentController=_documentController;
@synthesize openDocumentsArrayController=_openDocumentsArrayController;

#pragma mark -
#pragma mark Initialization & Deallocation

#define kOpenDocumentTableViewDataType @"OpenDocumentTableViewDataType"

- (id)init{
	if (self = [super initWithNibName:@"OpenDocumentsPanel" bundle:nil]){
		_documentController = [(StoryTellingEditorAppDelegate*)[[NSApplication sharedApplication] delegate] documentController];		
	}
	return self;
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:kOpenDocumentTableViewDataType] owner:self];
    [pboard setData:data forType:kOpenDocumentTableViewDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{	
	NSLog(@"row: %d", row);
	// don't accept any other table
	if (aTableView != self.tableView) return NSDragOperationNone;
	// only accept drops on existing table rows
	if (row < 0 || row >= [self.tableView numberOfRows]) return NSDragOperationNone;

	NSDocument *targetDocument = [[self.openDocumentsArrayController arrangedObjects] objectAtIndex:row];
	NSLog(@"target: %@", [targetDocument displayName]);
	if (targetDocument == nil) return NSDragOperationNone;
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:kOpenDocumentTableViewDataType];
    NSIndexSet* dragRowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSIndexSet* targetRowIndexes = [NSIndexSet indexSetWithIndex: row];

	NSArray *documents = [self.openDocumentsArrayController arrangedObjects];
	NSInteger documentCount = [documents count];

	if( 0 == documentCount || NSNotFound == row || row > documentCount - 1|| 0 == [dragRowIndexes count] || [dragRowIndexes lastIndex] > documentCount -1 ) {
		lpkerrorf("preconditionFail, documentAction", "documentCount: %ld targetRow: %ld dragRowIndexes: %@ documents: %@",
			(long)documentCount, (long) row, dragRowIndexes, documents);
		return NO;
	}
	

	NSArray *sourceDocuments = [documents objectsAtIndexes: dragRowIndexes];	
	NSArray *targetDocuments = [documents objectsAtIndexes: targetRowIndexes];

	if( 0 == [sourceDocuments count] || 0 == [targetDocuments count] ) {
		lpkerrorf("postConditionFail, documentAction", "sources: %@ %@ targets: %@ %@",
			[sourceDocuments valueForKey: @"displayName"], sourceDocuments,
			[targetDocuments valueForKey: @"displayName"], targetDocuments);
		return NO;
	}
	
	MergeDocumentsWizardController *mergeDocumentsWizardController = [[MergeDocumentsWizardController alloc] initWithWindowNibName:@"MergeDocumentsWizard"];

	mergeDocumentsWizardController.sourceDocuments = sourceDocuments;
	mergeDocumentsWizardController.targetDocuments = targetDocuments;

	// change presentation here when support for multiple target documents is required
	[NSApp beginSheet: mergeDocumentsWizardController.window modalForWindow: [[targetDocuments lastObject] windowForSheet] modalDelegate: self didEndSelector: nil contextInfo: nil];
	[NSApp runModalForWindow: mergeDocumentsWizardController.window];	
	
    [NSApp endSheet: mergeDocumentsWizardController.window];
    [mergeDocumentsWizardController.window orderOut: self];

	[mergeDocumentsWizardController release];

	return YES;
}

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
    int row;
    row = [self.tableView selectedRow];
		
    if (row == -1) {
        // no row selected
	} else {
		NSDocument *selectedDocument = [[_openDocumentsArrayController arrangedObjects] objectAtIndex:row];
		[selectedDocument showWindows];
	}	
} 


- (void)awakeFromNib
{
	[self.tableView setDraggingSourceOperationMask:NSDragOperationMove
									 forLocal:YES];
    [self.tableView registerForDraggedTypes:
	 [NSArray arrayWithObject:kOpenDocumentTableViewDataType] ];
}

- (void) dealloc
{
	[_openDocumentsArrayController release];
	[_tableView release];
	[super dealloc];
}

@end
