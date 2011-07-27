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

#import "AssetDragVO.h"

@implementation AssetDragVO

@synthesize name, externalId, externalURL, type, contentType;

- (void)dealloc{
	[name release];
	[externalId release];
	[externalURL release];
	[contentType release];
	[super dealloc];
}

- (NSString *)description{
	return [NSString stringWithFormat:@"<%@ = 0x%08x> name: %@, externalURL: %@, externalId: %@, type: %d", 
		[self className], (long)self, name, externalURL, externalId, type];
}

- (id)initWithCoder:(NSCoder *)decoder{
	if (self = [super init]){
		name = [[decoder decodeObjectForKey:@"name"] retain];
		externalId = [[decoder decodeObjectForKey:@"externalId"] retain];
		externalURL = [[decoder decodeObjectForKey:@"externalURL"] retain];
		type = [decoder decodeIntForKey:@"type"];
		contentType = [[decoder decodeObjectForKey:@"contentType"] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeObject:name forKey:@"name"];
	[coder encodeObject:externalId forKey:@"externalId"];
	[coder encodeObject:externalURL forKey:@"externalURL"];
	[coder encodeInt:type forKey:@"type"];
	[coder encodeInt:type forKey:@"contentType"];	
}

+ (NSInteger)typeFromString:(NSString*)ts {
	if ([ts isEqualToString:@"page"])			{	return AssetDragVOTypePage;		} 
	else if ([ts isEqualToString:@"article"])	{	return AssetDragVOTypeArticle;	} 
	else if ([ts isEqualToString:@"img"])		{	return AssetDragVOTypeImage;	} 
	else if ([ts isEqualToString:@"video"])		{	return AssetDragVOTypeVideo;	} 
	else if ([ts isEqualToString:@"folder"])	{	return AssetDragVOTypeFolder;	}
	return AssetDragVOTypeUnknown;
}

@end
