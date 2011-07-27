/*
Copyright (c) 2010, Bjoern Kriews
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the distribution.
Neither the name of the author nor the names of its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, 
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* 


HOWTO: Create a Plugin

Xcode -> File -> New Project

	Place in the same directory containing the app source,
	the two projects must be siblings.


	Mac OS X 
		Framework & Library
			Bundle

	Framework Popup: Cocoa

Open Top-Level Project, Classes -> New File

	Mac OS X
		Objective-C Class

	Subclass of: NSObject (change to NSResponder!) or NSWindowController
	
	Create some IB-Actions if you want to

Select "Targets" -> your bundle

	Get Info -> Properties

		Fix identifier + version

		Enter Principal Class created above


	Get Info -> Build

		Wrapper Extension -> "plugin"

		User Header Search Paths -> ../AppSourceDir/ (recursive)
		
			If you want to include files from AppSourceDir which reference Headers
			from Frameworks linked into the app then an easy way to find them
			is having a shared build directory and building the app beforehand.
			Otherwise you have to add them here.
	

	Open Info.plist
	
		Fix version
		
		Add an Array "pluginMenuItems", containing dictionaries like:
			title			YourMenuItemTitle
			action			yourMenuItemAction:
			keyEquivalent	ctrl shift alt cmd x

	I recommend creating a symlink from ~/Library/Application Support/Plug-Ins/your.plugin to your build directory.
*/

#import <Cocoa/Cocoa.h>

@interface PluginLoader : NSObject {

}

+ (void) loadPluginsWithSearchPathDomainMask: (NSSearchPathDomainMask) searchPathDomainMask;

+ (void) loadPluginsAtPaths: (NSArray *) allPluginPaths;

+ (NSDictionary *) plugins;

@end
