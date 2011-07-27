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

#import "ExternalDataMO.h"
#import <AFCache/AFCacheLib.h>
#import <EngineRoom/tracer.h>
#import <EngineRoom/CrossPlatform_Utilities.h>

@interface ExternalDataMO (CoreDataGeneratedPrimitiveAccessors)

- (NSMutableSet*)primitiveAssets;
- (void)setPrimitiveAssets:(NSMutableSet*)value;

- (NSData *)primitiveRenderedData;
- (void)setPrimitiveRenderedData:(NSData *)value;

- (NSNumber *)primitiveRenderQuality;
- (void)setPrimitiveRenderQuality:(NSNumber *)value;

- (NSString *)primitiveExternalURL;
- (void)setPrimitiveExternalURL:(NSString *)value;

@end

@implementation ExternalDataMO

@dynamic assets;

@dynamic externalId;
@dynamic externalURL;

@dynamic contentType;

@dynamic cachedData;

// TODO: refactor
@dynamic viewPosition;
@dynamic keyName;

@synthesize mediaContainer = m_mediaContainer;

- (NSSet *) keysToExcludeFromDictionaryRepresentationInContext: (void *) context
{
	return [NSSet setWithObjects: @"assets", nil];
}

- (void) awakeMediaContainer
{
	AFCache *cache = [AFCache sharedInstance];
		
	MediaContainer *mediaContainer = nil;
	NSURL *URL = self.externalURL ? [NSURL URLWithString: self.externalURL] : nil;
	NSError *error = nil;

	if( self.cachedData ) {
		lpktrace("mediaContainer", "awake from data");
		mediaContainer = [[[MediaContainer alloc] initWithData: self.cachedData cache: cache error: &error] autorelease];
		if( nil != mediaContainer ) {
			lpktrace("mediaContainer", "awake from data ok");
			mediaContainer.renderQuality = self.renderQuality;
			
			if( NO == [mediaContainer updateFromURL: URL error: &error] ) {
				lpkerror("mediaContainer", "update failed", URL, error, error.userInfo);
			}
		}
	} else {
		lpktrace("mediaContainer", "awake from URL");
		mediaContainer = [[[MediaContainer alloc] initWithURL: URL cache: cache error: &error] autorelease];
	}

	self.mediaContainer = mediaContainer;

	if( nil == mediaContainer ) {
		lpkerror("mediaContainer", "init failed", error, error.userInfo);
	} else {
		if( nil != self.renderQuality ) {
			[mediaContainer setRenderQuality: self.renderQuality];
		}
	}

	lpkdebug("mediaContainer", URL, self.mediaContainer);
}

- (void) awakeFromInsert
{
	// awaking is done in setExternalURL
	[super awakeFromInsert];
}

- (void) awakeFromFetch
{
	[super awakeFromFetch];
	[self awakeMediaContainer];
}	

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
#define FlagString(x) (flags & (x) ? @#x " ": @"")
	[super awakeFromSnapshotEvents: flags];
	
	MediaContainer *mediaContainer = self.mediaContainer;
	
	lpkdebugf("undo,mediaContainer", "mediaContainer: %s cachedData: %s flags: %@%@%@%@%@%@",
			  mediaContainer ? "YES" : "NO",
			  self.cachedData ? "YES" : "NO",
			  FlagString(NSSnapshotEventUndoInsertion),
			  FlagString(NSSnapshotEventUndoDeletion),
			  FlagString(NSSnapshotEventUndoUpdate),
			  FlagString(NSSnapshotEventRollback),
			  FlagString(NSSnapshotEventRefresh),
			  FlagString(NSSnapshotEventMergePolicy)
			  );


#if 0
	if( flags & NSSnapshotEventUndoInsertion ) {
		[self performSelector: @selector(setMediaContainer:) withObject: nil afterDelay: 0.0];		  
	}
#endif

#if 0
	if( flags & NSSnapshotEventUndoDeletion ) {
		[self performSelector: @selector(awakeMediaContainer) withObject: nil afterDelay: 0.0];		  
	}
#endif
	
	if( flags & NSSnapshotEventUndoUpdate ) {
		NSNumber *renderQuality = self.renderQuality;
		lpkdebug("undo,mediaContainer", renderQuality, mediaContainer);
		mediaContainer.renderQuality = renderQuality;
	}
}


- (void) willSave
{
	[super willSave];
	
	// delete ExternalDataMOs with zero references 
	if( NO == [self isDeleted] && 0 == [self.assets count] ) {
		lptrace("deleting", self.externalURL);
		[self.managedObjectContext deleteObject: self];
	} 
}
	
- (void) willTurnIntoFault
{
	lpktrace("mediaContainer");

	// potentially dangerous - not guaranteed to work for future OS version
	//lpkdebug("mediaContainer", (id)[self observationInfo]);
	
        self.mediaContainer = nil;

	[super willTurnIntoFault];
}

- (void) didTurnIntoFault
{
	[super didTurnIntoFault];
}

- (NSNumber *) renderQuality
{
	[self willAccessValueForKey:@"renderQuality"];
	NSNumber *renderQuality = [self primitiveRenderQuality];
	
	if( nil == renderQuality ) {
		renderQuality = [NSNumber numberWithInteger: kMediaContainerRenderQualityOriginal];
	}
	
	[self didAccessValueForKey:@"renderQuality"];

	return renderQuality;
}

- (void)setRenderQuality:(NSNumber *) renderQuality
{
	[self willChangeValueForKey:@"renderQuality"];
    [self setPrimitiveRenderQuality: renderQuality];
	lpktrace("mediaContainer", renderQuality);
	self.mediaContainer.renderQuality = renderQuality; 
	[self didChangeValueForKey:@"renderQuality"];
}

- (void)setExternalURL:(NSString *) URLString 
{
    [self willChangeValueForKey:@"externalURL"];
    [self setPrimitiveExternalURL: URLString];
	lptrace(URLString);
	
	if( nil == self.mediaContainer ) {
		[self awakeMediaContainer];
	} else {
		NSError *error = nil;
		if( NO == [self.mediaContainer updateFromURL: [NSURL URLWithString: URLString] error: &error] ) {
			lperror(error, error.userInfo);
			[NSApp presentError: error];
		}
	}

	[self didChangeValueForKey:@"externalURL"];
}

// core data disables auto-notify, we observe mediaContainers data to keep cachedData in sync
- (void) setMediaContainer: (MediaContainer *) mediaContainer
{
	[self willChangeValueForKey: @"mediaContainer"];

	if( m_mediaContainer ) {
			[self removeObserver: self forKeyPath: @"mediaContainer.data"];			
			[m_mediaContainer autorelease];
	}

	lpkdebug("mediaContainer", [m_mediaContainer observationInfo]);

	
	m_mediaContainer = [mediaContainer retain];

	if( m_mediaContainer ) {
		[self addObserver: self forKeyPath: @"mediaContainer.data" options: NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context: nil];
	}
		
	[self didChangeValueForKey: @"mediaContainer"];
}

// the MediaContainer has a life of its own - we need to track the image data to save it
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if( [keyPath isEqualToString: @"mediaContainer.data"] ) {
		NSData *newData = self.mediaContainer.data;
		lpkdebug("mediaContainer", [newData length]);
		
		if( nil != newData ) {

			if( YES == self.mediaContainer.loaded ) {
				if( nil == self.cachedData ) {
					// first load: determine default quality
					NSNumber *recommendedRenderQuality = [self.mediaContainer recommendedRenderQuality];
					self.renderQuality = recommendedRenderQuality;
					lpkdebug("mediaContainer", recommendedRenderQuality);
				}
			}
						
			self.cachedData = newData;

		}
	
		return;
	}
	
	[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

+ (NSString *) fetchRequestNameForReusableObject
{
	return @"ReusableExternalData";
}

+ (NSSet *) keyPathsForValuesAffectingDataSize
{ 
return [NSSet setWithObjects: @"mediaContainer.data", nil];
}

- (NSInteger) dataSize
{
return [self.mediaContainer.data length];
}

+ (NSSet *) keyPathsForValuesAffectingRenderedDataSize
{ 
return [NSSet setWithObjects: @"mediaContainer.renderedData", nil];
}

- (NSInteger) renderedDataSize
{
return [self.mediaContainer.renderedData length];
}



@end
