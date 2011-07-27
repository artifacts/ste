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

#import "StageMigrationPolicy.h"
#import "DocumentSettingsMO.h"

@implementation StageMigrationPolicy

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
	NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName] inManagedObjectContext:[manager destinationContext]];			

	[StageMO ensureDocumentSettingsExistForEntity:(StageMO*)newObject inManagedObjectContext:[manager destinationContext]];
	
	// copy the rest
	[newObject setValue:[sInstance valueForKey:@"name"] forKey:@"name"];
	[newObject setValue:[sInstance valueForKey:@"width"] forKey:@"width"];
	[newObject setValue:[sInstance valueForKey:@"height"] forKey:@"height"];
	
	if ([sInstance respondsToSelector:NSSelectorFromString(@"gravity")]) {
		[newObject setValue:[sInstance valueForKey:@"gravity"] forKey:@"gravity"];
	} else {
		[newObject setValue:[NSNumber numberWithFloat:9.81] forKey:@"gravity"];
	}

	if ([sInstance respondsToSelector:NSSelectorFromString(@"physicsEnabled")]) {
		[newObject setValue:[sInstance valueForKey:@"physicsEnabled"] forKey:@"physicsEnabled"];
	} else {
		[newObject setValue:[NSNumber numberWithBool:NO] forKey:@"physicsEnabled"];
	}

	if ([sInstance respondsToSelector:NSSelectorFromString(@"userInteractionEnabled")]) {
		[newObject setValue:[sInstance valueForKey:@"userInteractionEnabled"] forKey:@"userInteractionEnabled"];
	} else {
		[newObject setValue:[NSNumber numberWithBool:NO] forKey:@"userInteractionEnabled"];
	}	
	
	[manager associateSourceInstance:sInstance withDestinationInstance:newObject forEntityMapping:mapping];
	
	return YES;
}

@end
