'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:24 pm'!

MCounter subclass: #BooleanCounter
	instanceVariableNames: '
		myTrue {IntegerVar}
		myFalse {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-monitor'!

(BooleanCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BooleanCounter methodsFor: 'accessing'!

{void} count: value {BooleanVar}
	value
		ifTrue: [myTrue _ myTrue + 1]
		ifFalse: [myFalse _ myFalse + 1]!

create
	super create.
	myTrue _ myFalse _ IntegerVar0!

{ScruTable of: IntegerPos} results
	"the results shown in a form mapping from some position type to the actual numbers"
	| result {MuTable of: PackOBits and: IntegerPos} |
	result _ MuTable make: PackOBitsSpace make.
	result at: (PackOBits string: 'True') store: myTrue integer.
	result at: (PackOBits string: 'False') store: myFalse integer.
	^result!

{IntegerVar} total
	"the total number of occurrences"
	^myTrue + myFalse! !