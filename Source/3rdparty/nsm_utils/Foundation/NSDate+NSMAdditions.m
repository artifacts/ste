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

#import "NSDate+NSMAdditions.h"


@implementation NSDate (NSMAdditions)

- (NSString *)nsm_relativeDateStringFromDate:(NSDate *)date oldDateFormat:(NSString *)oldDateFormat{
	if (date == nil)
		date = [NSDate date];
	
	NSDate *laterDate = [self laterDate:date];
	NSDate *earlierDate = [self earlierDate:date];
	NSTimeInterval difference = [laterDate timeIntervalSinceDate:earlierDate];
	int days = (int)floor((difference / 60 / 60 / 24));
	
	if (days > 7){
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		if (oldDateFormat == nil)
			[formatter setDateStyle:NSDateFormatterShortStyle];
		else
			[formatter setDateFormat:oldDateFormat];
		NSString *dateString = [formatter stringFromDate:self];
		[formatter release];
		return dateString;
	}else if (days > 1){
		return [NSString stringWithFormat:NSLocalizedString(@"%d days ago", @""), days];
	}else if (days == 1){
		return [NSString stringWithFormat:NSLocalizedString(@"%d day ago", @""), days];
	}else{
		difference -= (days * 60 * 60 * 24);
		int hours = (int)floor((difference / 60 / 60));
		
		if (hours > 1){
			return [NSString stringWithFormat:NSLocalizedString(@"%d hours ago", @""), hours];
		}else if (hours == 1){
			return [NSString stringWithFormat:NSLocalizedString(@"%d hour ago", @""), hours];
		}else{
			difference -= (hours * 60 * 60);
			int minutes = (int)floor((difference / 60));
			if (minutes > 1){
				return [NSString stringWithFormat:NSLocalizedString(@"%d minutes ago", @""), 
					minutes];
			}else if (minutes == 1){
				return [NSString stringWithFormat: NSLocalizedString(@"%d minute ago", @""), 
					minutes];
			}else{
				difference -= (minutes * 60);
				int seconds = (int)difference;
				if (seconds <= 15)
					return NSLocalizedString(@"Right now", @"");
				else
					return NSLocalizedString(@"Less than a minute ago", @"");
			}
		}
	}
	return nil;
}

- (NSString *)nsm_stringWithDateFormat:(NSString *)aFormat{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:aFormat];
	NSString *result = [formatter stringFromDate:self];
	[formatter release];
	return result;
}

+ (NSDate *)nsm_dateFromString:(NSString *)dateString dateFormat:(NSString *)dateFormat{
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:dateFormat];
	NSDate *date = [formatter dateFromString:dateString];
	[formatter release];
	return date;
}

- (NSDate *)nsm_dateAtMidnight{
	NSDateComponents *comps = [[NSCalendar currentCalendar] 
		components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

+ (NSDate *)nsm_dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day{
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setYear:year];
	[comps setMonth:month];
	[comps setDay:day];
	NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
	[comps release];
	return date;
}

- (NSDate *)nsm_dateTomorrow{
	NSDateComponents *comps = [[NSCalendar currentCalendar] 
		components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | 
			NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) 
		fromDate:self];
	[comps setDay:[comps day] + 1];
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

- (NSDate *)nsm_dateYesterday{
	NSDateComponents *comps = [[NSCalendar currentCalendar] 
		components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | 
			NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) 
		fromDate:self];
	[comps setDay:[comps day] - 1];
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

- (NSDate *)nsm_dateTomorrowAtMidnight{
	NSDateComponents *comps = [[NSCalendar currentCalendar] 
		components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
	[comps setDay:[comps day] + 1];
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

- (BOOL)nsm_isSameDate:(NSDate *)aDate{
	NSDateComponents *compsA = [[NSCalendar currentCalendar] 
		components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:self];
	NSDateComponents *compsB = [[NSCalendar currentCalendar] 
		components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:aDate];
	return [compsA year] == [compsB year] && 
		[compsA month] == [compsB month] && 
		[compsA day] == [compsB day];
}

- (NSDate *)nsm_dateAt:(NSInteger)hour minutes:(NSInteger)minutes seconds:(NSInteger)seconds{
	NSDateComponents *comps = [[NSCalendar currentCalendar] 
		components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) 
		fromDate:self];
	[comps setHour:hour];
	[comps setMinute:minutes];
	[comps setSecond:seconds];
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}
@end
