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

#import "NSTreeController+NSMAdditions.h"

@interface NSTreeController (NSMPrivateAdditions)
- (NSTreeNode *)_nodeForObject:(id)anObject inArray:(NSArray *)anArray;
@end


@implementation NSTreeController (NSMAdditions)

- (NSArray *)rootNodes;
{
	return [[self arrangedObjects] childNodes];
}

- (NSTreeNode *)nodeAtIndexPath:(NSIndexPath *)indexPath;
{
	return [[self arrangedObjects] descendantNodeAtIndexPath:indexPath];
}

- (NSMutableArray*)_traverseNodesStartingWithNode:(id)currentNode collectedNodes:(NSMutableArray*)collectedNodes {
	if (currentNode == nil) {
		currentNode = [self arrangedObjects];
	}
	if ([collectedNodes containsObject:currentNode]) return collectedNodes;
	if ([currentNode respondsToSelector:@selector(representedObject)]) {		
		[collectedNodes addObject:currentNode];
	}
	for (id child in [[currentNode childNodes] reverseObjectEnumerator]) {
		[self _traverseNodesStartingWithNode:child collectedNodes:collectedNodes];
	}
	return collectedNodes;
}

// all the NSTreeNodes in the tree, depth-first searching
- (NSArray *)flattenedNodes;
{
	NSMutableArray *nodes = [self _traverseNodesStartingWithNode:nil collectedNodes:[NSMutableArray array]];
	return [[nodes copy] autorelease];
}


- (void)setSelectedObject:(id)anObject{
	if (anObject == nil) return;
	[self setSelectedObjects:[NSArray arrayWithObject:anObject]];
}

- (void)setSelectedObjects:(NSArray *)objects{
	NSMutableArray *indexPaths = [NSMutableArray array];
	for (id obj in objects){
		NSIndexPath *path = [self indexPathForObject:obj];
		if (path) [indexPaths addObject:path];
	}
	[self setSelectionIndexPaths:indexPaths];
}

- (NSIndexPath *)indexPathForObject:(id)anObject{
	NSInteger index;
	NSArray *sortedArray = [[self content] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"viewPosition" ascending:NO]]];
	
	if ((index = [sortedArray indexOfObjectIdenticalTo:anObject]) != NSNotFound)
		return [NSIndexPath indexPathWithIndex:index];
	
	__block BOOL (^indexPathOfObjectInNode)(id, id, NSIndexPath**);
	indexPathOfObjectInNode = ^(id anObject, id aNode, NSIndexPath **path){
			// mic, 2010-09-12: changed from NSArray to NSSet because CoreData gives us a set
			NSSet *nodes = [aNode valueForKey:[self childrenKeyPath]];
			if (!nodes) return NO;
			NSArray *sortedArray = [[nodes allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"viewPosition" ascending:NO]]];
			NSInteger index = [sortedArray indexOfObjectIdenticalTo:anObject];
			if (index != NSNotFound){
				*path = [*path indexPathByAddingIndex:index];
				return YES;
			}
			NSInteger i = 0;
			for (id subNode in nodes){
				NSIndexPath *pathCopy = [*path indexPathByAddingIndex:i++];
				BOOL success = indexPathOfObjectInNode(anObject, subNode, &pathCopy);
				if (success){
					*path = pathCopy;
					return YES;
				}
			}
			return NO;
	};
	
	NSInteger i = 0;
	for (id subNode in sortedArray){
		NSIndexPath *path = [NSIndexPath indexPathWithIndex:i++];
		if (indexPathOfObjectInNode(anObject, subNode, &path)){
			return path;
		}
	}
	
	return nil;
}

- (NSTreeNode *)nodeForObject:(id)anObject{
	if (anObject == nil) return nil;
	return [self _nodeForObject:anObject inArray:[[self arrangedObjects] childNodes]];
}

- (NSTreeNode *)_nodeForObject:(id)anObject inArray:(NSArray *)anArray{
	for (id node in anArray){
		if ([node representedObject] == anObject)
			return node;
		id subnode = [self _nodeForObject:anObject inArray:[node childNodes]];
		if (subnode) return subnode;
	}
	return nil;
}
@end
