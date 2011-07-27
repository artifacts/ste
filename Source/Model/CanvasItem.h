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


@interface CanvasItem : NSObject
{
	CGRect frame;
	CGFloat cornerRadius;
	NSColor *backgroundColor;
	NSImage *backgroundImage;
	CGPoint backgroundImagePosition;
	
	NSColor *shadowColor;
	CGFloat shadowOpacity;
	CGFloat shadowRadius;
	CGFloat shadowXOffset;
	CGFloat shadowYOffset;
}
@property (nonatomic, assign) CGFloat xPosition;
@property (nonatomic, assign) CGFloat yPosition;
@property (nonatomic, assign) CGFloat frameWidth;
@property (nonatomic, assign) CGFloat frameHeight;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGSize size;

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, retain) NSImage *backgroundImage;
@property (nonatomic, assign) CGPoint backgroundImagePosition;
@property (nonatomic, retain) NSColor *backgroundColor;

@property (nonatomic, retain) NSColor *shadowColor;
@property (nonatomic, assign) CGFloat shadowOpacity;
@property (nonatomic, assign) CGFloat shadowRadius;
@property (nonatomic, assign) CGFloat shadowXOffset;
@property (nonatomic, assign) CGFloat shadowYOffset;

- (NSXMLNode *)xmlRepresentation;
@end
