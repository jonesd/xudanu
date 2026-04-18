'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:25 pm'!

MCounter subclass: #TableCounter
	instanceVariableNames: 'myCounts {MuTable of: IntegerPos}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-monitor'!

(TableCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TableCounter methodsFor: 'accessing'!

create: cs {CoordinateSpace}
	super create.
	myCounts _ MuTable make: cs!

{ScruTable of: IntegerPos} results
	"the results shown in a form mapping from some position type to the actual numbers"
	^myCounts copy!

{IntegerVar} total
	"the total number of occurrences"
	| result {IntegerVar} |
	result _ IntegerVar0.
	myCounts stepper forEach: [ :n {IntegerPos} |
		result _ result + n asIntegerVar].
	^result! !

!TableCounter methodsFor: 'protected: protected'!

{void} privateCount: key {Position}
	| n {IntegerPos} |
	n _ (myCounts fetch: key) quickCast: IntegerPos.
	n == NULL
		ifTrue: [myCounts at: key store: 1 integer]
		ifFalse: [myCounts at: key store: (n asIntegerVar + 1) integer]! !