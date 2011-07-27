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

#import "NSMPreferencesWindowController.h"


@interface NSMPreferencesWindowController (Private)
- (void)_initDefaults;
- (void)_applySettings;
- (void)_resizeWindowToSize:(NSSize)size animate:(BOOL)bFlag;
- (void)_saveWindowOrigin;
- (void)_restoreWindowOrigin;
- (NSArray *)_toolbarIdentifiers;
- (NSToolbarItem *)_toolbarItemForIdentifier:(NSString *)ident;
- (NSViewController *)_viewControllerForIdentifier:(NSString *)ident;
- (void)_setViewControllerVisible:(NSViewController *)controller;
- (void)_setupToolbar;
@end


@implementation NSMPreferencesWindowController

@synthesize toolbarIdentifier=m_toolbarIdentifier, 
			toolbarAllowsUserCustomization=m_toolbarAllowsUserCustomization, 
			toolbarAutosavesConfiguration=m_toolbarAutosavesConfiguration, 
			toolbarSizeMode=m_toolbarSizeMode, 
			toolbarDisplayMode=m_toolbarDisplayMode, 
			windowAutosaveName=m_windowAutosaveName;

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithWindow:(NSWindow *)window{
	if (self = [super initWithWindow:window]){
		[window setDelegate:self];
		[self _initDefaults];
	}
	return self;
}

- (id)initWithWindowNibName:(NSString *)windowNibName{
	if (self = [super initWithWindowNibName:windowNibName])
		[self _initDefaults];
	return self;
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner{
	if (self = [super initWithWindowNibName:windowNibName owner:owner])
		[self _initDefaults];
	return self;
}

- (id)initWithWindowNibPath:(NSString *)windowNibPath owner:(id)owner{
	if (self = [super initWithWindowNibPath:windowNibPath owner:owner])
		[self _initDefaults];
	return self;
}

- (void)dealloc{
	[m_toolbarItems release];
	[m_toolbarIdentifier release];
	[m_windowAutosaveName release];
	[super dealloc];
}



#pragma mark -
#pragma mark Public methods

- (void)addPrefPaneWithController:(NSViewController *)controller icon:(NSImage *)icon{
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:[controller title]];
	[toolbarItem setLabel:[controller title]];
	[toolbarItem setPaletteLabel:[controller title]];
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector(toolbarItem_clicked:)];
	[toolbarItem setTag:[m_toolbarItems count]];
	[toolbarItem setAutovalidates:YES];
	[toolbarItem setImage:icon];
	
	[m_toolbarItems addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
		toolbarItem, @"ToolbarItem", 
		controller, @"Controller", nil]];
	
	[toolbarItem release];
}

- (void)setToolbarAllowsUserCustomization:(BOOL)bFlag{
	m_toolbarAllowsUserCustomization = bFlag;
	[self _applySettings];
}

- (void)setToolbarAutosavesConfiguration:(BOOL)bFlag{
	m_toolbarAutosavesConfiguration = bFlag;
	[self _applySettings];
}

- (void)setToolbarSizeMode:(NSToolbarSizeMode)mode{
	m_toolbarSizeMode = mode;
	[self _applySettings];
}

- (void)setToolbarDisplayMode:(NSToolbarDisplayMode)mode{
	m_toolbarDisplayMode = mode;
	[self _applySettings];
}



#pragma mark -
#pragma mark Overridden NSWindowController methods

- (IBAction)showWindow:(id)sender{
	if ([[self window] toolbar] == nil && [m_toolbarItems count] > 0){
		[self _setupToolbar];
		[self _setViewControllerVisible:[[m_toolbarItems objectAtIndex:0] 
			objectForKey:@"Controller"]];
	}
	[super showWindow:sender];
}

- (BOOL)windowShouldClose:(id)window{
	[self _saveWindowOrigin];
	return YES;
}




#pragma mark -
#pragma mark Private methods

- (void)_initDefaults{
	m_toolbarItems = [[NSMutableArray alloc] init];
	m_activeController = nil;
	m_toolbarIdentifier = [@"MainToolbar" retain];
	m_toolbarAllowsUserCustomization = NO;
	m_toolbarAutosavesConfiguration = YES;
	m_toolbarSizeMode = NSToolbarSizeModeDefault;
	m_toolbarDisplayMode = NSToolbarDisplayModeDefault;
	m_windowAutosaveName = [@"PreferencesWindowOrigin" retain];
}

- (void)_applySettings{
	NSToolbar *toolbar;
	if (toolbar = [[self window] toolbar]){
		 [toolbar setAllowsUserCustomization:m_toolbarAllowsUserCustomization];
		 [toolbar setAutosavesConfiguration:m_toolbarAutosavesConfiguration];
		 [toolbar setSizeMode:m_toolbarSizeMode];
		 [toolbar setDisplayMode:m_toolbarDisplayMode];
	}
}

- (void)_resizeWindowToSize:(NSSize)size animate:(BOOL)bFlag{
	NSRect windowFrame = [[self window] frame];
	int toolbarHeight = NSHeight(windowFrame) - NSHeight([[[self window] contentView] frame]);
	int neededWindowSize = size.height + toolbarHeight;
	int sizeOffset = NSHeight([[self window] frame]) - neededWindowSize;
	windowFrame.origin.y += sizeOffset;
	windowFrame.size.height = neededWindowSize;
	windowFrame.size.width = size.width == -1 ? windowFrame.size.width : size.width;
	[[self window] setFrame:windowFrame display:YES animate:bFlag];
}

- (void)_saveWindowOrigin{
	NSPoint windowOrigin = [[self window] frame].origin;
	NSSize windowSize = [[self window] frame].size;
	windowOrigin.y += windowSize.height;
	[[[NSUserDefaultsController sharedUserDefaultsController] values] 
		setValue:NSStringFromPoint(windowOrigin) 
		forKey:m_windowAutosaveName];
}

- (void)_restoreWindowOrigin{
	NSString *originString = [[[NSUserDefaultsController sharedUserDefaultsController] values] 
		valueForKey:m_windowAutosaveName];
	if (originString == nil){
		[[self window] center];
		return;
	}
	NSPoint origin = NSPointFromString(originString);
	NSSize windowSize = [[self window] frame].size;
	origin.y -= windowSize.height;
	[[self window] setFrameOrigin:origin];
}

- (NSArray *)_toolbarIdentifiers{
	NSMutableArray *identifiers = [NSMutableArray array];
	for (NSDictionary *dict in m_toolbarItems)
		[identifiers addObject:[(NSViewController *)[dict objectForKey:@"Controller"] title]];
	return identifiers;
}

- (NSToolbarItem *)_toolbarItemForIdentifier:(NSString *)ident{
	for (NSDictionary *dict in m_toolbarItems)
		if ([[(NSViewController *)[dict objectForKey:@"Controller"] title] isEqualToString:ident])
			return [dict objectForKey:@"ToolbarItem"];
	return nil;
}

- (NSViewController *)_viewControllerForIdentifier:(NSString *)ident{
	for (NSDictionary *dict in m_toolbarItems){
		NSViewController *controller = [dict objectForKey:@"Controller"];
		if ([[controller title] isEqualToString:ident])
			return controller;
	}
	return nil;
}

- (void)_setViewControllerVisible:(NSViewController *)controller{
	BOOL animate = NO;
	if (m_activeController != nil){
		[[m_activeController view] removeFromSuperview];
		if ([m_activeController respondsToSelector:@selector(prefPaneDidMoveToWindow)])
			[m_activeController prefPaneDidMoveToWindow];
		animate = YES;
	}
	m_activeController = controller;
	[self _resizeWindowToSize:[[controller view] bounds].size animate:animate];
	if ([m_activeController respondsToSelector:@selector(prefPaneWillMoveToWindow)])
		[m_activeController prefPaneWillMoveToWindow];
	[[[self window] contentView] addSubview:[controller view]];
	if ([m_activeController respondsToSelector:@selector(prefPaneDidMoveToWindow)])
		[m_activeController prefPaneDidMoveToWindow];
	if (!animate)
		[self _restoreWindowOrigin];
	[[[self window] toolbar] setSelectedItemIdentifier:[controller title]];
}

- (void)_setupToolbar{
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:m_toolbarIdentifier];
	[toolbar setDelegate:self];
	[[self window] setToolbar:toolbar];
	[toolbar release];
	[self _applySettings];
}



#pragma mark -
#pragma mark NSToolbarItem action method

- (void)toolbarItem_clicked:(NSToolbarItem *)sender{
	[self _setViewControllerVisible:[self _viewControllerForIdentifier:[[[self window] toolbar] 
		selectedItemIdentifier]]];
}



#pragma mark -
#pragma mark NSToolbar delegate methods

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
    itemForItemIdentifier:(NSString *)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag{
	return [self _toolbarItemForIdentifier:itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar{
    return [self _toolbarIdentifiers];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar{
    return [self _toolbarIdentifiers];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar{
    return [self _toolbarIdentifiers];
}
@end
