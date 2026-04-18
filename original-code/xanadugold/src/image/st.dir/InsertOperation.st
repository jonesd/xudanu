'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:34 pm'!

PrimOperation subclass: #InsertOperation
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(InsertOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}
	super create: s with: f with: aFragment! !

!InsertOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'Insert[' << self startPosition << ',' << self finalPosition << ','  << self fragment << ']'.! !

!InsertOperation methodsFor: 'accessing'!

{IntegerVar} nextFinalPosition
	"return the position in the final document of the operation that will follow this one"
	^self finalPosition + self count!

{IntegerVar} nextStartPosition
	"return the position in the start document of the operation that will follow this one"
	^self startPosition! !

!InsertOperation methodsFor: 'testing'!

{BooleanVar} isInsertMove
	"Am I an insertion of text which comes from somewhere else?"
	^self fragment isShared!

{BooleanVar} isPureInsert
	^self fragment isShared not! !

!InsertOperation methodsFor: 'smalltalk: printing'!

{void} printTextOn: oo {TextStream reference}
	
	oo emphasis: 2.
	oo << myFragment text! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InsertOperation class
	instanceVariableNames: ''!

(InsertOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertOperation class methodsFor: 'pseudoConstructors'!

{InsertOperation} make: s {IntegerVar} with: f {IntegerVar} with: aFragment {CompareFragment}

	^InsertOperation create: s with: f with: aFragment! !