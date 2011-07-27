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

#import "StoryTellingEditorAppDelegate.h"
#import "PluginLoader.h"
#import "MyDocument.h"
#import "Constants.h"

#import <EngineRoom/ERValueTransformer.h>

#define kMaxCacheableItemFileSize kAFCacheInfiniteFileSize

#define kSTEImagesAppSupportFolderName @"Images"
#define kSTEImportAppSupportFolderName @"Import"

@interface StoryTellingEditorAppDelegate ()
- (void)_updateCurrentDocument;
@end

@implementation StoryTellingEditorAppDelegate

@synthesize window = _window;
@synthesize assetEditorController = _assetEditorController;
@synthesize currentDocument=_currentDocument;
@synthesize splashScreen=_splashScreen;
@synthesize splashScreenVersionLabel=_splashScreenVersionLabel;
@synthesize documentController=_documentController;
@synthesize newDocumentWizardController=_newDocumentWizardController;

+ (void)initialize{
	
	if( [self class] != [StoryTellingEditorAppDelegate class] ) {
		return;
	}
	
	NSString *defaultPreferenceSettingsPath;
	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
	if (defaultPreferenceSettingsPath = [thisBundle pathForResource:@"DefaultPreferenceSettings" ofType:@"plist"])  {
		NSDictionary *defaultPreferenceSettings = [NSDictionary dictionaryWithContentsOfFile:defaultPreferenceSettingsPath];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPreferenceSettings];
	}		

	// this is cleanup code due to a name change - do NOT use kSTEStageSizePresetsPreference here 
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"STEStageSizePresetsPreference"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"STETimeScrubberShowsTimePreference"];

	NSError *error = nil;
	if( NO == [ERValueTransformer registerTransformersFromBundles: nil error: &error] ) {
		[NSApp presentError: error];
	}
	
	lpkdebug("valueTransformerTest", [NSValueTransformer valueTransformerNames]);
}

+ (NSSet *) keyPathsForValuesAffectingAssetEditor
{
	return [NSSet setWithObject: @"assetEditorController.selection"];
}

- (AssetEditor *) assetEditor
{
	return [self.assetEditorController.selection valueForKey: @"self"];
}

- (NSString *) pathForApplicationSupportSubFolder: (NSString *) subFolder createIfNeeded: (BOOL) createIfNeeded
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory , NSUserDomainMask, YES);
	if( 0 == [paths count] ) {
		return nil;
	}
	
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey: (id)kCFBundleNameKey];
	
	NSString *appSupport = [[paths objectAtIndex: 0] stringByAppendingPathComponent: appName];

	NSString *fullPath = [subFolder length] ? [appSupport stringByAppendingPathComponent: subFolder] : appSupport;

	NSFileManager *fileManager = [NSFileManager defaultManager];

	BOOL exists = [fileManager fileExistsAtPath: fullPath];
	
	if( NO == exists && YES == createIfNeeded ) {

		NSError *error = nil;
		if( NO == [fileManager createDirectoryAtPath: fullPath withIntermediateDirectories: YES attributes: nil error: &error] ) {
			[NSApp presentError: error];
		} else {
			exists = YES;
		}
	}
	
	return exists ? fullPath : nil;
}

- (BOOL) checkExecutionEnvironment
{
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	
	NSString *currentAppName = [bundlePath lastPathComponent];
	
	NSString *currentAppPath = [bundlePath stringByDeletingLastPathComponent];

	if( [currentAppName isEqualToString: @"StoryTellingEditor.app"] && 
	   ( [currentAppPath isEqualToString: @"/Applications"] || [currentAppPath hasSuffix: @"/Debug"]) ) {
		return YES;
	}	
	
	NSInteger button = NSRunCriticalAlertPanel(@"Warnung", @"StoryTellingEditor muss im Verzeichnis /Programme bzw. /Applications installiert sein und mit 'StoryTellingEditor.app' benannt sein damit alle Funktionen zur Verfuegung stehen.\n\nAnwendungsname: %@\nSpeicherort: %@", @"Abbrechen", @"Trotzdem", nil, currentAppName, currentAppPath);
	
	return NSAlertDefaultReturn == button ? NO : YES;
}

- (void) mailto: (NSString *) recipients subject: (NSString *) subject body: (NSString *) body 
{
	NSBundle *mainBundle = [NSBundle mainBundle];

	if( nil == recipients ) {
		recipients = [[NSUserDefaults standardUserDefaults] valueForKey: kSTEDeveloperMailAddress];

		lpdebug(recipients, subject, body);
				
		if( 0 == [recipients length] ) {
			return;
		}	

		subject = [NSString stringWithFormat: @"%@ %@ needs to call mum: %@", 
							 [mainBundle objectForInfoDictionaryKey: (id)kCFBundleNameKey],
							 [mainBundle objectForInfoDictionaryKey: (id)kCFBundleVersionKey],
								subject];
	}
	

	NSURL *mailtoURL = [NSURL URLWithString: [NSString stringWithFormat: @"mailto:%@?subject=%@&body=%@", 
											  recipients,
											  [subject stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], 
											  [body stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
											  ]];

	lpinfo(mailtoURL);
	[[NSWorkspace sharedWorkspace] openURLs: [NSArray arrayWithObject: mailtoURL] 
									withAppBundleIdentifier: @"com.apple.finder"
									options: NSWorkspaceLaunchDefault|NSWorkspaceLaunchWithoutActivation|NSWorkspaceLaunchWithoutAddingToRecents 
									additionalEventParamDescriptor: nil 
									launchIdentifiers: nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{

	if( NO == [self checkExecutionEnvironment] ) {	
		[NSApp terminate: self];
	}
	
	[[AFCache sharedInstance] setMaxItemFileSize:kMaxCacheableItemFileSize];
	// create necessary import folders
	[self pathForApplicationSupportSubFolder: nil createIfNeeded: YES];
	[self pathForApplicationSupportSubFolder: kSTEImagesAppSupportFolderName createIfNeeded: YES];
	[self pathForApplicationSupportSubFolder: kSTEImportAppSupportFolderName createIfNeeded: YES];

	// create panels
	_panelWindowController = [[PanelWindowController alloc] init];
	[_panelWindowController window];

	// observe current document
	[NSApp addObserver:self forKeyPath:@"mainWindow.windowController.document" 
		options:0 context:NULL];
	
	[PluginLoader loadPluginsWithSearchPathDomainMask: NSUserDomainMask];
	
	// register the HTML store type
	Class clazz = NSClassFromString(@"HTMLStore");
	if (nil == clazz) {
		NSLog(@"Could not load HTMLStore plugin");
	} else {
		[NSPersistentStoreCoordinator registerStoreClass:clazz forStoreType:@"HTMLStore"];
		NSLog(@"HTMLStoreLoader done.  Registered store types are now:  %@", [NSPersistentStoreCoordinator registeredStoreTypes] );
	}
	
}

- (void)showNewDocumentWizard {
	if (_newDocumentWizardController == nil) {
		_newDocumentWizardController = [[NewDocumentWizardController alloc] initWithWindowNibName:@"NewDocumentWizard"];
	}
	[_newDocumentWizardController.window center];	
	NSRect frame = [_newDocumentWizardController.window frame];
	NSRect screen = [[_newDocumentWizardController.window screen] frame];
	frame.origin.y = (screen.size.height - frame.size.height) / 2;
	[_newDocumentWizardController.window setFrameOrigin:frame.origin];
	[_newDocumentWizardController.window makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey: kSTEShowNewDocumentWizard] == YES) {
		[self showNewDocumentWizard];
	}	
    return NO;
}

- (void) dealloc
{
	[NSApp removeObserver:self forKeyPath:@"mainWindow.windowController.document"];
	[_newDocumentWizardController release];
	[_splashScreenVersionLabel release];
	[_splashScreen release];
	[_currentDocument release];
	[_window release];
	[_assetEditorController release];
	[super dealloc];
}

#pragma mark -
#pragma mark error handling
- (NSError*)application:(NSApplication*)application
	   willPresentError:(NSError*)error
{
	if (error)
	{
		NSDictionary* userInfo = [error userInfo];
		lperrorf("encountered the following error: %@ (%@)", error, userInfo);		
#ifdef SPAWN_DEBUGGER_ON_ERROR
		Debugger();
#endif
	}
	
	return error;
}

#pragma mark -
#pragma mark IBActions

- (IBAction)showPreferences:(id)sender{
	if (!m_prefsWindowController){
		NSWindow *window = [[NSWindow alloc] initWithContentRect:(NSRect){0, 0, 100, 100} 
			styleMask:(NSTitledWindowMask | NSClosableWindowMask) 
			backing:NSBackingStoreBuffered defer:YES];
		m_prefsWindowController = [[NSMPreferencesWindowController alloc] initWithWindow:window];
		m_prefsWindowController.toolbarIdentifier = @"STPreferencesToolbar";
		m_prefsWindowController.windowAutosaveName = @"STPreferencesWindowOrigin";
		
		MainPreferencesViewController *mainPrefsViewController = 
			[[[MainPreferencesViewController alloc] init] autorelease];
		[m_prefsWindowController addPrefPaneWithController:mainPrefsViewController 
			icon:[NSImage imageNamed:@"General Preferences.tiff"]];
				
		[window release];
	}
	[m_prefsWindowController showWindow:self];
}



#pragma mark -
#pragma mark KVO Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change 
	context:(void *)context{
	// we need to delay the method call, because otherwise the sharedDocumentController would 
	// argue it would still have documents openened, if this was the last window
	[self performSelector:@selector(_updateCurrentDocument) withObject:nil 
		afterDelay:0.0];
}



#pragma mark -
#pragma mark Private methods

- (void)_updateCurrentDocument{
	id doc = [[[NSApp mainWindow] windowController] document];
	if ((doc == _currentDocument || ![doc isKindOfClass:[MyDocument class]]) && 
		[[[NSDocumentController sharedDocumentController] documents] count] > 0){
		return;
	}
	self.currentDocument = doc;
}

@end

@implementation NSApplication ( StoryTellingEditorAppDelegate )
- (StoryTellingEditorAppDelegate *) storyTellingEditorDelegate
{
	return (StoryTellingEditorAppDelegate *) [self delegate];
}
@end

