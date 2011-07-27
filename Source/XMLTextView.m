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

#import "XMLTextView.h"


@implementation XMLTextView

// string that is pasted from OxygenXML has strange line breaks
- (NSString*)stringByNormalizingLineBreaks:(NSString*) str {
	NSMutableString *newStr = [NSMutableString stringWithString:str];
	NSRange entireString = [str rangeOfString:str];
	[newStr replaceOccurrencesOfString:@"\u2028" withString:@"\n"
							   options:NSLiteralSearch range:entireString];
	[newStr replaceOccurrencesOfString:@"\u2029" withString:@"\n"
							   options:NSLiteralSearch range:entireString];
	return newStr;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type {
	NSString *plaintext = [self plaintext];
	NSRange range = [self selectedRange];
	if (range.length == 0) {
		range = NSMakeRange(0, [plaintext length]);
	}
	NSString *selection = [plaintext substringWithRange:range];
	[pboard clearContents];
	[pboard setData:[selection dataUsingEncoding:NSUTF8StringEncoding] forType:NSPasteboardTypeString];
	return YES;	
}

- (NSString*)plaintext {
	NSString* XMLString = [NSString stringWithString:[[[self textStorage] string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	XMLString = [self stringByNormalizingLineBreaks:XMLString];		
	return XMLString;
}

@end
