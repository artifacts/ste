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

#import "NSString+NSMAdditions.h"


@implementation NSString (NSMAdditions)

+ (NSString *)nsm_uuid{
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return [(NSString *)uuidStringRef autorelease];
}

- (NSString *)nsm_stringByEscapingHTMLEntities{
	NSMutableString *escapedString = [NSMutableString stringWithString:self];
	[escapedString replaceOccurrencesOfString:@"&" withString: @"&amp;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@"\"" withString: @"&quot;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@"'" withString: @"&#39;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@">" withString: @"&gt;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@"<" withString: @"&lt;" 
		options:NSLiteralSearch range:NSMakeRange(0, [escapedString length])];
	return [[escapedString copy] autorelease];
}

- (NSString *)nsm_normalizedFilename{
	NSMutableString *result = [NSMutableString stringWithString:self];
	[result replaceOccurrencesOfString:@":" withString:@"-" 
		options:0 range:(NSRange){0, [result length]}];
	[result replaceOccurrencesOfString:@"/" withString:@":" 
		options:0 range:(NSRange){0, [result length]}];
	return [result precomposedStringWithCanonicalMapping];
}

- (BOOL)nsm_isURL{
	return [self isMatchedByRegex:@"([hH][tT][tT][pP][sS]?:\\/\\/[^ ,'\">\\]\\)]*[^\\. ,'\">\\]\\)])"];
}

- (NSString *)nsm_stringByReplacingPlaceholdersWithContentsOfDict:(NSDictionary *)aDict{
	NSMutableString *result = [NSMutableString stringWithString:self];
	for (NSString *key in aDict){
		[result replaceOccurrencesOfString:[NSString stringWithFormat:@"%%%@%%", [key uppercaseString]] 
			withString:[aDict objectForKey:key] options:0 range:(NSRange){0, [result length]}];
	}
	return [NSString stringWithString:result];
}
@end
