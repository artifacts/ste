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

#import "STModelAccessViewController.h"

#import "Convenience_Macros.h"

@implementation STModelAccessViewController

@synthesize mainArrayControllerKeyPath = _mainArrayControllerKeyPath;
@synthesize mainArrayController = _mainArrayController;

- (id) init
{
	NSAssert(nil, @"STModelAccessViewController must be initialized with its own initializers which include mainArrayController");
	return nil;
}

- (id) initWithNibName: (NSString *) nibName bundle: (NSBundle *) bundle
{
	return [self init]; // just complain
}

- (id) initWithNibName: (NSString *) nibName bundle: (NSBundle *) bundle mainArrayControllerKeyPath: (NSString *) mainArrayControllerKeyPath
{
	if( ( self = [super initWithNibName: nibName bundle: bundle] ) ) {
		self.mainArrayControllerKeyPath = mainArrayControllerKeyPath;
	}
	return self;
}

+ (id) viewControllerReplacingPlaceholderView: (NSView *) placeholderView mainArrayControllerKeyPath: (NSString *) mainArrayControllerKeyPath
{
	STViewController *viewController = [[[self alloc] initWithMainArrayControllerKeyPath: mainArrayControllerKeyPath] autorelease];
	if( viewController ) {
		[viewController replacePlaceholderView: placeholderView];
	}
	return viewController;
}

- (id) initWithMainArrayControllerKeyPath: (NSString *) mainArrayControllerKeyPath
{
	return [self initWithNibName: [[self class] defaultNibName] bundle: nil mainArrayControllerKeyPath: mainArrayControllerKeyPath];
}

- (void) dealloc
{
	self.mainArrayController = nil;
	self.mainArrayControllerKeyPath = nil;
	[super dealloc];
}

- (void) setRepresentedObject: (id) representedObject
{
	id lastRepresentedObject = self.representedObject;
	
	if( lastRepresentedObject ) {
		NSArray *UTIs = [self.mainArrayController objectExchangeUTIsWithOptions: [self optionsForDragOperation: NSDragOperationCopy]];
		for(NSView *dragView in [self viewsForRegisteringObjectExchangeTypes: UTIs]) {
			//[dragView unregisterDraggedTypes];
		}
		self.mainArrayController = nil;
	}

	[super setRepresentedObject: representedObject];

	if( nil != representedObject ) {
		self.mainArrayController = [representedObject valueForKey: self.mainArrayControllerKeyPath];

		NSArray *UTIs = [self.mainArrayController objectExchangeUTIsWithOptions: [self optionsForDragOperation: NSDragOperationCopy]];

		for(NSView *dragView in [self viewsForRegisteringObjectExchangeTypes: UTIs]) {
			[dragView registerForDraggedTypes: UTIs];
			//NSLog(@"%@ registering %@ for %@", self, dragView, UTIs);
		}
	}
}

#pragma mark -
#pragma mark Copy and Paste support

- (NSSet *) viewsForRegisteringObjectExchangeTypes: (NSArray *) types
{
	return [NSSet setWithObject: self.view];
}

- (NSDictionary *) optionsForDragOperation: (NSDragOperation) operation
{
	return [NSDictionary dictionaryWithObject: [self.mainArrayController entityName] forKey: kObjectExchangeEntityName];
}

- (IBAction) delete: (id) sender
{
	[self.mainArrayController removeObjectsAtArrangedObjectIndexes: [self.mainArrayController selectionIndexes]];
}

- (IBAction) cut: (id) sender
{
	NSDictionary *options = [self optionsForDragOperation: NSDragOperationNone];
	if( NO == [self.mainArrayController writeSelectionToPasteboard: [NSPasteboard generalPasteboard] options: options] ) {
		PRESENT_NSERROR_REASON(NSApp, NSPOSIXErrorDomain, EINVAL, @"errorCutOperationFailed");
		NSLog(@"copy part of cut failed in %@", self);
	} else {
		[self.mainArrayController removeObjectsAtArrangedObjectIndexes: [self.mainArrayController selectionIndexes]];
	}
}

- (void) copyWithOptions: (NSDictionary *) options
{
	if( NO == [self.mainArrayController writeSelectionToPasteboard: [NSPasteboard generalPasteboard] options: options] ) {
		PRESENT_NSERROR_REASON(NSApp, NSPOSIXErrorDomain, EINVAL, @"errorCopyOperationFailed");
		NSLog(@"copy failed in %@", self);
	}
}

- (IBAction) copy: (id) sender
{
	[self copyWithOptions: [self optionsForDragOperation: NSDragOperationNone]];
}

- (IBAction) paste: (id) sender
{
	NSDictionary *options = [self optionsForDragOperation: NSDragOperationCopy];
	NSError *error = nil;
	if( NO == [self.mainArrayController insertFromPasteboard: [NSPasteboard generalPasteboard] options: options error: &error] ) {
		[NSApp presentError: error];
	}
}

- (IBAction) duplicate: (id) sender
{
	[self copy: sender];
	[self paste: sender];
}

@end
