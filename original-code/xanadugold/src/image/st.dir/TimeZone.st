'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:06 pm'!

Object subclass: #TimeZone
	instanceVariableNames: 'secondsFromGMT dayStartDST dayEndDST timeStartEndDST secondsForDST weekDayStartDST '
	classVariableNames: 'DefaultTimeZone NullTimeZone '
	poolDictionaries: ''
	category: 'Magnitude-General'!
TimeZone comment:
'TimeZone represents a mapping between Greenwich Mean Time (GMT) and local time.  This involves both a time difference for standard time, and an algorithm for determining whether Daylight Savings Time (DST) is in effect and, if so, what the additional time offset is.  TimeZone is a support class for class Time.

There are places in the world in which one or the other of the time offsets is not an integral number of hours, and where the DST algorithms vary.  We accommodate the former, but not the latter.  We currently assume that DST transitions always occur on the last Sunday preceding a fixed date.

Instance Variables:
	secondsFromGMT	<Integer>	offset of this time zone from GMT, in seconds, 
									e.g., California = -8 * 3600
	dayStartDST		<Integer>	day of (non-leap) year when DST starts 
									(resolved to the previous Sunday)
	dayEndDST			<Integer>	day of (non-leap) year when DST ends 
									(resolved to the previous Sunday)
	timeStartEndDST	<Integer>	time of day (in seconds) when DST starts or ends
	secondsForDST		<Integer>	(non-negative) additional time offset when DST is in
							 		effect, e.g., U.S. uses 1 hour = 3600
	weekDayStartDST	<Integer>	day of the week that DST starts (usually Sunday).

Class Variables:
	DefaultTimeZone	<TimeZone> a TimeZone initialized with date and time 
									information to specify difference from GMT
	NullTimeZone 		<TimeZone> a TimeZone with no date and time information
'!


!TimeZone methodsFor: 'accessing'!

weekDayToStartDST
	"Answer the day of the week that DST starts (usually #Sunday)."

	^weekDayStartDST!

weekDayToStartDST: aSymbol
	"Set the day of the week that DST starts (usually #Sunday)."

	weekDayStartDST _ aSymbol.! !

!TimeZone methodsFor: 'converting'!

convertGMT: totalSeconds do: aBlock 
	"Convert a GMT time to a local date and time 
	(the two interact because of Daylight Saving Time.) 
	The GMT time origin is midnight, Dec 31 1900. 
	Answer with the result of invoking the argument  
	aBlock with two arguments representing the local 
	date (an instance of Date) and time (an instance of 
	Time where time is in seconds where midnight = 0)."

	| sec date seconds days dstDay dd start end dday |
	sec _ totalSeconds + secondsFromGMT.
		"Estimate the number of days since the origin.
		Since 86400 = 675 * 128, we can bring the total
		seconds back into SmallInteger range by doing an
		initial shift, thereby trading LargeInteger shifting
		and masking for multiplication and division."
	seconds _ sec bitAnd: 127.
	sec _ sec bitShift: -7.
	days _ sec // 675.
	seconds _ seconds + (sec \\ 675 bitShift: 7).
		"Decide if DST is in effect."
	secondsForDST ~= 0
		ifTrue: 
			["This time zone does have DST"
			dstDay _ seconds < timeStartEndDST
						ifTrue: [days - 1]
						ifFalse: [days].
			dd _ Date fromDays: dstDay.
			dday _ dd day.
			start _ Date newDay: 
							(dayStartDST >= 60
								ifTrue: [dayStartDST + dd leap - 1]
								ifFalse: [dayStartDST])
						  year: dd year.
			dday >= (start previous: self weekDayToStartDST) day
				ifTrue: 
					[end _ Date newDay: 
									(dayEndDST >= 60
										ifTrue: [dayEndDST + dd leap - 1]
										ifFalse: [dayEndDST])
								 year: dd year.
					dday < (end previous: self weekDayToStartDST) day
						ifTrue: 
							["DST is in effect.  Correct the time."
							seconds _ seconds + secondsForDST.
							seconds >= 86400
								ifTrue: 
									["crossed a day boundary"
									seconds _ seconds - 86400.
									days _ days + 1]]].
			date _ dstDay = days
						ifTrue: [dd]
						ifFalse: [Date fromDays: days]]
		ifFalse: ["No DST"
				date _ Date fromDays: days].
	^aBlock value: date value: seconds! !

!TimeZone methodsFor: 'private: private'!

setDifference: hours DST: dstAmount at: dstHour from: dstStart to: dstEnd
	"Initialize the instance variables."
	
	secondsFromGMT _ (hours * 3600) rounded.
	dayStartDST _ dstStart.
	dayEndDST _ dstEnd.
	timeStartEndDST _ (dstHour * 3600) rounded.
	secondsForDST _ (dstAmount * 3600) rounded! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TimeZone class
	instanceVariableNames: ''!


!TimeZone class methodsFor: 'class initialization'!

initialize
	"Install a default TimeZone.  The parameters here are for California.
	Eventually we should obtain this from the operating system."

	"TimeZone initialize."

	DefaultTimeZone _ self 
		timeDifference: -8	"Offset for California."
		DST: 1				"1 hour DST"
		at: 4					"starting at 4 AM"
		from: 91 + 6			"(first Sunday preceding) April 7"
		to: 274 + 6.			"(first Sunday preceding) October 7"
	DefaultTimeZone weekDayToStartDST: #Sunday.

	"Also create a zone that leaves times unchanged."
	NullTimeZone _ self timeDifference: 0 
		DST: 0 
		at: 0 
		from: 0 
		to: 0.
	NullTimeZone weekDayToStartDST: #Sunday.!

initializeDefaultTimeZone: hoursFromGMT
	"Install a default TimeZone with hours offset from Greenwich mean time."
	
	"TimeZone initializeDefaultTimeZone: -8.	for California
	TimeZone initializeDefaultTimeZone: -5.		for NewYork
	TimeZone initializeDefaultTimeZone: 0.		for London
	TimeZone initializeDefaultTimeZone: 1.		for Dortmund
	TimeZone initializeDefaultTimeZone: nil.		for absolute"


	hoursFromGMT == nil
		ifTrue: [ DefaultTimeZone _ self null ]
		ifFalse:[
	DefaultTimeZone _ self 
		timeDifference: hoursFromGMT
		DST: 1				"1 hour DST"
		at: 4					"starting at 4 AM"
		from: 91 + 6			"on (first Sunday preceding) April 7"
		to: 305 - 1.			"until (first Sunday preceding) October 31"
	DefaultTimeZone weekDayToStartDST: #Sunday.]! !

!TimeZone class methodsFor: 'instance creation'!

default
	"Answer the default time zone, set at class initialization."

	^DefaultTimeZone!

null
	"Answer a TimeZone that leaves times unchanged.  This is appropriate
	if the operating system returns local time rather than GMT."

	^NullTimeZone!

timeDifference: hours DST: amount at: startHour from: startDate to: endDate
	"Answer a new TimeZone.  This is the most general message
	for creating a TimeZone with specified time difference and DST parameters."

	^self new
		setDifference: hours
		DST: amount
		at: startHour
		from: startDate
		to: endDate! !

TimeZone initialize!
