'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:39 pm'!

TableStepper subclass: #AscendingWordArrayStepper
	instanceVariableNames: 'myWA myIndex myLast '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!


!AscendingWordArrayStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	^ myWA intFetch: myIndex!

{BooleanVar} hasValue
	^myIndex <= myLast!

{void} step
	myIndex _ myIndex + 1! !

!AscendingWordArrayStepper methodsFor: 'create'!

{Stepper} copy
	^AscendingWordArrayStepper
		create: myWA
		with: myIndex
		with: myLast!

create: array {MuWordArray}
	super create.
	myWA _ array.
	myIndex _ 0.
	myLast _ myWA highestIndex DOTasLong!

create: array {MuWordArray} with: index {IntegerVar}
	super create.
	myWA _ array.
	myIndex _ index DOTasLong.
	myLast _ myWA highestIndex DOTasLong!

create: array {MuWordArray} with: start {IntegerVar} with: stop {IntegerVar}
	super create.
	myWA _ array.
	myIndex _ start DOTasLong.
	myLast _ stop DOTasLong! !