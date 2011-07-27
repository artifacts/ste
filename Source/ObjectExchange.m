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

#import "ObjectExchange.h"

#import "Convenience_Macros.h"

@implementation ObjectExchange

NSString *kObjectExchangeDictionaryRepresentationEntityNameKey = @"#entityName";
NSString *kObjectExchangeDictionaryRepresentationObjectIDKey = @"#id";
NSString *kObjectExchangeDictionaryRepresentationObjectIDReferenceKey = @"#idref";
NSString *kObjectExchangeDictionaryRepresentationReservedKeyPrefix = @"#";

NSString *kObjectExchangeRepresentationIndexes = @"indexes";
NSString *kObjectExchangeRepresentationDictionaries = @"dictionaries";

NSString *kObjectExchangeViewPositionKeyPath = @"kObjectExchangeViewPositionKeyPath";
NSString *kObjectExchangeNameToChangeOnCopyKeyPath = @"kObjectExchangeNameToChangeOnCopyKeyPath";
NSString *kObjectExchangeBaseUTI = @"kObjectExchangeBaseUTI";
NSString *kObjectExchangeEntityName = @"kObjectExchangeEntityName";
NSString *kObjectExchangeVariantName = @"kObjectExchangeVariantName";
//NSString *kObjectExchangeSubKeyPath = @"kObjectExchangeSubKeyPath";
NSString *kObjectExchangeRepresentation = @"kObjectExchangeRepresentation";
NSString *kObjectExchangeIndexesUTI = @"kObjectExchangeIndexesUTI";
NSString *kObjectExchangeDictionariesUTI = @"kObjectExchangeDictionariesUTI";
NSString *kObjectExchangeContext = @"kObjectExchangeContext";
NSString *kObjectExchangeDictionaryProcessors = @"kObjectExchangeDictionaryProcessors";
NSString *kObjectExchangeObjectProcessors = @"kObjectExchangeObjectProcessors";

+ (NSArray *) UTIsWithOptions: (NSDictionary *) options
{
	return [NSArray arrayWithObjects: 
		[self UTIForRepresentation: kObjectExchangeRepresentationIndexes options: options],
		[self UTIForRepresentation: kObjectExchangeRepresentationDictionaries options: options],
		nil];
}

+ (NSString *) UTIForRepresentation: (NSString *) type options: (NSDictionary *) options
{
	NSString *typeUTI = type ? [options valueForKey: type] : nil;

	if( typeUTI ) {
		return typeUTI;
	}

	NSString *baseUTI = [options valueForKey: kObjectExchangeBaseUTI];
	if( nil == baseUTI ) {
		baseUTI = [[NSBundle mainBundle] bundleIdentifier];
	}

	NSString *entityName = [options valueForKey: kObjectExchangeEntityName];

	NSString *entityUTI = entityName ? [baseUTI stringByAppendingPathExtension: entityName] : baseUTI;

	NSString *variant = [options valueForKey: kObjectExchangeVariantName];

	if( nil != variant ) {
		entityUTI = [entityUTI stringByAppendingPathExtension: variant];
	}

	return type ? [entityUTI stringByAppendingPathExtension: type] : entityUTI;
}

+ (BOOL) writeDictionaries: (NSArray *) dictionaries indexes: (NSIndexSet *) indexes toPasteboard: (NSPasteboard *) pboard options: (NSDictionary *) options
{
	if( nil == pboard ) {
		pboard = [NSPasteboard generalPasteboard];
	}

	NSMutableArray *types = [NSMutableArray arrayWithCapacity: 2];
	
	NSString *dictionariesUTI = nil;
	NSString *indexesUTI = nil;
	
	if( nil != indexes ) {
		indexesUTI = [self UTIForRepresentation: kObjectExchangeRepresentationIndexes options: options];
		[types addObject: indexesUTI];
	}
	
	if( nil != dictionaries ) {
		dictionariesUTI = [self UTIForRepresentation: kObjectExchangeRepresentationDictionaries options: options];
		[types addObject: dictionariesUTI];
	}
	
	if( 0 == [types count] ) {
		return NO;
	}
	
	[pboard declareTypes: types owner: nil];

	if( nil != indexes ) {
		[pboard setData: [NSKeyedArchiver archivedDataWithRootObject: indexes] forType: indexesUTI]; 
	}

	if( nil != dictionaries ) {
		[pboard setPropertyList: dictionaries forType: dictionariesUTI]; 
	}
	
	return YES;
}

+ (NSIndexSet *) indexesFromPasteboard: (NSPasteboard *) pboard options: (NSDictionary *) options error: (NSError **) outError
{
	if( nil == pboard ) {
		pboard = [NSPasteboard generalPasteboard];
	}
	
	NSString *UTI = [self UTIForRepresentation: kObjectExchangeRepresentationIndexes options: options];

	NSString *type = [pboard availableTypeFromArray: [NSArray arrayWithObject: UTI]];

	CHECK_NSERROR_REASON_RETURN_NIL(nil != type, outError, NSPOSIXErrorDomain, EINVAL, @"errorDragOperationWithoutAppropriateIndexesOnPasteboard");

	NSData *pboardData = [pboard dataForType: type];

	CHECK_NSERROR_REASON_RETURN_NIL(nil != pboardData, outError, NSPOSIXErrorDomain, EINVAL, @"errorDragOperationWithoutDeclaredIndexesOnPasteboard");
	
	return [NSKeyedUnarchiver unarchiveObjectWithData: pboardData];
}

+ (NSArray *) dictionariesFromPasteboard: (NSPasteboard *) pboard options: (NSDictionary *) options error: (NSError **) outError
{
	if( nil == pboard ) {
		pboard = [NSPasteboard generalPasteboard];
	}

	NSString *UTI = [self UTIForRepresentation: kObjectExchangeRepresentationDictionaries options: options];

	NSString *type = [pboard availableTypeFromArray: [NSArray arrayWithObject: UTI]];

	CHECK_NSERROR_REASON_RETURN_NIL(nil != type, outError, NSPOSIXErrorDomain, EINVAL, @"errorNoAppropriateDictionariesOnPasteboard");

	NSArray *dictionaries = [pboard propertyListForType: type];

	CHECK_NSERROR_REASON_RETURN_NIL(nil != dictionaries, outError, NSPOSIXErrorDomain, EINVAL, @"errorNoDictionariesForDeclaredTypeOnPasteboard");
	
	return dictionaries;
}


@end
