'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:24 pm'!

TableCounter subclass: #IntegerCounter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-monitor'!

(IntegerCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!IntegerCounter methodsFor: 'accessing'!

{void} count: value {IntegerVar}
	| n {IntegerPos} |
	n _ (myCounts intFetch: value) quickCast: IntegerPos.
	n == NULL
		ifTrue: [myCounts atInt: value store: 1 integer]
		ifFalse: [myCounts atInt: value store: (n asIntegerVar + 1) integer]!

create
	super create: IntegerSpace make! !