'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:38 pm'!

PrimOperation subclass: #ShareOperation
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(ShareOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ShareOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'Share[' << self startPosition << ',' << self finalPosition << ',' << self fragment << ']'.! !

!ShareOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}
	super create: s with: f with: aFragment! !

!ShareOperation methodsFor: 'accessing'!

{IntegerVar} nextFinalPosition
	"return the position in the final document of the operation that will follow this one"
	^self finalPosition + self count!

{IntegerVar} nextStartPosition
	"return the position in the start document of the operation that will follow this one"
	^self startPosition + self count! !

!ShareOperation methodsFor: 'smalltalk: printing'!

{void} printTextOn: oo {TextStream reference}
	
	oo emphasis: 0.
	oo << myFragment! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ShareOperation class
	instanceVariableNames: ''!

(ShareOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ShareOperation class methodsFor: 'pseudoConstructors'!

{ShareOperation} make: s {IntegerVar} with: f {IntegerVar} with:  aFragment {CompareFragment}

	^ShareOperation create: s with: f with: aFragment! !