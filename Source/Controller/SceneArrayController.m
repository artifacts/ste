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

#import "SceneArrayController.h"

#import "SceneMO.h"
#import "TransitionMO.h"


@implementation SceneArrayController

#pragma mark -
#pragma mark Initialization & Deallocation

- (id)initWithCoder:(NSCoder *)aCoder{
	if (self = [super initWithCoder:aCoder]){
		[self setSortDescriptors:[NSArray arrayWithObject:
			[NSSortDescriptor sortDescriptorWithKey:@"viewPosition" ascending:YES]]];
	}
	return self;
}

#pragma mark -
#pragma mark NSArrayController methods

- (id)newObject{
	SceneMO *scene = (SceneMO *)[super newObject];
	NSInteger nextPos = [[self arrangedObjects] count];
	[scene setName:[NSString stringWithFormat:@"Neue Szene %d", nextPos]];
	[scene setViewPosition:[NSNumber numberWithInt:nextPos]];
	
	NSManagedObjectContext *ctx = [self managedObjectContext];
	NSManagedObjectModel *model = [[ctx persistentStoreCoordinator] managedObjectModel];
	NSEntityDescription *entity = [[model entitiesByName] objectForKey:@"Transition"];
	
	TransitionMO *transition = [[NSManagedObject alloc] initWithEntity:entity 
		insertIntoManagedObjectContext:ctx];
	[scene setValue:transition forKey:@"transitionToNext"];
	[transition release];
	
	return scene;
}

@end
