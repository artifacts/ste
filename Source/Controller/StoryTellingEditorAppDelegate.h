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
#import <AFCache/AFCacheLib.h>
#import "TimelineViewController.h"
#import "PanelWindowController.h"
#import "NSMPreferencesWindowController.h"
#import "MainPreferencesViewController.h"
#import "Constants.h"
#import "NewDocumentWizardController.h"

@class MyDocument;

@interface StoryTellingEditorAppDelegate : NSObject{
    NSWindow *_window;
	NSDocumentController *_documentController;
	NSObjectController *_assetEditorController;
	MyDocument *_currentDocument;
	PanelWindowController *_panelWindowController;
	NSMPreferencesWindowController *m_prefsWindowController;
	NSWindow *_splashScreen;
	NSTextField *_splashScreenVersionLabel;
	BOOL surpressOpenDocumentError;
	NewDocumentWizardController *_newDocumentWizardController;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet NSDocumentController *documentController;
@property (nonatomic, retain) IBOutlet NSObjectController *assetEditorController;
@property (nonatomic, retain) MyDocument *currentDocument;
@property (nonatomic, retain) IBOutlet NSWindow *splashScreen;
@property (nonatomic, retain) IBOutlet NSTextField *splashScreenVersionLabel;
@property (nonatomic, assign) BOOL surpressOpenDocumentError;
@property (nonatomic, retain) IBOutlet NewDocumentWizardController *newDocumentWizardController;

@property (nonatomic, readonly) AssetEditor *assetEditor;

- (IBAction)showPreferences:(id)sender;
- (NSString *) pathForApplicationSupportSubFolder: (NSString *) subFolder createIfNeeded: (BOOL) createIfNeeded;

- (void) mailto: (NSString *) recipients subject: (NSString *) subject body: (NSString *) body; 

- (void)showNewDocumentWizard;

@end

@interface NSApplication ( StoryTellingEditorAppDelegate )
- (StoryTellingEditorAppDelegate *) storyTellingEditorDelegate;
@end
