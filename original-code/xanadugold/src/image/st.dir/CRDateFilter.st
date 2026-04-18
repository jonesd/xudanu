'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:08 pm'!

CRFilter subclass: #CRDateFilter
	instanceVariableNames: 'myDate {Date}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!



!CRDateFilter methodsFor: 'accessing'!

{String} label
	^ myDate printString!

{BooleanVar} passes: cr {ChangeRecord}
	^ cr date >= myDate! !

!CRDateFilter methodsFor: 'create'!

create: onDate {Date}

	super create.
	myDate _ onDate! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CRDateFilter class
	instanceVariableNames: ''!



!CRDateFilter class methodsFor: 'make'!

after: date {Date}
	^ self create: date!

before: date {Date}

	^ CRNotFilter make: (self create: date)! !