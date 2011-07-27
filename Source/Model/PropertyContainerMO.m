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

#import "PropertyContainerMO.h"
#import <EngineRoom/CrossPlatform_Utilities.h>
#import "BKColor.h"

id (^CGPointValueFromStringConverter)(id value) = ^ (id value) { return (id)[NSValue valueWithCGPoint: CGPointFromString(value)]; };
id (^CGRectValueFromStringConverter)(id value) = ^ (id value) { return (id)[NSValue valueWithCGRect: CGRectFromString(value)]; };
id (^BKColorFromGenericRGBAStringConverter)(id value) = ^ (id value) { return (id) [BKColor colorWithGenericRGBAString: value]; };

id (^StringFromCGPointValueConverter)(id value) = ^ (id value) { return (id) NSStringFromCGPoint( [value CGPointValue] ); };
id (^StringFromCGRectValueConverter)(id value) = ^ (id value) { return (id) NSStringFromCGRect( [value CGRectValue] ); };
id (^GenericRGBAStringFromBKColorConverter)(id value) = ^ (id value) { return (id)[value genericRGBAString]; };

@implementation PropertyContainerMO

@dynamic properties;
@dynamic persistentProperties;


NSMutableDictionary *ConvertDictionaryUsingValueConverters(NSDictionary *source, NSDictionary *valueConverters)
{
	NSMutableDictionary *converted = [NSMutableDictionary dictionaryWithCapacity: [source count]];

	[source enumerateKeysAndObjectsUsingBlock: ^ (id key, id value, BOOL *stop) {
		id (^converter)(id value) = [valueConverters objectForKey: key];
		[converted setObject: converter ? converter(value) : value forKey: key];			
	 }];
	
	return converted;
}

- (NSMutableDictionary *) propertiesFromPersistentProperties: (NSDictionary *) persistentProperties
{
	NSDictionary *converters = [NSDictionary dictionaryWithObjectsAndKeys:
		CGPointValueFromStringConverter, @"position",
		CGPointValueFromStringConverter, @"anchorPoint",
		CGRectValueFromStringConverter, @"bounds",
//		CGColorFromGenericRGBAStringConverter, @"backgroundColor",
		BKColorFromGenericRGBAStringConverter, @"backgroundColor",
	nil];


	
	NSMutableDictionary *nonPersistent = ConvertDictionaryUsingValueConverters(persistentProperties, converters);	

	//NSLog(@"%@ nonPersistent %@", self, nonPersistent);

	return nonPersistent;
}


- (NSDictionary *) persistentPropertiesFromProperties: (NSDictionary *) properties
{
	NSDictionary *converters = [NSDictionary dictionaryWithObjectsAndKeys:
		StringFromCGPointValueConverter, @"position",
		StringFromCGPointValueConverter, @"anchorPoint",
		StringFromCGRectValueConverter, @"bounds",
//		GenericRGBAStringFromCGColorConverter, @"backgroundColor",
		GenericRGBAStringFromBKColorConverter, @"backgroundColor",
	nil];
	
	NSDictionary *persistent = ConvertDictionaryUsingValueConverters(properties, converters);	
	
	//NSLog(@"%@ persistent %@", self, persistent);
	
	return persistent;
}

- (void) thawProperties
{
	NSMutableDictionary *properties = [self propertiesFromPersistentProperties: self.persistentProperties];

	// NSLog(@"%@ thawProperties: %@", [self class], properties);

    self.properties = properties;
}

- (void) freezeProperties
{
	NSDictionary *persistentProperties = [self persistentPropertiesFromProperties: self.properties];

	//NSLog(@"%@ freezeProperties: persistentProperties %@", [self class], persistentProperties);

    [self setPrimitiveValue: persistentProperties forKey: @"persistentProperties"];
}


- (void) awakeFromInsert
{
    [super awakeFromInsert];
	
	//NSLog(@"%@ awakeFromInsert", [self class]);
	
	[self thawProperties];
}

- (void) awakeFromFetch
{
    [super awakeFromFetch];

	//NSLog(@"%@ awakeFromFetch", [self class]);
	
	[self thawProperties];
}

- (void) willSave
{
	[self freezeProperties];
	[super willSave];
}

// forward unknown attributes to the property dictionary

- (void) setValue: (id) value forUndefinedKey: (NSString *)key
{

	//NSLog(@"setValue: %@ forKey: %@", value, key);

	NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary: self.properties];

	[properties setValue: value forKey: key];

	self.properties = properties;

	//NSLog(@"posting PropertiesAffected for %p", self);
	[[NSNotificationCenter defaultCenter] postNotificationName:	kModelAccessPropertiesAffectedNotification object: self];
}

- (id) valueForUndefinedKey: (NSString *)key
{
	return [self.properties valueForKey: key];
}

+ (NSMutableDictionary *) defaultProperties
{
	return [NSMutableDictionary dictionary];
}

@end
