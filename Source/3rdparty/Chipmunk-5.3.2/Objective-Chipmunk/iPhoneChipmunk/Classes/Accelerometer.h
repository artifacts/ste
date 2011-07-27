#import <UIKit/UIKit.h>

#import "chipmunk/chipmunk.h"

@interface Accelerometer : NSObject <UIAccelerometerDelegate>

+ (void)installWithInterval:(NSTimeInterval)interval andAlpha:(float)alpha;
+ (cpVect)getAcceleration;

@end
