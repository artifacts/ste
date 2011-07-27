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

// Manages a preferences window, handling the toolbar and shows and hides the according views.
// The toolbar is created upon the first showWindow: message, thus there is enough time to 
// set it up via the addPrefPane ... methods
@interface NSMPreferencesWindowController : NSWindowController <NSWindowDelegate, NSToolbarDelegate>{
	NSMutableArray *m_toolbarItems;
	NSViewController *m_activeController;
	NSString *m_toolbarIdentifier;
	BOOL m_toolbarAllowsUserCustomization;
	BOOL m_toolbarAutosavesConfiguration;
	NSToolbarSizeMode m_toolbarSizeMode;
	NSToolbarDisplayMode m_toolbarDisplayMode;
	NSString *m_windowAutosaveName;
}
// The identifier is used as the autosave name for toolbars that save their configuration, 
// Defaults to MainToolbar. Must be set before the toolbar is created!
@property (nonatomic, retain) NSString *toolbarIdentifier;
// Defaults to NO
@property (nonatomic, assign) BOOL toolbarAllowsUserCustomization;
// When autosaving is enabled, the receiver will automatically write the toolbar settings to user 
// Defaults if the toolbar configuration changes. defaults to YES
@property (nonatomic, assign) BOOL toolbarAutosavesConfiguration;
// Defaults to NSToolbarSizeModeDefault
@property (nonatomic, assign) NSToolbarSizeMode toolbarSizeMode;
// Defaults to NSToolbarDisplayModeDefault
@property (nonatomic, assign) NSToolbarDisplayMode toolbarDisplayMode;
// Used in UserPreferences, defaults to PreferencesWindowOrigin
@property (nonatomic, retain) NSString *windowAutosaveName;

// Adds a view and the respecting ToolbarItem, uses the ViewControllers title property for display 
// and identifying purposes
- (void)addPrefPaneWithController:(NSViewController *)controller icon:(NSImage *)icon;
@end


@interface NSObject (NSMPreferencesViewController)
- (void)prefPaneWillMoveToWindow;
- (void)prefPaneDidMoveToWindow;
@end
