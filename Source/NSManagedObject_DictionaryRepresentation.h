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

@interface NSManagedObject( DictionaryRepresentation ) 

+ (BOOL) writeObjects: (NSArray *) objects atIndexes: (NSIndexSet *) indexes toPasteboard: (NSPasteboard *) pasteboard options: (NSDictionary *) options;

+ (NSArray *) objectsFromPasteboard: (NSPasteboard *) pboard managedObjectContext: (NSManagedObjectContext *) managedObjectContext options: (NSDictionary *) options error: (NSError **) outError;

- (NSDictionary *) dictionaryRepresentationWithOptions: (NSDictionary *) options;
- (NSDictionary *) dictionaryRepresentationWithOptions: (NSDictionary *) options visitedObjects: (NSMutableSet *) visitedObjects;

+ (NSArray *) dictionaryRepresentationsOfObjects: (NSArray *) objects options: (NSDictionary *) options;

+ (NSString *) fetchRequestNameForReusableObject;
+ (NSFetchRequest *) fetchRequestForReusableObjectWithProperties: (NSDictionary *) properties inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext;

// slightly weird semantics: BOOL return signals success of LOOKING, not of FINDING - meaning that if the return value is NO, check outError
// check outObject for a matching object, guaranteed to be set to nil or an object if return value is YES
+ (BOOL) checkForReusableObject: (NSManagedObject **) outObject withProperties: (NSDictionary *) properties inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext error: (NSError **) outError;


+ (id) objectFromDictionaryRepresentation: (NSDictionary *) entityDictionary inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext options: (NSDictionary *) options error: (NSError **) outError;
+ (NSArray *) objectsFromDictionaryRepresentations: (NSArray *) entityDictionaries inManagedObjectContext: (NSManagedObjectContext *) managedObjectContext options: (NSDictionary *) options error: (NSError **) outError;

@end
