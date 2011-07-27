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

#import <Foundation/Foundation.h>


@interface NSDate (NSMAdditions)
- (NSString *)nsm_relativeDateStringFromDate:(NSDate *)date oldDateFormat:(NSString *)oldDateFormat;
- (NSString *)nsm_stringWithDateFormat:(NSString *)aFormat;
+ (NSDate *)nsm_dateFromString:(NSString *)dateString dateFormat:(NSString *)dateFormat;
- (NSDate *)nsm_dateAtMidnight;
+ (NSDate *)nsm_dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
- (NSDate *)nsm_dateTomorrow;
- (NSDate *)nsm_dateYesterday;
- (NSDate *)nsm_dateTomorrowAtMidnight;
- (BOOL)nsm_isSameDate:(NSDate *)aDate;
- (NSDate *)nsm_dateAt:(NSInteger)hour minutes:(NSInteger)minutes seconds:(NSInteger)seconds;
@end