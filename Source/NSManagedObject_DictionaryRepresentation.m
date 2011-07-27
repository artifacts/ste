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

#import "NSManagedObject_DictionaryRepresentation.h"

#import "ObjectExchange.h"

#import "Convenience_Macros.h"

@implementation NSManagedObject( DictionaryRepresentation )

+ (BOOL) writeObjects: (NSArray *) objects atIndexes: (NSIndexSet *) indexes toPasteboard: (NSPasteboard *) pasteboard options: (NSDictionary *) options
{
	if( nil == indexes ) {
		indexes = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, [objects count])];
	}
	
	if( 0 == [indexes count] ) {
		return NO;
	}

	NSArray *dictionaries = [self dictionaryRepresentationsOfObjects: [objects objectsAtIndexes: indexes] options: options];

	return [ObjectExchange writeDictionaries: dictionaries indexes: indexes toPasteboard: pasteboard options: options];
}


+ (NSArray *) objectsFromPasteboard: (NSPasteboard *) pboard managedObjectContext: (NSManagedObjectContext *) managedObjectContext options: (NSDictionary *) options error: (NSError **) outError
{
	NSArray *dictionaries = [ObjectExchange dictionariesFromPasteboard: pboard options: options error: outError];
	if( nil == dictionaries	) {
		return nil;
	}
	
	NSArray *objects = [self objectsFromDictionaryRepresentations: dictionaries inManagedObjectContext: managedObjectContext options: options error: outError];
	return objects;
}


- (NSDictionary *) dictionaryRepresentationWithOptions: (NSDictionary *) options
{
	NSDictionary *dictionary = [self dictionaryRepresentationWithOptions: options visitedObjects: nil];
	if( lpkswitch("dictionaryRepresentationDump", "dumping") ) {
		[dictionary writeToFile: @"/tmp/dictionaryRepresentation.plist" atomically: YES];
	}
	return dictionary;
}

- (NSString *) objectURIAsString
{
	return [[[self objectID] URIRepresentation] absoluteString];
}

- (NSDictionary *) dictionaryRepresentationWithOptions: (NSDictionary *) options visitedObjects: (NSMutableSet *) visitedObjects
{
	NSString *objectURIAsString = [self objectURIAsString];

	if( [visitedObjects containsObject: objectURIAsString] ) {
		return [NSDictionary dictionaryWithObject: objectURIAsString forKey: kObjectExchangeDictionaryRepresentationObjectIDReferenceKey];
	}

	if( nil == visitedObjects ) {
		visitedObjects = [NSMutableSet setWithObject: objectURIAsString];
	} else {
		[visitedObjects addObject: objectURIAsString];
	}

	NSEntityDescription *entity = [self entity];
	NSString *entityName = [entity name];

	NSSet *excludedKeys = nil;

	if( [self respondsToSelector: @selector(keysToExcludeFromDictionaryRepresentationInContext:)] ) {
		excludedKeys = [self performSelector: @selector(keysToExcludeFromDictionaryRepresentationInContext:) withObject: nil];
	}

	NSMutableDictionary *representation = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		entityName, kObjectExchangeDictionaryRepresentationEntityNameKey,
		objectURIAsString, kObjectExchangeDictionaryRepresentationObjectIDKey,
		nil];

	NSDictionary *attributes = [entity attributesByName];

	SEL freezer = @selector(freezeProperties);
	if( [self respondsToSelector: freezer] ) {
		[self performSelector: freezer];
	}

	for( NSString *key in [attributes allKeys] ) {
			if( [excludedKeys containsObject: key] ) {
				continue;
			}
	
			NSAttributeDescription *attribute = [attributes valueForKey: key];

			if( [attribute isTransient] ) {
				continue;
			}

			id value = [self valueForKey: key];

			if( nil != value ) {
				[representation setObject: value forKey: key];
			}
	}
		
	NSDictionary *relationships = [entity relationshipsByName];
	
	for (NSString *key in [relationships allKeys]) {
		if( [excludedKeys containsObject: key] ) {
			continue;
		}

		NSRelationshipDescription *relationship = [relationships valueForKey: key];
		
		if( [relationship isTransient] ) {
			continue;
		}

		if ([relationship isToMany]) {
			
			NSMutableArray *memberDictionaries = [NSMutableArray array];
			
			for (NSManagedObject *member in [self valueForKey:key]) {
				[memberDictionaries addObject: [member dictionaryRepresentationWithOptions: options visitedObjects: visitedObjects]];
			}
			
			[representation setObject: memberDictionaries forKey:key];
			
		} else {
			id value = [self valueForKey: key];

			if( nil != value ) {
				[representation setObject: [value dictionaryRepresentationWithOptions: options visitedObjects: visitedObjects] forKey:key];
			}
		}
	}
		
	return representation;
}

+ (NSArray *) dictionaryRepresentationsOfObjects: (NSArray *) objects options: (NSDictionary *) options
{
	NSMutableSet *visitedObjects = [NSMutableSet set];
	NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity: [objects count]];
	for(NSManagedObject *sourceObject in objects) {
		 [dictionaries addObject: [sourceObject dictionaryRepresentationWithOptions: options visitedObjects: visitedObjects]];
	}
	
	if( lpkswitch("dictionaryRepresentationDump", "dumping") ) {
		[dictionaries writeToFile: @"/tmp/dictionaryRepresentation.plist" atomically: YES];
	}
	
	return dictionaries;
}

+ (NSDictionary *) applyProcessors: (NSArray *) processors toDictionary: (NSDictionary *) entityDictionary options: (NSDictionary *) options depth: (NSInteger) depth
{
		NSMutableDictionary *mutableEntityDictionary = [NSMutableDictionary dictionaryWithDictionary: entityDictionary];
		for(ObjectExchangeDictionaryProcessor processor in processors) {
			processor( mutableEntityDictionary, options, depth );
		}
		return mutableEntityDictionary;
}

+ (NSManagedObject *) applyProcessors: (NSArray *) processors toObject: (NSManagedObject *) object options: (NSDictionary *) options depth: (NSInteger) depth
{
	for(ObjectExchangeObjectProcessor processor in processors) {
		processor( object, options, depth );
	}
	return object;
}

+ (NSString *) fetchRequestNameForReusableObject
{
	return nil;
}


// override this method to supply a fetch request to look for reusable objects
+ (NSFetchRequest *) fetchRequestForReusableObjectWithProperties: (NSDictionary *) properties inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext
{
	NSString *fetchRequestName = [self fetchRequestNameForReusableObject];

	if( nil == fetchRequestName ) {
		return nil;
	}
	
	NSFetchRequest *fetchRequest = 
	[[[managedObjectContext persistentStoreCoordinator] managedObjectModel] fetchRequestFromTemplateWithName: fetchRequestName substitutionVariables: properties];

	lpdebug(fetchRequest, properties);
	
	lpassertf(nil != fetchRequest, "model has no fetch request template named '%@'", fetchRequestName);
	
	return fetchRequest;
}

// slightly weird semantics: BOOL return signals success of LOOKING, not of FINDING - meaning that if the return value is NO, check outError
// check outObject for a matching object, guaranteed to be set to nil or an object if return value is YES
+ (BOOL) checkForReusableObject: (NSManagedObject **) outObject withProperties: (NSDictionary *) properties inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext error: (NSError **) outError
{
	NSFetchRequest *fetchRequest = [self fetchRequestForReusableObjectWithProperties: properties inManagedObjectContext: managedObjectContext];

	if( nil == fetchRequest ) {
		if( nil != outObject ) {
			*outObject = nil;
		}	
		return YES;		
	}
	
	NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error: outError];		
	
	if( nil == results ) {
		if( outError ) {
			lperror(*outError, (*outError).userInfo);
		}
		return NO;
	}
	
	id reusableObject = [results lastObject];
	
	lpdebug([reusableObject class], [reusableObject isDeleted]);
	
	if( nil != outObject ) {
		*outObject = reusableObject;
	}
	
	return YES;
}

+ (id) objectFromDictionaryRepresentation: (NSDictionary *) entityDictionary inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext options: (NSDictionary *) options error: (NSError **) outError depth: (NSInteger) depth collectedIDs: (NSMutableDictionary *) collectedIDs collectedRelations: (NSMutableDictionary *) collectedRelations
{
	NSString *objectIDReference = [entityDictionary valueForKey: kObjectExchangeDictionaryRepresentationObjectIDReferenceKey];

	if( nil != objectIDReference ) {
		return objectIDReference;
	}

	NSString *entityName = [entityDictionary valueForKey: kObjectExchangeDictionaryRepresentationEntityNameKey];

	CHECK_NSERROR_REASON_RETURN_NIL(nil != entityName, outError, NSPOSIXErrorDomain, EINVAL, @"errorNoEntityNameFieldInDictionaryRepresentation");

	// NSLog(@"creating %@ (%@)", entityName, [entityDictionary valueForKey: @"name"] ?: @"-");

	NSString *objectURIAsString = [entityDictionary valueForKey: kObjectExchangeDictionaryRepresentationObjectIDKey];

	// allow omission in plist files 
	//CHECK_NSERROR_REASON_RETURN_NIL(nil != objectURIAsString, outError, NSPOSIXErrorDomain, EINVAL, @"errorNoObjectIDFieldInDictionaryRepresentation");

	NSEntityDescription *entity = [NSEntityDescription entityForName: entityName inManagedObjectContext: managedObjectContext];
	
	CHECK_NSERROR_REASON_RETURN_NIL(nil != entity, outError, NSPOSIXErrorDomain, EINVAL, @"errorUnknownEntityNameInDictionaryRepresentation: %@", entityName);
		
	// we can't set relations to inserted objects on objects that have not yet been inserted
	// therefore we collect them and set them after the insertion
	NSMutableDictionary *relations = [NSMutableDictionary dictionary];
	
	NSArray *preprocessors = [options valueForKey: kObjectExchangeDictionaryProcessors];
	
	if( preprocessors ) {
		entityDictionary = [self applyProcessors: preprocessors toDictionary: entityDictionary options: options depth: depth];
	}

	NSManagedObject *newObject = nil;
	
	Class entityClass = NSClassFromString( [entity managedObjectClassName] );
	
	if( NO == [entityClass checkForReusableObject: &newObject withProperties: entityDictionary inManagedObjectContext: managedObjectContext error: outError] ) {
		return nil; // check failed with an error 
	}
	
	if( nil != newObject ) { // found a reusable one
		// must be able to reinstantiate symbolic references to reused objects, see note at end of method
		[collectedIDs setObject: newObject forKey: objectURIAsString ? (id)objectURIAsString : (id)[newObject objectID]];
		
		
		return newObject;
	}
		
	newObject = [[[NSManagedObject alloc] initWithEntity: entity insertIntoManagedObjectContext: nil] autorelease];
	
	CHECK_NSERROR_REASON_RETURN_NIL(nil != newObject, outError, NSPOSIXErrorDomain, ENOTSUP, @"errorCantCreateNewObjectForEntity: %@", entityName);
	
	id nsnull = [NSNull null];
		
	for( NSString *key in entityDictionary ) {
		if( [key hasPrefix: kObjectExchangeDictionaryRepresentationReservedKeyPrefix] ) {
			continue;
		}
		
		id value = [entityDictionary valueForKey: key];
		
		if( nsnull == value ) {
			value = nil;
		}
		
		if( [value isKindOfClass: [NSArray class]] ) {

			NSMutableSet *relatedObjects = [NSMutableSet set];

			for( NSDictionary *relatedDictionary in (NSArray *) value ) {
				NSManagedObject *related = [self objectFromDictionaryRepresentation: relatedDictionary inManagedObjectContext: managedObjectContext options: options error: outError depth: depth + 1 collectedIDs: collectedIDs collectedRelations: collectedRelations];
				if( nil == related ) {
					return NO;
				}
							
				[relatedObjects addObject: related];
			}

			[relations setObject: relatedObjects forKey: key];	

		} else {
			if( [value isKindOfClass: [NSDictionary class]] && ( [value valueForKey: kObjectExchangeDictionaryRepresentationEntityNameKey] || [value valueForKey: kObjectExchangeDictionaryRepresentationObjectIDReferenceKey] ) ) {
					NSManagedObject *related = [self objectFromDictionaryRepresentation: value inManagedObjectContext: managedObjectContext options: options error: outError depth: depth + 1 collectedIDs: collectedIDs collectedRelations: collectedRelations];

					if( nil == related ) {
						return NO;
					}	

					[relations setObject: related forKey: key];	

			} else {
					[newObject setValue: value forKey: key];
			}
		}
	}
	
	[managedObjectContext insertObject: newObject];

	// we use collectedIDs to reconnect references and to postprocess all created objects, 
	// therefore we use another kind of reference (for non-clashing namespaces) if there 
	// was none in the dictionary representation	
	[collectedIDs setObject: newObject forKey: objectURIAsString ? (id)objectURIAsString : (id)[newObject objectID]];
	
	[collectedRelations setObject: relations forKey: [newObject objectID]];

	return newObject;
}

+ (id) objectFromDictionaryRepresentation: (NSDictionary *) entityDictionary inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext options: (NSDictionary *) options error: (NSError **) outError
{
	// implemented in terms of objectsFromDictionaryRepresentations: to keep the surrounding logic in one place
	NSArray *newObjects = [self objectsFromDictionaryRepresentations: [NSArray arrayWithObject: entityDictionary] inManagedObjectContext: managedObjectContext options: options error: outError];
	return [newObjects lastObject]; // nil if newObjects is nil
}

+ (NSArray *) objectsFromDictionaryRepresentations: (NSArray *) entityDictionaries inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext options: (NSDictionary *) options error: (NSError **) outError
{
	NSMutableDictionary *collectedIDs = [NSMutableDictionary dictionary];
	NSMutableDictionary *collectedRelations = [NSMutableDictionary dictionary];

	NSMutableArray *newObjects = [NSMutableArray arrayWithCapacity: [entityDictionaries count]];
	for(NSDictionary *dictionary in entityDictionaries) {

		id newOne = [self objectFromDictionaryRepresentation: dictionary inManagedObjectContext: managedObjectContext options: options error: outError depth: 0 collectedIDs: collectedIDs collectedRelations: collectedRelations];
		if( nil == newOne ) {
			return nil;
		} else {
			[newObjects addObject: newOne];
		}
	}

	//NSLog(@"IDs: %@", [collectedIDs allKeys]);

	for( NSManagedObjectID *oid in collectedRelations ) {
		NSManagedObject *object = [managedObjectContext objectWithID: oid];

		NSAssert(object != nil, @"object in collectedRelations not found in managedObjectContext");

		NSDictionary *objectRelations = [collectedRelations objectForKey: oid];

		for( NSString *key in objectRelations ) {

			id value = [objectRelations objectForKey: key];
			
			//NSLog(@"%@ value  in: %@", key, [value class]);
			
			id (^dereferencer)(id relationValue) = ^(id relationValue){
				if([relationValue isKindOfClass: [NSString class]]) {
					id referencedObject = [collectedIDs valueForKey: relationValue];
					//NSLog(@"deref %@ to %@", relationValue, [referencedObject class]);
					NSAssert( referencedObject != nil, @"object reference not found in collectedIDs");
					relationValue = referencedObject;
				} 
				
				return relationValue;
			};
			
			if( [value isKindOfClass: [NSSet class]] ) {
				NSMutableSet *setValue = [NSMutableSet set];
				for( id member in value ) {
					[setValue addObject: dereferencer(member)];
				}
				value = setValue;
			} else {
				value = dereferencer(value);
			}
			
			//NSLog(@"%@ value  out: %@", key, [value class]);
			
			[object setValue: value forKey: key];
		}
	}

	NSArray *postprocessors = [options valueForKey: kObjectExchangeObjectProcessors];

	if( postprocessors ) {
		for( id obj in [collectedIDs allValues] ) {
			[self applyProcessors: postprocessors toObject: obj options: options depth: 0];
		}
	}

	[managedObjectContext processPendingChanges];

	return newObjects;
}

#if 0 
// BK: currently retired, needs reimplementation using pasteboard/arraycontroller or duplicated name / viewPosition support
+ (NSArray *) duplicateObjects: (NSArray *) objects inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext options: (NSDictionary *) options error: (NSError **) outError
{
	NSArray *dictionaries = [self dictionaryRepresentationsOfObjects: objects options: options];
	return [self objectsFromDictionaryRepresentations: dictionaries inManagedObjectContext: managedObjectContext options: options error: outError];
}
#endif

@end
