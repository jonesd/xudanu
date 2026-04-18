'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:10 pm'!

CRFilter subclass: #CRTimeFilter
	instanceVariableNames: 'myTime {Time}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CRTimeFilter methodsFor: 'accessing'!

{String} label
	^ myTime printString!

{BooleanVar} passes: cr {ChangeRecord}
	^ cr time >= myTime! !

!CRTimeFilter methodsFor: 'create'!

create: onTime {Time}

	super create.
	myTime _ onTime! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CRTimeFilter class
	instanceVariableNames: ''!



!CRTimeFilter class methodsFor: 'make'!

after: time {Time}
	^ self create: time!

before: time {Time}

	^ CRNotFilter make: (self create: time)! !