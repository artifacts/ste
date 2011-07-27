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

#import "PluginLoader.h"
#import "Convenience_Macros.h"

@implementation PluginLoader

#pragma mark -
#pragma mark Plugin Support

static NSString *kPluginBundleApplicationSupportSubFolder = @"Plug-Ins";
static NSString *kPluginBundleExtension = @"plugin";

static NSString *kPluginBundleMenuItemsKey = @"pluginMenuItems";
static NSString *kPluginBundleMenuActionKey = @"action";
static NSString *kPluginBundleMenuItemNameKey = @"title";
static NSString *kPluginBundleMenuKeyEquivalentKey = @"keyEquivalent";

static NSString *kPluginBundleDefaultMenuAction = @"defaultPluginAction:";

static NSMutableDictionary *_plugins = nil;

+ (NSDictionary *) plugins
{
	return [[_plugins retain] autorelease];
}

+ (void) installPluginMenuItems: (NSDictionary *) pluginMenuItemsByBundleIdentifier
{
	if( 0 != [pluginMenuItemsByBundleIdentifier count] ) {

		NSMenu *mainMenu = [NSApp mainMenu];

		NSMenu *appMenu = [[[mainMenu itemArray] objectAtIndex: 0] submenu];

		NSMenuItem *pluginsMenuItem = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Plug-Ins", @"Plug-Ins Menu Title") action: NULL keyEquivalent: @""] autorelease];
		[appMenu insertItem: pluginsMenuItem atIndex: 1];

		NSMenu *pluginsMenu = [[[NSMenu alloc] initWithTitle: @""] autorelease];
		[pluginsMenuItem setSubmenu: pluginsMenu];

		for( NSString *targetName in [[pluginMenuItemsByBundleIdentifier allKeys] sortedArrayUsingSelector: @selector(compare:)]  ) {
				
			NSMenuItem *targetMenuItem = [[[NSMenuItem alloc] initWithTitle: targetName action: NULL keyEquivalent: @""] autorelease];
			[pluginsMenu addItem: targetMenuItem];

			NSMenu *pluginSubMenu = [[[NSMenu alloc] initWithTitle: @""] autorelease];

			[targetMenuItem setSubmenu: pluginSubMenu];			

			for( NSDictionary *menuDict in [pluginMenuItemsByBundleIdentifier objectForKey: targetName] ) {
			
				NSString *menuTitle = [menuDict objectForKey: kPluginBundleMenuItemNameKey] ?: targetName;
				NSString *menuAction = [menuDict objectForKey: kPluginBundleMenuActionKey] ?: kPluginBundleDefaultMenuAction;
				NSArray *keyParts = [[menuDict objectForKey: kPluginBundleMenuKeyEquivalentKey] ?: @"" componentsSeparatedByString: @" "];
				
				NSString *keyCharacter = [keyParts lastObject];

				NSInteger modifierMask = 0;
				
				if( [keyParts count] > 1 ) {
					if( 0 == [keyCharacter length] ) { // special case if space is the key
						keyCharacter = @" ";
					}

					for( NSString *modifier in keyParts ) {
						modifierMask |= 
							( [modifier isEqualToString: @"cmd"] ? NSCommandKeyMask : 0 ) |
							( [modifier isEqualToString: @"ctrl"] ? NSControlKeyMask : 0 ) |
							( [modifier isEqualToString: @"shift"] ? NSShiftKeyMask : 0 ) |
							( [modifier isEqualToString: @"alt"] ? NSAlternateKeyMask : 0 );
					}
				} 
				
				NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle: menuTitle action: NSSelectorFromString(menuAction) keyEquivalent: keyCharacter] autorelease];

				[menuItem setKeyEquivalentModifierMask: modifierMask];
				[menuItem setTarget: [_plugins objectForKey: targetName]];

				[pluginSubMenu addItem: menuItem];

			} // menuItem

		} // targetName

		NSLog(@"menuItems: %@", pluginMenuItemsByBundleIdentifier);

	} // if menuItems
}

+ (void) loadPluginsAtPaths: (NSArray *) allPluginPaths
{
	_plugins = [[NSMutableDictionary alloc] init];

	NSMutableDictionary *pluginMenuItemsByBundleIdentifier = [NSMutableDictionary dictionary];

	for( NSString *pluginPath in allPluginPaths ) {
		NSLog(@"loading plug-in: %@", pluginPath);
		
		NSBundle *pluginBundle = [NSBundle bundleWithPath: pluginPath];
		NSError *error = nil;
	
		if( NO == CHECK_NSERROR_REASON(pluginBundle != nil, &error, NSPOSIXErrorDomain, EINVAL, @"errorCouldNotCreateBundleFromPluginPath: %@", pluginPath) ) {
			lperror(error);
			[NSApp presentError: error];
			continue;
		}

		if( NO == [pluginBundle loadAndReturnError: &error] ) {
			lperror(error);
			[NSApp presentError: error];
		} else {
			id plugin = [[[[pluginBundle principalClass] alloc] init] autorelease];

			NSString *pluginIdentifier = [pluginBundle bundleIdentifier];
			
			NSArray *pluginBundleMenuItems = [pluginBundle objectForInfoDictionaryKey: kPluginBundleMenuItemsKey];
			
			if( 0 != [pluginBundleMenuItems count] ) {
				[pluginMenuItemsByBundleIdentifier setObject: pluginBundleMenuItems forKey: pluginIdentifier];
			}

			[_plugins setObject: plugin forKey: [pluginBundle bundleIdentifier]];
		}
	}

	[self installPluginMenuItems: pluginMenuItemsByBundleIdentifier];

	NSLog(@"plugins: %@", self.plugins);
}

+ (void) loadPluginsWithSearchPathDomainMask: (NSSearchPathDomainMask) searchPathDomainMask
{
	NSMutableArray *plugins = [NSMutableArray array];

	NSArray *pluginPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, searchPathDomainMask, YES);

	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey: (id)kCFBundleNameKey];

	for( NSString *path in pluginPaths ) {
		NSString *fullPath = [[path stringByAppendingPathComponent: appName] stringByAppendingPathComponent: kPluginBundleApplicationSupportSubFolder];
		[plugins addObjectsFromArray: [NSBundle pathsForResourcesOfType: kPluginBundleExtension inDirectory: fullPath]];
	}

	if( 0 != [plugins count] ) {
		[self loadPluginsAtPaths: plugins];
	}
}

@end
