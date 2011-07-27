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

#import "CanvasModel.h"


@implementation CanvasModel

@synthesize items=m_items, 
			selectedItems=m_selectedItems, 
			itemClass=m_itemClass;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	NSSet *affectedKeys = nil;	
    if ([key isEqualToString:@"selectedItems"])
		affectedKeys = [NSSet setWithObject:@"selectedItem"];
	keyPaths = [keyPaths setByAddingObjectsFromSet:affectedKeys];
	return keyPaths;
}

- (id)init
{
	if (self = [super init])
	{
		m_items = [[NSMutableSet alloc] init];
		m_selectedItems = nil;
		m_itemClass = [CanvasItem class];
	}
	return self;
}

- (void)dealloc
{
	[m_selectedItems release];
	[m_items release];
	[super dealloc];
}

- (CanvasItem *)selectedItem
{
	return [m_selectedItems anyObject];
}

- (void)setSelectedItem:(CanvasItem *)item
{
	self.selectedItems = item == nil 
		? nil 
		: [NSSet setWithObject:item];
}

- (CanvasItem *)addItemAtPoint:(CGPoint)point
{
	CanvasItem *item = [[m_itemClass alloc] init];
	item.position = point;
	item.size = (CGSize){100.0f, 100.0f};
	[self addItem:item];
	[item release];
	return item;
}

- (CanvasItem *)addItemWithFrame:(CGRect)rect
{
	CanvasItem *item = [[m_itemClass alloc] init];
	item.frame = CGRectStandardize(rect);
	[self addItem:item];
	[item release];
	return item;
}

- (void)addItem:(CanvasItem *)item
{
	[self willChangeValueForKey:@"items"];
	[m_items addObject:item];
	[self didChangeValueForKey:@"items"];
	self.selectedItem = item;
}

- (void)removeItem:(CanvasItem *)item
{
	[self willChangeValueForKey:@"items"];
	[m_items removeObject:item];
	[self didChangeValueForKey:@"items"];
}

- (NSSet *)itemsInRect:(CGRect)rect
{
	return [m_items objectsPassingTest:^BOOL(id obj, BOOL *stop){
			return CGRectIntersectsRect(rect, [(CanvasItem *)obj frame]);}];
}

- (void)selectItemsInRect:(CGRect)rect
{
	self.selectedItems = [self itemsInRect:rect];
}

- (CGRect)selectionFrame
{
	CGRect frame = CGRectZero;
	for (CanvasItem *item in m_selectedItems)
	{
		if (CGRectIsEmpty(frame))
			frame = item.frame;
		else
			frame = CGRectUnion(frame, item.frame);
	}
	return frame;
}

- (NSXMLDocument *)xmlRepresentation
{
	NSMutableArray *children = [NSMutableArray array];
	for (CanvasItem *item in m_items)
		[children addObject:[item xmlRepresentation]];
	NSXMLElement *dataNode = [NSXMLNode elementWithName:@"data" children:children attributes:nil];
	NSXMLElement *rootNode = [NSXMLNode elementWithName:@"archive" 
		children:[NSArray arrayWithObject:dataNode] 
		attributes:[NSArray arrayWithObjects:
			[NSXMLElement attributeWithName:@"type" stringValue:@"aa.InterfaceBuilder1.AS.AIB"], 
			[NSXMLElement attributeWithName:@"version" stringValue:@"1.00"], 
			nil]];
	return [NSXMLDocument documentWithRootElement:rootNode];
}

@end
