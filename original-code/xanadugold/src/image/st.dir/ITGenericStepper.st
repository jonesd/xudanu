'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:43 pm'!

IntegerTableStepper subclass: #ITGenericStepper
	instanceVariableNames: '
		arrayInternal {IntegerTable}
		indexInternal {IntegerVar}
		lastValueInternal {IntegerVar}
		incrementInternal {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(ITGenericStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ITGenericStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	self hasValue
		ifTrue: [^ arrayInternal intFetch: indexInternal]
		ifFalse: [^NULL]!

{BooleanVar} hasValue
	^(incrementInternal > Int32Zero and: [indexInternal <= lastValueInternal])
		or: [incrementInternal < Int32Zero and: [indexInternal >= lastValueInternal]]!

{void} step
	indexInternal _ indexInternal + incrementInternal.
	self verifyEntry! !

!ITGenericStepper methodsFor: 'special'!

{IntegerVar} index
	^indexInternal!

{Position} position
	^indexInternal integer! !

!ITGenericStepper methodsFor: 'create'!

{Stepper} copy
	^ITGenericStepper
		create: arrayInternal
		with: indexInternal
		with: lastValueInternal
		with: incrementInternal!

create: array {IntegerTable}
	super create.
	arrayInternal _ (array copy cast: IntegerTable).
	indexInternal _ IntegerVar0.
	lastValueInternal _ arrayInternal highestIndex.
	incrementInternal _ 1!

create: onTable {IntegerTable} with.OrderSpec: anOrder {OrderSpec} 
	
	super create.
	(anOrder followsInt: 1 with: IntegerVar0)
		ifTrue: "order is ascending"
			[arrayInternal _ (onTable copy cast: IntegerTable).
			indexInternal _ onTable lowestIndex.
			lastValueInternal _ onTable highestIndex.
			incrementInternal _ 1]
		ifFalse: "order is descending"
			[arrayInternal _ (onTable copy cast: IntegerTable).
			indexInternal _ onTable highestIndex.
			lastValueInternal _ onTable lowestIndex.
			incrementInternal _ -1]!

create: array {IntegerTable} with: index {IntegerVar}
	super create.
	arrayInternal _ array copy cast: IntegerTable.
	indexInternal _ index.
	lastValueInternal _ arrayInternal highestIndex.
	incrementInternal _ 1!

create: array {IntegerTable} with: start {IntegerVar} with: stop {IntegerVar}
	super create.
	arrayInternal _ array copy cast: IntegerTable.
	indexInternal _ start.
	lastValueInternal _ stop.
	incrementInternal _ 1!

create: array {IntegerTable} with: start {IntegerVar} with: stop {IntegerVar} with: direction {IntegerVar}
	super create.
	arrayInternal _ array copy cast: IntegerTable.
	indexInternal _ start.
	lastValueInternal _ stop.
	incrementInternal _ direction DOTasLong! !

!ITGenericStepper methodsFor: 'private: private'!

{void} verifyEntry
	| notDone {BooleanVar} |
	notDone _ true.
	[notDone]
		whileTrue: [
			((incrementInternal > Int32Zero and: [indexInternal < lastValueInternal])
					or: [incrementInternal < Int32Zero and: [indexInternal >= lastValueInternal]])
				ifTrue: [(arrayInternal intFetch: indexInternal) == NULL
						ifTrue: [indexInternal _ indexInternal + incrementInternal]
						ifFalse: [notDone _ false]]
				ifFalse: [notDone _ false]]! !