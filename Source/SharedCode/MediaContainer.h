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

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <CoreServices/CoreServices.h>

#define kMediaContainerRenderQualityOriginal 100

@class AFCache;
@class AFCacheableItem;

@interface MediaContainer : NSObject {
	NSData *m_data;

	AFCache	*m_cache;
	AFCacheableItem *m_cacheableItem;
	
	NSBitmapImageRep *m_bitmapImageRep;
	BOOL m_opaque;
	BOOL m_loaded;

	NSData *m_renderedData;
	NSURL *m_renderedURL;
	NSString *m_renderedTypeIdentifier;
	NSBitmapImageRep *m_renderedBitmapImageRep;
	NSNumber *m_renderQuality;
	
	NSError *m_error;
	NSString *m_name;
	NSString *m_typeIdentifier;
	NSURL *m_URL;

	QTTime m_qtDuration;
}

@property (nonatomic, retain) AFCache *cache;
@property (nonatomic, retain) AFCacheableItem *cacheableItem;

@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain) NSBitmapImageRep *bitmapImageRep;

@property (nonatomic, assign, getter = isOpaque) BOOL opaque;
@property (nonatomic, assign, getter = isLoaded) BOOL loaded;

@property (nonatomic, retain, readonly) NSNumber *recommendedRenderQuality;

@property (nonatomic, retain, readonly ) NSNumber *doesRender;

@property (nonatomic, retain) NSData *renderedData;
@property (nonatomic, retain) NSURL *renderedURL;
@property (nonatomic, copy) NSString *renderedTypeIdentifier;
@property (nonatomic, retain) NSBitmapImageRep *renderedBitmapImageRep;
@property (nonatomic, retain) NSNumber *renderQuality;

@property (nonatomic, retain) NSError *error;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *typeIdentifier;
@property (nonatomic, retain) NSURL *URL;

@property (nonatomic, assign) QTTime qtDuration;

@property (nonatomic, assign, readonly) CGFloat width;
@property (nonatomic, assign, readonly) CGFloat height; 

- (id) initWithCache: (AFCache *) cache error: (NSError **) outError;


- (id)initWithURL: (NSURL *) URL cache: (AFCache *) cache error: (NSError **) outError;
- (id)initWithData:(NSData *)data cache: (AFCache *) cache error: (NSError **) outError;

- (BOOL) updateFromData: (NSData *) data error: (NSError **) outError;
- (BOOL) updateFromURL: (NSURL *) URL error: (NSError **) outError;

- (void) updateRenderings;

- (CGImageRef) renderedCGImage;

@end

@interface MediaContainer ( AFCacheDelegate )
- (void)connectionDidFinish:(AFCacheableItem *)cacheableItem;
- (void)connectionDidFail:(AFCacheableItem *)cacheableItem;
@end
