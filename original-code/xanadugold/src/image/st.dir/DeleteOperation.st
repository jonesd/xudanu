'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:31 pm'!

PrimOperation subclass: #DeleteOperation
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(DeleteOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeleteOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}
	super create: s with: f with: aFragment! !

!DeleteOperation methodsFor: 'smalltalk: printing'!

{void} printTextOn: oo {TextStream reference}
	
	oo emphasis: 13.
	oo << myFragment text! !

!DeleteOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'Delete[' << self startPosition << ',' << self finalPosition << ',' << self fragment << ']'.! !

!DeleteOperation methodsFor: 'accessing'!

{IntegerVar} nextFinalPosition
	"return the position in the final document of the operation that will follow this one"
	^self finalPosition!

{IntegerVar} nextStartPosition
	"return the position in the start document of the operation that will follow this one"
	^self startPosition + self count! !

!DeleteOperation methodsFor: 'testing'!

{BooleanVar} isPureDelete
	^self fragment isShared not! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DeleteOperation class
	instanceVariableNames: ''!

(DeleteOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeleteOperation class methodsFor: 'pseudoConstructors'!

{DeleteOperation} make: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}

	^DeleteOperation create: s with: f with: aFragment! !