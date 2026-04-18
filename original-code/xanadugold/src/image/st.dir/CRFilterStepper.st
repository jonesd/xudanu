'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:09 pm'!

Stepper subclass: #CRFilterStepper
	instanceVariableNames: '
		mySource {Stepper}
		myFilter {CRFilter}
		myCurrentRecord {ChangeRecord}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!
CRFilterStepper comment:
'This class accepts a source and a filter.  It steps until the filter passes the current record of the source.'!



!CRFilterStepper methodsFor: 'operations'!

{Heaper} fetch

	^ myCurrentRecord!

{BooleanVar} hasValue
	
	^ myCurrentRecord ~~ NULL!

{void} step
	
	mySource step.
	self skipToNext! !

!CRFilterStepper methodsFor: 'private: operation'!

{void} skipToNext
	
	[mySource hasValue and: [(myFilter passes: mySource fetch) not]] whileTrue: [mySource step].
	mySource hasValue
		ifTrue: [myCurrentRecord _ mySource fetch]
		ifFalse: [myCurrentRecord _ NULL]! !

!CRFilterStepper methodsFor: 'create'!

{Stepper} copy
	^ self create: mySource copy with: myFilter with: myCurrentRecord!

create: onSource {Stepper} with: filter {CRFilter}
	mySource _ onSource.
	myFilter _ filter.
	myCurrentRecord _ NULL.
	self skipToNext!

create: onSource {Stepper} with: filter {CRFilter} with: current {ChangeRecord}

	mySource _ onSource.
	myFilter _ filter.
	myCurrentRecord _ current! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CRFilterStepper class
	instanceVariableNames: ''!



!CRFilterStepper class methodsFor: 'make'!

make: source {Stepper} with: filter {CRFilter}

	^ self create: source with: filter! !