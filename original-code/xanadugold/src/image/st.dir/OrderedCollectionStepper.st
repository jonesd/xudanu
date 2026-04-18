'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:44 pm'!

TableStepper subclass: #OrderedCollectionStepper
	instanceVariableNames: 'arrayInternal indexInternal '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!


!OrderedCollectionStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	^indexInternal <= arrayInternal size
		ifTrue: [arrayInternal at: indexInternal]
		ifFalse: [NULL]!

{Heaper wimpy} get
	^arrayInternal at: indexInternal!

{BooleanVar} hasValue
	^indexInternal <= arrayInternal size and: [(arrayInternal at: indexInternal) ~~ nil]!

{void} step
	indexInternal _ indexInternal + 1.
	self verifyEntry! !

!OrderedCollectionStepper methodsFor: 'special'!

{IntegerVar} index
	^indexInternal!

{Position} key
	^indexInternal integer!

{Position} position
	^indexInternal integer! !

!OrderedCollectionStepper methodsFor: 'create'!

{Stepper} copy
	^OrderedCollectionStepper create: arrayInternal with: indexInternal!

create: array {OrderedCollection}
	arrayInternal _ array.
	indexInternal _ 1.
	self verifyEntry!

create: array {ScruTable} with: index {IntegerVar}
	arrayInternal _ array.
	indexInternal _ index.
	self verifyEntry! !

!OrderedCollectionStepper methodsFor: 'private: private'!

{void} verifyEntry
	[indexInternal <= arrayInternal size and: [(arrayInternal at: indexInternal) == NULL]]
		whileTrue: [indexInternal _ indexInternal + 1]! !