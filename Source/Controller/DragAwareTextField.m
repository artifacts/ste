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

#import "DragAwareTextField.h"
#import "MyDocument.h"

@implementation DragAwareTextField

- (void)awakeFromNib {
	[self registerForDraggedTypes:[NSArray arrayWithObject:kSTECMSContentDragType]];		
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self registerForDraggedTypes:[NSArray arrayWithObject:kSTECMSContentDragType]];		
    }
    return self;
}
/*
- (void)drawRect:(NSRect)dirtyRect {
	NSRect bounds = [self bounds];
	if (highlighted) {
		NSGradient *gr;
		gr = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor grayColor]];
		[gr drawInRect:bounds relativeCenterPosition:NSZeroPoint];
		[gr release];
	} else {
		[[NSColor whiteColor] set];
		[NSBezierPath fillRect:bounds];
	}
}
*/
- (BOOL)readFromPasteboard:(NSPasteboard*)pb {
	NSArray *types = [pb types];
	if ([types containsObject:kSTECMSContentDragType]) {
		NSData *carriedData = [pb dataForType:kSTECMSContentDragType];
		NSArray *dragData = [NSKeyedUnarchiver unarchiveObjectWithData:carriedData];
		if ([dragData count]>0) {
			AssetDragVO *dragVO = [dragData objectAtIndex:0];
			[self setStringValue:dragVO.externalId];
			return YES;
		}
	}
	return NO;
}

- (NSDragOperation)draggingEntered:(id)sender {
	NSLog(@"dragging entered:");
	if ([sender draggingSource]==self) {
		return NSDragOperationNone;
	}
	highlighted = YES;
	[self setNeedsDisplay:YES];
	return NSDragOperationCopy;
}

- (void)draggingExited:(id)sender {
	NSLog(@"draggingExited:");
	highlighted = NO;
	[self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id)sender {
	return YES;
}

- (BOOL)performDragOperation:(id)sender {
	NSPasteboard *pb = [sender draggingPasteboard];
	if (![self readFromPasteboard:pb]) {
		NSLog(@"Error: Could not read from dragging pasteboard");
		return NO;
	}
	return YES;
}

- (void)concludeDragOperation:(id)sender {
	NSLog(@"concludeDragOperation:");
	highlighted = NO;
	[self setNeedsDisplay:YES];
}

@end
