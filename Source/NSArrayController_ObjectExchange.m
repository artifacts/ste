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

#import "NSArrayController_ObjectExchange.h"

#import "ObjectExchange.h"
#import "NSManagedObject_DictionaryRepresentation.h"

#import "Convenience_Macros.h"

@implementation NSArrayController (ObjectExchange)


NSString *NSStringFromDragOperation(NSDragOperation operation)
{
	return [NSString stringWithFormat: @"%s%s%s%s%s%s",
	operation & NSDragOperationCopy ? "Copy " : "",	
	operation & NSDragOperationLink ? "Link " : "",
	operation & NSDragOperationGeneric ? "Generic " : "",
	operation & NSDragOperationPrivate ? "Private " : "",
	operation & NSDragOperationMove ? "Move " : "",
	operation & NSDragOperationDelete ? "Delete " : ""
	];
}

- (NSDictionary *) optionsWithEntityNameFromOptions: (NSDictionary *) options
{
	if( nil == [options valueForKey: kObjectExchangeEntityName] ) {
		options = options ? [NSMutableDictionary dictionaryWithDictionary: options] : [NSMutableDictionary dictionary];

		NSString *entityName = [self entityName];
		NSAssert( entityName != nil, @"optionsWithEntityNameFromOptions: needs entityName in options or on arraycontroller");		

		[options setValue: entityName forKey: kObjectExchangeEntityName];
	}

	return options;
}

- (NSArray *) objectExchangeUTIsWithOptions: (NSDictionary *) options
{
	options = [self optionsWithEntityNameFromOptions: options];
	return [ObjectExchange UTIsWithOptions: options];
}

- (BOOL) isSortedByDescendingKey: (NSString *) key
{
	// if we have a sort descriptor targeting the given viewPosition key (does not work for keyPath) 
	// then we have to renumber and select insertion points in reverse order
	BOOL sortedByDescendingKey = ( NSNotFound != [[self sortDescriptors] indexOfObjectPassingTest: ^(id obj, NSUInteger idx, BOOL *stop){ 
		return (BOOL) ( NO == [obj ascending] && [[obj key] isEqualToString: key] );
	}]);
	
	NSLog(@"%@ sortedByDescendingKey '%@': %@", [self entityName], key, sortedByDescendingKey ? @"YES" : @"NO");

	return sortedByDescendingKey;
}

- (BOOL) writeObjectsAtIndexes: (NSIndexSet *) indexes toPasteboard: (NSPasteboard *) pboard options: (NSDictionary *) options
{
	return [NSManagedObject writeObjects: [self arrangedObjects] atIndexes: indexes toPasteboard: pboard options: [self optionsWithEntityNameFromOptions: options]];
}

- (BOOL) writeSelectionToPasteboard: (NSPasteboard *) pboard options: (NSDictionary *) options
{
	return [self writeObjectsAtIndexes: [self selectionIndexes] toPasteboard: pboard options: options];
}

#if UNTESTED_CODE
- (BOOL) setValuesForKeyPaths: (NSArray *) keyPaths fromPasteboard: (NSPasteboard *) pboard options: (NSDictionary *) options error: (NSError **) outError
{
	CHECK_NSERROR_REASON_RETURN_NO(0 != [keyPaths count], outError, NSPOSIXErrorDomain, EINVAL, @"errorApplyValuesWithoutKeyPaths");
	
	NSArray *sourceObjects = [NSManagedObject objectsFromPasteboard: pboard managedObjectContext: [self managedObjectContext] options: options error: outError];

	CHECK_NSERROR_REASON_RETURN_NO(0 != [sourceObjects count], outError, NSPOSIXErrorDomain, EINVAL, @"errorApplyValuesWithoutSourceObjects");

	NSArray *targetObjects = [self selectedObjects];

	CHECK_NSERROR_REASON_RETURN_NO(0 != [targetObjects count], outError, NSPOSIXErrorDomain, EINVAL, @"errorApplyValuesWithoutTargetObjects");

	NSInteger sourceIndex = 0;
	for( NSManagedObject *target in targetObjects ) {
		
		NSManagedObject *source = [sourceObjects objectAtIndex: sourceIndex];
		
		for( NSString *path in keyPaths ) {
			[target setValue: [source valueForKeyPath: path] forKeyPath: path];
		}

		[[source managedObjectContext] deleteObject: source];

		// if we have fewer source objects then we apply the last one from here
		if( sourceIndex < [sourceObjects count] - 1 ) {
			++sourceIndex;
		}
	}

	return YES;
}
#endif

- (BOOL) insertFromPasteboard: (NSPasteboard *) pboard options: (NSDictionary *) options error: (NSError **) outError
{
	NSString *viewPositionKeyPath = [options valueForKey: kObjectExchangeViewPositionKeyPath];

	// will fallback to NO if keyPath is indeed a path
	BOOL isSortedByDescendingViewPosition =  ( nil == viewPositionKeyPath ) ? NO : [self isSortedByDescendingKey: viewPositionKeyPath];

	NSInteger insertionOffset = isSortedByDescendingViewPosition ? 0 : 1;

	NSUInteger insertionIndex = isSortedByDescendingViewPosition ? [[self selectionIndexes] firstIndex] : [[self selectionIndexes] lastIndex];

	if( NSNotFound == insertionIndex ) {
		insertionIndex = isSortedByDescendingViewPosition ? 0 : [[self arrangedObjects] count] - 1;
	}

	NSLog(@"%@ insertionIndex+insertionOffset: %ld + %ld", [self entityName], (long) insertionIndex, (long) insertionOffset);

	return [self performDragOperation: NSDragOperationCopy fromPasteboard: pboard beforeIndex: insertionIndex + insertionOffset options: options error: outError];
}

- (void) updateViewPositionsOfObjects: (NSArray *) array usingKeyPath: (NSString *) keyPath
{
	// will fallback to NO if keyPath is indeed a path
	NSUInteger idxReverseOffset = [self isSortedByDescendingKey: keyPath] ? [array count] - 1 : 0;

	NSLog(@"before: %@", [array valueForKey: keyPath]);
	[array enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		NSUInteger oldIndex = [[obj valueForKeyPath: keyPath] unsignedIntegerValue];
		NSInteger newIndex = (idxReverseOffset == 0) ? idx : idxReverseOffset - idx;
		NSLog(@"idx: %ld old: %ld new: %ld", (long) idx, (long) oldIndex, (long) newIndex);
		if( oldIndex != newIndex ) {
			[obj setValue: [NSNumber numberWithUnsignedInteger: newIndex] forKeyPath: keyPath];
		}
	}];
	NSLog(@"after: %@", [array valueForKey: keyPath]);
}

- (void) updateNamesOfObjects: (NSArray *) newObjects usingKeyPath: (NSString *) keyPath avoidingCollisionsWithExistingObjects: (NSArray *) existingObjects 
{
	NSInteger startSuffix = 2;
	
	NSMutableSet *names = [NSMutableSet setWithArray: [existingObjects valueForKeyPath: keyPath]];
	[[newObjects valueForKeyPath: keyPath] enumerateObjectsUsingBlock:^(id oldName, NSUInteger idx, BOOL *stop) {
		NSString *newName = oldName;

		while( [names containsObject: newName] ) {

			NSInteger currentSuffix = 0; 

			if( [newName hasSuffix: @"]"] ) {
				NSRange suffixRange = [newName rangeOfString: @"[" options: NSBackwardsSearch];
				if(suffixRange.location != NSNotFound) {
					NSRange scanRange = { suffixRange.location + 1, [newName length] - suffixRange.location - 1 };
					currentSuffix = [[newName substringWithRange: scanRange] integerValue];
					if( currentSuffix >= startSuffix ) {
						suffixRange.length += scanRange.length;
						newName = [newName stringByReplacingCharactersInRange: suffixRange withString: @""];
					}
				}
			}

			if( currentSuffix < startSuffix ) {
				currentSuffix = startSuffix - 1;
			} 

			NSString *formattedNextSuffix = [NSString stringWithFormat: @"[%ld]", (long)currentSuffix + 1];

			newName = [newName stringByAppendingString: formattedNextSuffix];
		}

		if( newName != oldName ) { // pointer test ok
			[[newObjects objectAtIndex: idx] setValue: newName forKey: keyPath];
			[names addObject: newName];
		}
	}];
}

- (BOOL) performDragOperation: (NSDragOperation) dragOperation fromPasteboard: (NSPasteboard *) pboard beforeIndex: (NSInteger) destinationIndex options: (NSDictionary *) options error: (NSError **) outError
{
	options = [self optionsWithEntityNameFromOptions: options];

	NSMutableArray *objects = [NSMutableArray arrayWithArray: [self arrangedObjects]];

	NSInteger initialCount = [objects count];

	NSManagedObject *destinationIndexObject = (destinationIndex >= 0 && destinationIndex < initialCount) ? [objects objectAtIndex: destinationIndex] : nil;

	NSIndexSet *sourceIndexes = nil;
	NSArray *draggedObjects = nil;

	if( NSDragOperationCopy == dragOperation ) {
		draggedObjects = [NSManagedObject objectsFromPasteboard: pboard managedObjectContext: [self managedObjectContext] options: options error: outError];
		if( nil == draggedObjects ) {
			return NO;
		}
	} else {
		sourceIndexes = [ObjectExchange indexesFromPasteboard: pboard options: options error: outError];
		if( nil == sourceIndexes ) {
			return NO;
		}

		draggedObjects = [objects objectsAtIndexes: sourceIndexes];
	}

	if( 0 == [draggedObjects count] ) {
		CHECK_NSERROR_REASON_RETURN_NO(0 != [draggedObjects count], outError, NSPOSIXErrorDomain, EINVAL, @"errorDragOperationWithZeroObjects");
	}

	if( sourceIndexes && ( dragOperation & (NSDragOperationMove | NSDragOperationDelete) ) ) {
		[objects removeObjectsAtIndexes: sourceIndexes];
	}

	NSInteger newDestinationIndex = destinationIndexObject ? [objects indexOfObject: destinationIndexObject] : [objects count];

	if( NSNotFound == newDestinationIndex ) {
		newDestinationIndex = [objects count];
	}

	NSLog(@"performDragOperation: %@ %@ from %@ to former %ld now: %ld", [self entityName], NSStringFromDragOperation(dragOperation), sourceIndexes, (long)destinationIndex, (long)newDestinationIndex);

	if( ( NSDragOperationMove | NSDragOperationCopy ) & dragOperation ) {
		[objects insertObjects: draggedObjects atIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(newDestinationIndex, [draggedObjects count])]];
	}
	
	NSString *viewPositionKeyPath = [options valueForKey: kObjectExchangeViewPositionKeyPath];
	NSString *nameToChangeOnCopyKeyPath = [options valueForKey: kObjectExchangeNameToChangeOnCopyKeyPath];
	
	if( nil != viewPositionKeyPath ) {
		[self updateViewPositionsOfObjects: objects usingKeyPath: viewPositionKeyPath];
	}
	
	// clear
	[self setSelectionIndexes: [NSIndexSet indexSet]];
	
	switch( dragOperation ) {
		
		case NSDragOperationDelete:
			[self removeObjectsAtArrangedObjectIndexes: sourceIndexes];	
			break;
		
		case NSDragOperationCopy:
			if( nil != nameToChangeOnCopyKeyPath ) {
				[self updateNamesOfObjects: draggedObjects usingKeyPath: nameToChangeOnCopyKeyPath avoidingCollisionsWithExistingObjects: [self arrangedObjects]];
			}
		
			[self addObjects: draggedObjects];
			[self addSelectedObjects: draggedObjects];
			break;
		
		case NSDragOperationMove:
			[self addSelectedObjects: draggedObjects];
			break;

		default:
			NSBeep();
			NSLog(@"unsupported drag operation (%@)", NSStringFromDragOperation(dragOperation));
			return NO;
			break;
	}

	[self rearrangeObjects];

	return YES;
}


@end
