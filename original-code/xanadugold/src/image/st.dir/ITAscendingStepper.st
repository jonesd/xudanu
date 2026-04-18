'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:42 pm'!

IntegerTableStepper subclass: #ITAscendingStepper
	instanceVariableNames: '
		arrayInternal {OberIntegerTable}
		indexInternal {UInt32}
		lastValueInternal {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(ITAscendingStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ITAscendingStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	(indexInternal <= lastValueInternal)
		ifTrue: [^arrayInternal elementsArray fetch: indexInternal]
		ifFalse: [^NULL]!

{BooleanVar} hasValue
	^ indexInternal <= lastValueInternal!

{void} step
	indexInternal _ indexInternal + 1.
	[indexInternal <= lastValueInternal and: 
			[(arrayInternal elementsArray fetch: indexInternal) == NULL]]
		whileTrue: [indexInternal _ indexInternal + 1]! !

!ITAscendingStepper methodsFor: 'create'!

{Stepper} copy
	^ITAscendingStepper
		create: (arrayInternal copy cast: OberIntegerTable)
		with: self index
		with: arrayInternal startIndex + lastValueInternal!

create: array {OberIntegerTable}
	super create.
	arrayInternal _ (array copy cast: OberIntegerTable).
	indexInternal _ arrayInternal startOffset.
	lastValueInternal _ arrayInternal endOffset.
	self verifyEntry!

create: array {OberIntegerTable} with: index {IntegerVar}
	super create.
	arrayInternal _ (array copy cast: OberIntegerTable).
	indexInternal _ (index - arrayInternal startIndex) DOTasLong.
	lastValueInternal _ arrayInternal endOffset.
	self verifyEntry!

create: array {OberIntegerTable} with: start {IntegerVar} with: stop {IntegerVar} 
	"n.b. !!!!!!!! This constructor DOES NOT COPY the table because this 
	constructor is used by the table copy (which creates a stepper). 
	The copy is done in the table->stepper(NULL) routine before calling 
	this constructor."

	super create.
	arrayInternal _ array.
	indexInternal _ (start - arrayInternal startIndex) DOTasLong.
	lastValueInternal _ (stop - arrayInternal startIndex) DOTasLong.
	self verifyEntry! !

!ITAscendingStepper methodsFor: 'special'!

{IntegerVar} index
	^arrayInternal startIndex + indexInternal!

{Position} position
	^ self index integer! !

!ITAscendingStepper methodsFor: 'private: private'!

{void} verifyEntry
	[indexInternal <= lastValueInternal and: 
			[(arrayInternal elementsArray fetch: indexInternal) == NULL]]
		whileTrue: [indexInternal _ indexInternal + 1]! !