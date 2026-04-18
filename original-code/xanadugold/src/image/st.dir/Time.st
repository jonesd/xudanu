'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:06 pm'!

Magnitude subclass: #Time
	instanceVariableNames: 'hours minutes seconds '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-General'!
Time comment:
'An instance of class Time represents a particular second in a day.  Days start at midnight.  Protocol provided for the object Time supports inquiries about time in general as well as details about a specific time.  Time is represented by integral units of hours, minutes and seconds such that the total seconds since midnight is 3600*hours + (60*minutes + seconds).

Instance Variables:
	hours		<Integer>
	minutes		<Integer>
	seconds		<Integer>
				'!


!Time methodsFor: 'comparing'!

< aTime 
	"Answer whether the argument, aTime is earlier than the receiver."

	hours ~= aTime hours ifTrue: [^hours < aTime hours].
	minutes ~= aTime minutes ifTrue: [^minutes < aTime minutes].
	^seconds < aTime seconds!

= aTime 
	"Answer whether aTime represents the same second as the receiver."

	self species = aTime species
		ifTrue: [^hours = aTime hours 
					& (minutes = aTime minutes) 
					& (seconds = aTime seconds)]
		ifFalse: [^false]!

hash
	"Answer a SmallInteger unique to the receiver."

	^((hours hash bitShift: 3) bitXor: minutes) bitXor: seconds! !

!Time methodsFor: 'accessing'!

hours
	"Answer the number of hours the receiver represents."

	^hours!

minutes
	"Answer the number of minutes the receiver represents."

	^minutes!

seconds
	"Answer the number of seconds the receiver represents."

	^seconds! !

!Time methodsFor: 'arithmetic'!

addTime: timeAmount
	"Answer a new Time that is timeAmount after the receiver.  timeAmount is an 
	instance of Date or Time."

	^Time fromSeconds: self asSeconds + timeAmount asSeconds!

subtractTime: timeAmount 
	"Answer a new Time that is timeAmount before the receiver.  timeAmount is an 
	instance of Date or Time."

	^Time fromSeconds: self asSeconds - timeAmount asSeconds! !

!Time methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies 
	the receiver.  Format is h:mm:ss am/pm."

	hours > 12
		ifTrue: [hours - 12 printOn: aStream]
		ifFalse: [hours < 1
					ifTrue: [12 printOn: aStream]
					ifFalse: [hours printOn: aStream]].
	aStream nextPutAll: (minutes < 10
							ifTrue: [':0']
							ifFalse: [':']).
	minutes printOn: aStream.
	aStream nextPutAll: (seconds < 10
							ifTrue: [':0']
							ifFalse: [':']).
	seconds printOn: aStream.
	aStream nextPutAll: (hours < 12
							ifTrue: [' am']
							ifFalse: [' pm'])!

storeOn: aStream
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates an object similar to the receiver.  The general format
	for objects is
		( class-name readFromString: string )"

	aStream nextPutAll: '(', self class name, ' readFromString: ';
		print: self printString;
		nextPut: $)! !

!Time methodsFor: 'converting'!

asSeconds
	"Answer the number of seconds since midnight of the receiver."

	^3600 * hours + (60 * minutes + seconds)! !

!Time methodsFor: 'private: private'!

hours: anInteger 
	"Initialize the hour of the day."
	
	hours _ anInteger!

hours: hourInteger minutes: minInteger seconds: secInteger 
	"Initialize all the instance variables."

	hours _ hourInteger.
	minutes _ minInteger.
	seconds _ secInteger! !

!Time methodsFor: 'cxx translation'!

{Time} difference: from {Time}
	^ self subtractTime: from!

{BooleanVar} isEqual: to {Time}
	^ self = to!

{BooleanVar} isGreaterOrEqual: than {Time}

	^ than < self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Time class
	instanceVariableNames: ''!


!Time class methodsFor: 'instance creation'!

fromSeconds: secondCount 
	"Answer a Time that is secondCount seconds since midnight."

	| secondsInHour hours |
	hours _ secondCount // 3600.
	secondsInHour _ secondCount \\ 3600.
	^self new hours: hours
			   minutes: secondsInHour // 60
			   seconds: secondsInHour \\ 60!

now
	"Answer a Time representing the time right now--this is a 24 hour clock."

	^self dateAndTimeNow at: 2!

readFrom: aStream
	"Answer a Time as read from the argument aStream
	that is in the form:
		<hour>:<minute>:<second> <am/pm>
 
	<minute>, <second> or <am/pm> may be omitted. 
	such as,
			1:59:30 pm
			8AM
			15:30
	
	For example,
	Time readFrom: (ReadStream on: '2:23:09 pm')"

	| hour minute second char1 isAm |
	hour _ Integer readFrom: aStream.
	second _ 0.
	(aStream peekFor: $:)
		ifFalse: [minute _ 0]
		ifTrue: [minute _ Integer readFrom: aStream.
			(aStream peekFor: $:)
				ifTrue: [second _ Integer readFrom: aStream]].
	aStream skipSeparators.
	(aStream atEnd not and: [char1 _ aStream peek asLowercase.
		(isAm _ char1 = $a) or: [char1 = $p]])
			ifTrue: [aStream next. "advance stream pointer"
				(aStream atEnd not and: [aStream peek asLowercase = $m])
					ifFalse: [aStream skip: -1] "leave stream pointer after time"
					ifTrue: [aStream next. "advance stream pointer"
							"pm is default for 12, am is default for all others"
							hour = 12
								ifTrue: [isAm ifTrue: [hour _ 0]]
								ifFalse: [isAm ifFalse: [hour _ hour + 12]]]].
	^self fromSeconds: 60*(60*hour+minute)+second! !

!Time class methodsFor: 'general inquiries'!

dateAndTimeNow
	"Answer an array of (Date today, Time now)."

	"Time dateAndTimeNow."

	^self currentTime!

millisecondClockValue
	"Answer the number of milliseconds since the millisecond clock 
	was last reset or rolled over."

	| milliseconds |
	milliseconds _ Integer new: 4 neg: false.
	self millisecondClockInto: milliseconds.
	^milliseconds compressed!

millisecondsToRun: timedBlock
	"Answer the number of milliseconds timedBlock takes to return its value."

	| initialMilliseconds |
	initialMilliseconds _ self millisecondClockValue.
	timedBlock value.
	^self millisecondClockValue - initialMilliseconds!

timeWords
	"Answer the seconds (in GMT) since 1901 began, as a four element 
	ByteArray.  The high-order 8-bits of the answer are stored in the byte 
	indexed by 1 and the low-order 8-bits in the byte indexed 4."

	| seconds bytes |
	seconds _ ByteArray new: 4.
	self secondClockInto: seconds.
	bytes _ ByteArray new: 4.
	
	"Reverse the bytes"
	1 to: 4 do: [:i | bytes at: i put: (seconds at: 5 - i)].
	^bytes!

totalSeconds
	"Answer the total seconds since 1901 began, corrected for time zone  
	and daylight savings time."

	^self currentSeconds! !

!Time class methodsFor: 'private: private'!

aTime: theSeconds
	"Answer an Array of (Date today, Time now)."

	^TimeZone default
		convertGMT: theSeconds
		do:
			[:date :seconds |
			Array with: date with: (Time fromSeconds: seconds)]!

aTimeString: theSeconds 
	"Answer a String of the date and time where the argument, theSeconds,  
	represents the number of seconds since 1901 began."

	^TimeZone default 
		convertGMT: theSeconds 
		do: [:date :seconds | 
			date printString , ' ' , (Time fromSeconds: seconds) printString]!

currentSeconds
	"Answer with the total seconds since 1901 began,
	corrected for time zone and daylight savings time."

	^TimeZone default
		convertGMT: self secondClock
		do:
			[:date :seconds |
			date asSeconds + seconds]!

currentTime
	"Answer an Array of (Date today, Time now)."

	^self aTime: self secondClock!

millisecondClockInto: aByteArray 
	"Answer the number of milliseconds since the millisecond clock 
	was last reset or rolled over by storing the result in the argument.
	The argument is a byte indexable object of length at least four (a 
	LargePositiveInteger).  Store into the first four bytes of the argument the 
	number of milliseconds since the millisecond clock was last reset or rolled 
	over (a 32-bit unsigned number).  The low-order 8-bits are stored in 
	the byte indexed by 1 and the high-order 8-bits in the byte indexed 4.  
	Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 99>
	self primitiveFailed!

secondClock
	"Answer an integer representing the number of seconds since
	1901 began."

	| seconds |
	seconds _ Integer new: 4 neg: false.
	self secondClockInto: seconds.
	^seconds compressed!

secondClockInto: aByteArray 
	"The argument is a byte indexable object of length at least four.  Store 
	into the first four bytes of the argument the number of seconds since 
	1901 began (a 32-bit unsigned number).  The low-order 8-bits are stored 
	in the byte indexed by 1 and the high-order 8-bits in the byte indexed 4.  
	Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 98>
	self primitiveFailed! !

!Time class methodsFor: 'global: cxx'!

{Time} time
	^ self new!

{Time} time: old {Time}
	^ self new subtractTime: old!

{IntegerVar} xuTime
	"Seconds from the epoch."
	
	["Adjust for our epoch."  ^Time totalSeconds] smalltalkOnly.
	MarkM shouldImplement.! !