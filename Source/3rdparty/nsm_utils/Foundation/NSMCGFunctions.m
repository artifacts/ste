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

#import "NSMCGFunctions.h"

void NSMCGPathAddRoundRect(CGMutablePathRef path, CGRect rect, CGFloat cornerRadius){
	NSMCGPathAddRoundRectWithRadii(path, rect, 
		(CGFloat[]){cornerRadius, cornerRadius, cornerRadius, cornerRadius});
}

void NSMCGPathAddRoundRectWithRadii(CGMutablePathRef path, CGRect rect, CGFloat radii[4]){
	CGPathMoveToPoint(path, NULL, CGRectGetMinX(rect) + radii[0], CGRectGetMinY(rect));
	CGPathAddArc(path, NULL, CGRectGetMaxX(rect) - radii[0], CGRectGetMinY(rect) + radii[0], 
		radii[0], 3 * M_PI / 2, 0, 0);
	CGPathAddArc(path, NULL, CGRectGetMaxX(rect) - radii[1], CGRectGetMaxY(rect) - radii[1], 
		radii[1], 0, M_PI / 2, 0);
	CGPathAddArc(path, NULL, CGRectGetMinX(rect) + radii[2], CGRectGetMaxY(rect) - radii[2], 
		radii[2], M_PI / 2, M_PI, 0);
	CGPathAddArc(path, NULL, CGRectGetMinX(rect) + radii[3], CGRectGetMinY(rect) + radii[3], 
		radii[3], M_PI, 3 * M_PI / 2, 0);
}


CGRect NSMFitCGRectToRect(CGRect sourceRect, CGRect targetRect, BOOL keepRatio, BOOL allowUpscale){
	if (!keepRatio){
		return (CGRect){sourceRect.origin, 
			CGRectGetWidth(targetRect) - CGRectGetMinX(sourceRect), 
			CGRectGetHeight(targetRect) - CGRectGetMinY(sourceRect)};
	}
	
	CGFloat ratio;
	CGRect resultRect = sourceRect;
	
	// rect is too small
	if (CGRectGetWidth(sourceRect) < CGRectGetWidth(targetRect) && 
		CGRectGetHeight(sourceRect) < CGRectGetHeight(targetRect)){
		if (!allowUpscale){
			return resultRect;
		}
		ratio = MIN(CGRectGetWidth(targetRect) / CGRectGetWidth(sourceRect), 
			CGRectGetHeight(targetRect) / CGRectGetHeight(sourceRect));
		resultRect.size.width *= ratio;
		resultRect.size.height *= ratio;
		return resultRect;		
	}
	
	// rect is too tall
	if (CGRectGetWidth(sourceRect) <= CGRectGetWidth(targetRect)){
		ratio = CGRectGetHeight(targetRect) / CGRectGetHeight(sourceRect);
		resultRect.size.height = CGRectGetHeight(targetRect);
		resultRect.size.width *= ratio;
	// rect is too wide
	}else if (CGRectGetHeight(sourceRect) <= CGRectGetHeight(targetRect)){
		ratio = CGRectGetWidth(targetRect) / CGRectGetWidth(sourceRect);
		resultRect.size.width = CGRectGetWidth(targetRect);
		resultRect.size.height *= ratio;
	// rect is too wide and too tall
	}else{
		ratio = MIN(CGRectGetWidth(targetRect) / CGRectGetWidth(sourceRect), 
			CGRectGetHeight(targetRect) / CGRectGetHeight(sourceRect));
		resultRect.size.width *= ratio;
		resultRect.size.height *= ratio;
	}
	return resultRect;
}
