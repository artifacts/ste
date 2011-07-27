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

#import "NSWindow+Util.h"


@implementation NSWindow (Util)

/*
 
 window toolbar height
 
 */
- (float) toolbarHeight
{
    return NSHeight([NSWindow contentRectForFrameRect:[self frame] styleMask:[self styleMask]]) - NSHeight([[self contentView] frame]);
}

/*
 
 window title bar height
 
 */
- (float) titleBarHeight
{
    return NSHeight([self frame]) -
	NSHeight([[self contentView] frame]) -
	[self toolbarHeight];
}

#define kIconSpacing 8.0 // h-space between the icon and the toolbar button
/*
 
 add icon to toolbar
 
 */
- (NSImageView*) addIconToTitleBar:(NSImage*) icon
{
    id superview = [[self standardWindowButton:NSWindowToolbarButton]
					superview];
	
	// assume toolbarbutton present
    NSRect toolbarButtonFrame = [[self
								  standardWindowButton:NSWindowToolbarButton] frame];
    NSRect iconFrame;
	
    iconFrame.size = [icon size];
    iconFrame.origin.y = NSMaxY([superview frame]) -
	(iconFrame.size.height + ceil(([self titleBarHeight] - iconFrame.size.height) / 2.0));
    iconFrame.origin.x = NSMinX(toolbarButtonFrame) -
	iconFrame.size.width -
	kIconSpacing;
	
    NSImageView* iconView = [[[NSImageView alloc]
							  initWithFrame:iconFrame]
							 autorelease];
    [iconView setImage:icon];
    [iconView setEditable:NO];
    [iconView setImageFrameStyle:NSImageFrameNone];
    [iconView setImageScaling:NSScaleNone];
    [iconView setImageAlignment:NSImageAlignCenter];
    [iconView setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [superview addSubview:iconView];
	
    return iconView;
}

/*
 
 add icon to toolbar
 
 */
- (void) addViewToTitleBar:(NSView*)view xoffset:(CGFloat)xoffset
{
    id superview = [[self standardWindowButton:NSWindowToolbarButton]
					superview];
    NSRect toolbarButtonFrame = [[self
								  standardWindowButton:NSWindowToolbarButton] frame];
    NSRect iconFrame;
	
    iconFrame.size = [view bounds].size;
    iconFrame.origin.y = NSMaxY([superview frame]) -
	(iconFrame.size.height + ceil(([self titleBarHeight] -
								   iconFrame.size.height) / 2.0));
    iconFrame.origin.x = NSMinX(toolbarButtonFrame) -
	iconFrame.size.width - kIconSpacing;
	
	if (xoffset > 0) {
		iconFrame.origin.x -= (xoffset + kIconSpacing);
	}
	
    [view setFrame:iconFrame];
    [view setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [superview addSubview:view];
	
    return;
}
@end
