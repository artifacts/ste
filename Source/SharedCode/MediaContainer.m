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

#import "MediaContainer.h"

#import <EngineRoom/Convenience.h>
#import <EngineRoom/tracer.h>

#import <AFCache/AFCacheLib.h>
#import "Constants.h"
#import "NSData+md5.h"

BOOL IsCGImageOpaque(CGImageRef cgImage);

@interface MediaContainer ()
- (BOOL) _readFromImageData: (NSData *) data error: (NSError **) outError;
- (BOOL) _readFromMovieData: (NSData *) data error: (NSError **) outError;
@end

@implementation MediaContainer

@synthesize cache = m_cache;
@synthesize cacheableItem = m_cacheableItem;

@synthesize data = m_data;
@synthesize bitmapImageRep = m_bitmapImageRep;
@synthesize opaque = m_opaque;
@synthesize loaded = m_loaded;

@synthesize renderQuality = m_renderQuality;
@synthesize renderedData = m_renderedData;
@synthesize renderedBitmapImageRep = m_renderedBitmapImageRep;
@synthesize renderedTypeIdentifier = m_renderedTypeIdentifier;
@synthesize renderedURL = m_renderedURL;

@synthesize error = m_error;
@synthesize name = m_name;
@synthesize typeIdentifier = m_typeIdentifier;
@synthesize URL = m_URL;

@synthesize qtDuration = m_qtDuration;

+ (NSDictionary *) keyPathDependencies 
{
	return ER_DICT(
				   @"renderedCGImage",				ER_SET( @"renderedBitmapImageRep" ),
				   @"renderedURL",					ER_SET( @"URL", @"renderQuality" ),

				   @"doesRender",					ER_SET( @"renderQuality" ),

				   @"recommendedRenderQuality",		ER_SET( @"opaque" ),

				   @"width",						ER_SET( @"bitmapImageRep" ),
   				   @"height",						ER_SET( @"bitmapImageRep" )
				   );
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	static NSDictionary *dependencies = nil;

	if( nil == dependencies ) {
		dependencies =  [[self keyPathDependencies] retain];
	}
	
	NSSet *superKeyPaths = [super keyPathsForValuesAffectingValueForKey: key];
	
	NSSet *keyPaths = [dependencies objectForKey: key];

	NSSet *finalKeyPaths = ( nil == keyPaths ) ? superKeyPaths : [superKeyPaths count] ? [superKeyPaths setByAddingObjectsFromSet: keyPaths] : keyPaths;
	
	lpdebug(key, finalKeyPaths);
	
	return finalKeyPaths;
}

- (id) initWithCache: (AFCache *) cache error: (NSError **) outError
{
	if( ( self = [super init] ) ) {
		self.renderQuality = [NSNumber numberWithInteger: kMediaContainerRenderQualityOriginal];		
		self.qtDuration = QTZeroTime;
		self.cache = cache;
		self.opaque = NO;
		
		lpkdebugf("creation,backtrace", "\n%@", tracerBacktraceAsString(0));
	}
	
	ER_CHECK_NSERROR_REASON_RETURN_NIL( self != nil, outError, NSPOSIXErrorDomain, ENOMEM, @"errorAllocationFailure");	
	
	return self;
}

- (id)initWithData:(NSData *)data cache: (AFCache *) cache error: (NSError **) outError
{
	if( ( self = [self initWithCache: cache error: outError] ) ) {
		if( NO == [self updateFromData: data error: outError] ) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (id)initWithURL: (NSURL *) URL cache: (AFCache *) cache error: (NSError **) outError 
{
	if( ( self = [self initWithCache: cache error: outError] ) ) {
		if( NO == [self updateFromURL: URL error: outError] ) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (BOOL) updateFromCacheableItem: (AFCacheableItem *) item error: (NSError **) outError
{
	lpdebug(item.info.mimeType);
	return [self updateFromData: item.data error: outError];
}

- (BOOL) updateFromURL: (NSURL *) URL error: (NSError **) outError 
{
	if( nil == URL ) { 
		ER_SET_NSERROR_REASON(outError, NSPOSIXErrorDomain, EINVAL, @"errorURLIsNil");	
		self.URL = nil;
		[self updateFromData: nil error: nil]; // reset
		return NO;
	}
	
	BOOL success = NO;
	
	if( self.cache ) {
		
		self.cacheableItem = [self.cache cachedObjectForURL: URL 
												   delegate:self 
												   selector:@selector(connectionDidFinish:) 
											didFailSelector:@selector(connectionDidFail:) 
													options: 0];
		
		success = YES;
		
		if( self.cacheableItem.data ) {
			success = [self updateFromCacheableItem: self.cacheableItem error: outError];
		}
		
	} else {
		NSData *data = [NSData dataWithContentsOfURL: URL options: NSDataReadingMapped error: outError];

		success = [self updateFromData: data error: data ? outError : nil]; // just reset on fail 
	}
	
	self.URL = URL;
	
	return success;
}

- (BOOL) updateFromData: (NSData *) newData error: (NSError **) outError 
{
	ER_CHECK_NSERROR_REASON_RETURN_NO(newData != nil, outError, NSPOSIXErrorDomain, EINVAL, @"errorDataIsNil");
	
	if( YES == [self.data isEqualToData: newData] ) {
		lpdebug("data is equal to current data - ignoring and returning success");
		return YES;
	}
	
	if( [self _readFromImageData: newData error: outError] || [self _readFromMovieData: newData error: outError] ) {
		self.data = newData;		
	} else {
		self.data = nil;
	}
	
	[self updateRenderings];
	
	return self.data ? YES : NO;
}
	
- (NSNumber *) recommendedRenderQuality
{
	NSNumber *defaultRenderQuality = [[NSUserDefaults standardUserDefaults] objectForKey: kSTEDefaultRenderQuality];

	return self.opaque ? defaultRenderQuality : [NSNumber numberWithInteger: kMediaContainerRenderQualityOriginal];
}
 
- (CGFloat) width	{ NSBitmapImageRep *bitmapImageRep = self.bitmapImageRep; return bitmapImageRep ? bitmapImageRep.size.width : 0.0; }

- (CGFloat) height	{ NSBitmapImageRep *bitmapImageRep = self.bitmapImageRep; return bitmapImageRep ? bitmapImageRep.size.height : 0.0; }


- (BOOL) opaquenessOfBitmapImageRep: (NSBitmapImageRep *) imageRep
{
	BOOL opaque = NO;
	
	if( NO == [imageRep hasAlpha] || YES == [imageRep isOpaque] ) {
		opaque = YES;
		lpkdebug("imageTesting", "fast", opaque);
	} else {
		CGImageRef cgImage = [imageRep CGImage];
		opaque = IsCGImageOpaque( cgImage );
		lpkdebug("imageTesting", "slow", opaque);
	}
	
	return opaque;
}
	
- (BOOL) _readFromImageData: (NSData *) data error: (NSError **) outError
{
	NSImage *image = [[[NSImage alloc] initWithData: data] autorelease];
	NSRect imageRect = image ? (NSRect){NSZeroPoint, [image size]} : NSZeroRect;
	
	NSBitmapImageRep *imageRep = (NSBitmapImageRep *) [image bestRepresentationForRect: imageRect context: nil hints: nil];

	lptrace(imageRep);

	ER_CHECK_NSERROR_REASON_RETURN_NO(nil != imageRep, outError, NSPOSIXErrorDomain, EINVAL, @"errorCantInitImageWithData");
	
	ER_CHECK_NSERROR_REASON_RETURN_NO([imageRep isKindOfClass: [NSBitmapImageRep class]], outError, NSPOSIXErrorDomain, EINVAL, @"errorCantInitImageWithNonBitmapData");

	self.opaque = [self opaquenessOfBitmapImageRep: imageRep];
	self.loaded = YES;
	
	self.bitmapImageRep = imageRep;

	self.typeIdentifier = (id)kUTTypeImage;
	
	return YES;
}


// see "QTMovie object not fully-formed?" regarding movie initialization
// http://developer.apple.com/library/mac/#technotes/tn2005/tn2138.html
// days:hours:minutes:seconds.frames/timescale".
// QTTime time = QTTimeFromString(@"0:0:0:1:0/600");

- (BOOL) _readFromMovieData: (NSData *) data error: (NSError **) outError
{
	NSDictionary *attrs = ER_DICT( QTMovieDataAttribute, data, QTMovieOpenAsyncOKAttribute, ER_NUMBER_NO ); 
	
	QTMovie *movie = [QTMovie movieWithAttributes:attrs error:outError];                              
	
	if (movie == nil) {
		return NO;
	}
	
	NSImage *posterImage = [movie posterImage];
	
	if( nil == posterImage ) {
		posterImage = [movie currentFrameImage];
	}
	
	NSBitmapImageRep *imageRep = nil;
	
	if( nil != posterImage && [[posterImage representations] count] ) {
		imageRep = [[posterImage representations] objectAtIndex: 0];
	}
	
	self.error = nil;
	self.data = data;
	self.typeIdentifier = (id)kUTTypeVideo;
	self.bitmapImageRep = imageRep;
	
	return YES;
}

- (NSNumber *) doesRender
{
	return [NSNumber numberWithBool: kMediaContainerRenderQualityOriginal == [self.renderQuality integerValue] ? NO : YES];
}

- (NSURL *) renderedURL
{
	if( NO == [self.doesRender boolValue] ) {
		return self.URL;
	}
	
	NSString *encodedURLString = [[self.URL absoluteString] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    NSString *paramURL = @"";
    if (encodedURLString != nil) {
        paramURL = [[NSString stringWithFormat:@"url=%@", encodedURLString] md5];
    }
    
	NSString *mediaContainerURLString = [NSString stringWithFormat: @"mediaContainer://%@?%@&quality=%@&hash=%@.jpg", // %08lx.jpg", 
											 [[NSBundle bundleForClass: [self class]] bundleIdentifier], paramURL, self.renderQuality, (unsigned long)[self.renderedData md5]];
	
	NSString *fileName = [mediaContainerURLString stringByReplacingOccurrencesOfString: @"%" withString: @"_"];
	fileName = [fileName stringByReplacingOccurrencesOfString: @"?" withString: @"_"];
	fileName = [fileName stringByReplacingOccurrencesOfString: @"&" withString: @"_"];
	fileName = [fileName stringByReplacingOccurrencesOfString: @":" withString: @"_"];	
	fileName = [fileName stringByReplacingOccurrencesOfString: @"/" withString: @"_"];
	
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent: fileName];
	
	NSURL *renderedURL = [NSURL fileURLWithPath: filePath];
	
	
	NSError *error = nil;
	if( NO == [self.renderedData writeToURL: renderedURL options: 0 error: &error] ) {
		lperror("could not write", renderedURL, error, error.userInfo);
	} else {
		lpdebug(renderedURL);
	}
	
	return renderedURL;
}

- (NSData *) renderedData
{
	if( nil == m_renderedData ) {
		return self.data;
	}
	return [[m_renderedData retain] autorelease];
}

- (NSImageRep *) renderedBitmapImageRep
{
	if( nil == m_renderedBitmapImageRep ) {
		return self.bitmapImageRep;
	}
	return [[m_renderedBitmapImageRep retain] autorelease];
}

- (CGImageRef) renderedCGImage
{
	CGImageRef cgImage = [self.renderedBitmapImageRep CGImage];
	lptrace(cgImage);
	return cgImage;
}

- (NSString *) renderedTypeIdentifier
{
	if( nil == m_renderedTypeIdentifier ) {
		return self.typeIdentifier;
	}
	return [[m_renderedTypeIdentifier retain] autorelease];
}

- (void) updateRenderings
{
	NSInteger quality = [self.renderQuality integerValue];
	
	if( kMediaContainerRenderQualityOriginal == quality || NO == [self.typeIdentifier isEqualToString: (id)kUTTypeImage] ) {
		lpdebug("passing through");
		self.renderedData = nil;
		self.renderedBitmapImageRep = nil;
		self.renderedTypeIdentifier = nil;
	} else {
	
		NSData *renderedData = [self.bitmapImageRep representationUsingType: NSJPEGFileType properties: 
								ER_DICT(NSImageCompressionFactor, [NSNumber numberWithFloat: quality / 100.0])];
	
		self.renderedTypeIdentifier = (id)kUTTypeJPEG;
		self.renderedData = renderedData;
		self.renderedBitmapImageRep = [NSBitmapImageRep imageRepWithData: renderedData];
	
		lpdebug(quality, renderedData.length);
	}	
}

- (void)setRenderQuality:(NSNumber *) renderQuality
{
	if( nil == renderQuality ) {
		renderQuality = [NSNumber numberWithInteger: kMediaContainerRenderQualityOriginal];
	}
	
	if( NO == [m_renderQuality isEqualToNumber: renderQuality] ) {
		
		[m_renderQuality autorelease];
        
		m_renderQuality = [renderQuality retain];
		
		lpdebug(renderQuality);
		
		[self updateRenderings];
	}
}


- (void) setURL: (NSURL *) URL
{
	[m_URL autorelease];
	m_URL = [URL retain];
	
	self.name = [[URL lastPathComponent] stringByDeletingPathExtension];
}

- (void) shutdown
{
	if( nil != self.cache ) {
	
		AFCacheableItem *cacheableItem = self.cacheableItem;
		NSURL *cacheableItemURL = cacheableItem.url;
	
		if( cacheableItemURL ) {
			[self.cache cancelAsynchronousOperationsForURL: cacheableItemURL itemDelegate: cacheableItem.delegate];		
		}
	
		cacheableItem.delegate = nil;
		
		self.cacheableItem = nil;
	}
}


- (void) dealloc
{	
	[self shutdown];
	
	[m_renderQuality release];
	[m_renderedTypeIdentifier release];
	[m_renderedData release];
	[m_renderedBitmapImageRep release];
	
	[m_bitmapImageRep release];
	
	[m_error release];
	[m_name release];
	[m_typeIdentifier release];
	[m_URL release];
	
	[super dealloc];
}

@end


@implementation MediaContainer ( AFCacheDelegate )

- (void) connectionDidFail: (AFCacheableItem *) cacheableItem
{
	if( nil == self.data ) {	
		[NSApp presentError:cacheableItem.error];
		[self updateFromData: nil error: nil]; // reset
	} else {
		lpdebugf("silently falling back to cached data for url %@ (error: %@)", cacheableItem.url, cacheableItem.error);
	}
}

- (void)connectionDidFinish: (AFCacheableItem *) cacheableItem
{		
	NSError *error = nil;
	
	if( NO == [self updateFromCacheableItem: cacheableItem error: &error] ) {
		lperror(error);
		self.error = [error retain];
	} else {
		self.error = nil;
	}
}

@end


BOOL IsCGImageOpaque(CGImageRef cgImage)
{
	if( lpkcassertf("imageTesting", cgImage, "no input image") ) {
		return NO;
	}
	
	if( kCGImageAlphaNone == CGImageGetAlphaInfo( cgImage ) ) {
		return YES;
	}
	
	BOOL dumpPGM = lpkcswitch("imageTestingDumpTmpAlphaPGM") ? YES : NO;
	
	size_t pixelsWide = CGImageGetWidth( cgImage );
	size_t pixelsHigh = CGImageGetHeight( cgImage );
	
	if( 0 == pixelsWide || 0 == pixelsHigh ) {
		lpkcwarning("imageTesting", "image has zero dimension");
		return NO;
	}
	
	int bytesPerRow = dumpPGM ? pixelsWide : (pixelsWide + 15) & ~15; // %16 for speed, which is inconvenient for dumping
	size_t alphaLen = pixelsHigh * bytesPerRow;
	int	x, y;
	
	CGContextRef alphaContext = CGBitmapContextCreate (NULL, pixelsWide, pixelsHigh, 8 /* bitsPerComp */, bytesPerRow, NULL /* no cs for AlphaOnly */, kCGImageAlphaOnly);
	
	if( alphaContext == NULL) {
		lpkcwarning("imageTesting", "could not create alphaContext");
		return NO;
	}
	
	unsigned char *alpha = CGBitmapContextGetData( alphaContext );
	
	CGContextDrawImage(alphaContext, (CGRect) { {0, 0}, {pixelsWide, pixelsHigh}} , cgImage);
	
	
	BOOL hasAlpha = NO;
	size_t pixelsTested = 0;
	
	unsigned char *cursor = alpha;
	for( y = 0 ; y < pixelsHigh ; ++y, cursor += bytesPerRow ) {
		for( x = 0 ; x < pixelsWide ; ++x ) {
			++pixelsTested;
			if( 0xff != cursor[x] ) {
				y = pixelsHigh; // stop condition
				hasAlpha = YES;
				break;
			}
		}
	}
	
	lpkcdebug("imageTesting", hasAlpha, pixelsTested);
	
	if( YES == dumpPGM ) {
		NSString *pgmHeader = [NSString stringWithFormat: @"P5\n%ld %ld\n255\n", (long) bytesPerRow, (long) pixelsHigh];
		const char *pgmHeaderBytes = [pgmHeader UTF8String];
		size_t pgmHeaderLen = strlen(pgmHeaderBytes);
		
		// relies on bytesPerRow == pixelsWide - which is ensured above if YES == dumpPGM
		NSMutableData *pgmData = [[[NSMutableData alloc] initWithLength: pgmHeaderLen + pixelsWide * pixelsHigh] autorelease];
		
		void *pgmBytes = [pgmData mutableBytes];
		
		strncpy(pgmBytes, pgmHeaderBytes, pgmHeaderLen);
		
		memcpy(pgmBytes + pgmHeaderLen, alpha, alphaLen);
		
		[pgmData writeToFile: @"/tmp/alpha.pgm" atomically: NO];	
	}
	
	CGContextRelease( alphaContext );
	
	return hasAlpha ? NO : YES;
}


