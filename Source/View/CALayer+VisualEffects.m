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

#import "CALayer+VisualEffects.h"


@implementation CALayer (VisualEffects)

- (void)flash {
	
	// The selection layer will pulse continuously.
	// This is accomplished by setting a bloom filter on the layer
	
	// create the filter and set its default values
	CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome"];
	[filter setDefaults];
	[filter setValue:[CIColor colorWithRed:0.37 green:0.65 blue:0.97] forKey:@"inputColor"];
	
	// name the filter so we can use the keypath to animate the inputIntensity
	// attribute of the filter
	[filter setName:@"pulseFilter"];
	
	// set the filter to the selection layer's filters
	[self setFilters:[NSArray arrayWithObject:filter]];
	
	// create the animation that will handle the pulsing.
	CABasicAnimation* pulseAnimation = [CABasicAnimation animation];
	
	// the attribute we want to animate is the inputIntensity
	// of the pulseFilter
	pulseAnimation.keyPath = @"filters.pulseFilter.inputIntensity";
	
	// we want it to animate from the value 0 to 1
	pulseAnimation.fromValue = [NSNumber numberWithFloat: 0.0];
	pulseAnimation.toValue = [NSNumber numberWithFloat: 1.0];
	
	// over a one second duration, and run an infinite
	// number of times
	pulseAnimation.duration = 0.4;
	pulseAnimation.repeatCount = 1; //HUGE_VALF;
	pulseAnimation.removedOnCompletion = YES;
	
	// we want it to fade on, and fade off, so it needs to
	// automatically autoreverse.. this causes the intensity
	// input to go from 0 to 1 to 0
	pulseAnimation.autoreverses = YES;
	
	// use a timing curve of easy in, easy out..
	pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
	
	// add the animation to the selection layer. This causes
	// it to begin animating. We'll use pulseAnimation as the
	// animation key name
	[self addAnimation:pulseAnimation forKey:@"pulseAnimation"];				
	
	[self performSelector:@selector(setFilters:) withObject:nil afterDelay:0.39];
}

@end
