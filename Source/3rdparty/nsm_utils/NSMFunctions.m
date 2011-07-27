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

const void* RetainCallback(CFAllocatorRef allocator, const void *value){
	return value;
}
void ReleaseCallback(CFAllocatorRef allocator, const void *value){}

NSMutableArray *NSMCreateWeakArray(){
	CFArrayCallBacks callbacks = kCFTypeArrayCallBacks;
	callbacks.retain = RetainCallback;
	callbacks.release = ReleaseCallback;
	return (NSMutableArray*)CFArrayCreateMutable(nil, 0, &callbacks);
}

CGFloat NSMDegToRad(CGFloat degrees){
	return degrees * (M_PI / 180.0f);
}

CGFloat NSMRadToDeg(CGFloat radians){
	return radians * (180.0f / M_PI);
}

CGPoint NSMPointRotatedAroundPoint(CGPoint aPoint, CGPoint center, CGFloat radians){
	CGPoint point = aPoint;
	CGFloat x, y;
	point.x -= center.x;
	point.y -= center.y;
	x = point.x * cosf(radians) - point.y * sinf(radians);
	y = point.x * sinf(radians) + point.y * cosf(radians);
	point.x = x + center.x;
	point.y = y + center.y;
	return point;
}

CGPoint NSMRotatedVector(CGPoint vector, CGFloat radians){
	CGFloat x = vector.x * cosf(radians) - vector.y * sinf(radians);
	CGFloat y = vector.x * sinf(radians) + vector.y * cosf(radians);
	return (CGPoint){x, y};
}

void NSMRotatePointsAroundPoint(CGPoint points[], CGPoint center, CGFloat radians, size_t count){
	for (int i = 0; i < count; i++){
		CGPoint point = points[i];
		points[i] = NSMPointRotatedAroundPoint(point, center, radians);
	}
}

void NSMPointsByRotatingRectAroundAnchor(CGPoint *points, CGRect rect, CGPoint anchor, 
	CGFloat radians){
	points[0] = (CGPoint){CGRectGetMinX(rect), CGRectGetMinY(rect)};
	points[1] = (CGPoint){CGRectGetMaxX(rect), CGRectGetMinY(rect)}; 
	points[2] = (CGPoint){CGRectGetMaxX(rect), CGRectGetMaxY(rect)}; 
	points[3] = (CGPoint){CGRectGetMinX(rect), CGRectGetMaxY(rect)};
	CGPoint center = (CGPoint){CGRectGetWidth(rect) * anchor.x + CGRectGetMinX(rect), 
		CGRectGetHeight(rect) * anchor.y + CGRectGetMinY(rect)};
	NSMRotatePointsAroundPoint(points, center, radians, 4);
}

CGRect NSMRectByRotatingRectAroundPoint(CGRect rect, CGPoint anchor, CGFloat radians){
	CGPoint points[4] = {
		CGRectGetMinX(rect), CGRectGetMinY(rect), 
		CGRectGetMaxX(rect), CGRectGetMinY(rect), 
		CGRectGetMaxX(rect), CGRectGetMaxY(rect), 
		CGRectGetMinX(rect), CGRectGetMaxY(rect)
	};
	CGPoint *rotatedPoints = malloc(sizeof(CGPoint) * 4);
	memcpy(rotatedPoints, points, sizeof(CGPoint) * 4);
	NSMRotatePointsAroundPoint(rotatedPoints, anchor, radians, 4);
	CGFloat minX, maxX, minY, maxY;
	for (int i = 0; i < 4; i++){
		CGPoint point = rotatedPoints[i];
		if (i == 0){
			minX = maxX = point.x;
			minY = maxY = point.y;
			continue;
		}
		minX = MIN(minX, point.x);
		maxX = MAX(maxX, point.x);
		minY = MIN(minY, point.y);
		maxY = MAX(maxY, point.y);
	}
	free(rotatedPoints);
	return (CGRect){minX, minY, maxX - minX, maxY - minY};
}

// if any contained points have negative coordinates, the whole shebang is moved, so that every 
// coordinate is positive
void NSMNormalizePoints(CGPoint points[], size_t count){
	CGPoint maxOffset = CGPointZero;
	for (int i = 0; i < count; i++){
		CGPoint point = points[i];
		if (point.x < 0)
			maxOffset.x = MAX(-point.x, maxOffset.x);
		if (point.y < 0)
			maxOffset.y = MAX(-point.y, maxOffset.y);
	}
	
	if (CGPointEqualToPoint(maxOffset, CGPointZero)){
		return;
	}
	
	for (int i = 0; i < count; i++){
		CGPoint point = points[i];
		point.x += maxOffset.x;
		point.y += maxOffset.y;
		points[i] = point;
	}
}

BOOL NSMPointInPolygon(CGPoint point, CGPoint *polygonPoints, size_t count){
	int i, j;
	BOOL inside = NO;
	for (i = 0, j = count - 1; i < count; j = i++){
		CGPoint polygonPointA = polygonPoints[i];
		CGPoint polygonPointB = polygonPoints[j];
		if (((polygonPointA.y > point.y) != (polygonPointB.y > point.y)) &&
			(point.x < (polygonPointB.x - polygonPointA.x) * (point.y - polygonPointA.y) / 
				(polygonPointB.y - polygonPointA.y) + polygonPointA.x)){
			inside = !inside;
		}
	}
	return inside;
}


NSUInteger NSMHexValueFromString(NSString *hexString){
	NSString *cleanedString = [hexString stringByReplacingOccurrencesOfString:@"#" 
		withString:@"0x"];
	unsigned value;
	[[NSScanner scannerWithString:cleanedString] scanHexInt:&value];
	return value;
}

void NSMRGBComponentsWithHexValue(NSUInteger hexValue, CGFloat *redComponent, 
	CGFloat *greenComponent, CGFloat *blueComponent){
	*redComponent = ((hexValue >> 16) & 0xff) / 255.0f;
	*greenComponent = ((hexValue >> 8) & 0xff) / 255.0f;
	*blueComponent = (hexValue & 0xff) / 255.0f;
}
