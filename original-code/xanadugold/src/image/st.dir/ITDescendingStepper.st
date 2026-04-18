'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:42 pm'!

IntegerTableStepper subclass: #ITDescendingStepper
	instanceVariableNames: '
		arrayInternal {OberIntegerTable}
		indexInternal {UInt32}
		lastValueInternal {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(ITDescendingStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ITDescendingStepper methodsFor: 'create'!

{Stepper} copy
	^ITDescendingStepper
		create: (arrayInternal copy cast: ActualIntegerTable)
		with: self index
		with: arrayInternal startIndex + lastValueInternal!

create: array {OberIntegerTable} 
	super create.
	arrayInternal _ array copy cast: OberIntegerTable.
	indexInternal _ arrayInternal endOffset.
	lastValueInternal _ arrayInternal startOffset.
	self verifyEntry!

create: array {OberIntegerTable} with: index {IntegerVar} 
	super create.
	arrayInternal _ array copy cast: OberIntegerTable.
	indexInternal _ (index - arrayInternal startIndex) DOTasLong.
	lastValueInternal _ arrayInternal startOffset.
	self verifyEntry!

create: array {OberIntegerTable} with: start {IntegerVar} with: stop {IntegerVar} 
	super create.
	arrayInternal _ array copy cast: OberIntegerTable.
	indexInternal _ (start - arrayInternal startIndex) DOTasLong.
	lastValueInternal _ (stop - arrayInternal startIndex) DOTasLong.
	self verifyEntry! !

!ITDescendingStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	indexInternal >= lastValueInternal
		ifTrue: [^arrayInternal elementsArray fetch: indexInternal]
		ifFalse: [^NULL]!

{BooleanVar} hasValue
	^indexInternal >= lastValueInternal!

{void} step
	indexInternal _ indexInternal - 1.
	self verifyEntry! !

!ITDescendingStepper methodsFor: 'special'!

{IntegerVar} index
	^ arrayInternal startIndex + indexInternal!

{Position} position
	^ self index integer! !

!ITDescendingStepper methodsFor: 'private: private'!

{void} verifyEntry
	[indexInternal >= lastValueInternal and: 
			[(arrayInternal elementsArray fetch: indexInternal) == NULL]]
		whileTrue: [indexInternal _ indexInternal - 1]! !