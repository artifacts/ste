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

#import <Cocoa/Cocoa.h>

extern NSString *kObjectExchangeDictionaryRepresentationEntityNameKey;
extern NSString *kObjectExchangeDictionaryRepresentationObjectIDKey;
extern NSString *kObjectExchangeDictionaryRepresentationObjectIDReferenceKey;
extern NSString *kObjectExchangeDictionaryRepresentationReservedKeyPrefix;

extern NSString *kObjectExchangeTypeIndexes;
extern NSString *kObjectExchangeTypeDictionaries;

extern NSString *kObjectExchangeViewPositionKeyPath;
extern NSString *kObjectExchangeNameToChangeOnCopyKeyPath;
extern NSString *kObjectExchangeBaseUTI;
extern NSString *kObjectExchangeEntityName;
extern NSString *kObjectExchangeVariantName;
//extern NSString *kObjectExchangeSubKeyPath;
extern NSString *kObjectExchangeRepresentationType;
extern NSString *kObjectExchangeIndexesUTI;
extern NSString *kObjectExchangeDictionariesUTI;
extern NSString *kObjectExchangeContext;

// underdeveloped feature, internal use only
extern NSString *kObjectExchangeDictionaryProcessors;
extern NSString *kObjectExchangeObjectProcessors;

typedef void (^ObjectExchangeDictionaryProcessor)(NSMutableDictionary *dict, NSDictionary *options, NSInteger depth);
typedef void (^ObjectExchangeObjectProcessor)(NSManagedObject *obj, NSDictionary *options, NSInteger depth);

@interface ObjectExchange : NSObject 
{

}

+ (NSArray *) UTIsWithOptions: (NSDictionary *) options;

+ (NSString *) UTIForRepresentation: (NSString *) type options: (NSDictionary *) options;

+ (BOOL) writeDictionaries: (NSArray *) dictionaries indexes: (NSIndexSet *) indexes toPasteboard: (NSPasteboard *) pasteboard options: (NSDictionary *) options;


+ (NSIndexSet *) indexesFromPasteboard: (NSPasteboard *) pboard options: (NSDictionary *) options error: (NSError **) outError;
+ (NSArray *) dictionariesFromPasteboard: (NSPasteboard *) pboard options: (NSDictionary *) options error: (NSError **) outError;




@end
