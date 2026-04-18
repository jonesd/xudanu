'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:38 pm'!

ArrayStepper subclass: #AscendingArrayStepper
	instanceVariableNames: 'lastValueInternal {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(AscendingArrayStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!AscendingArrayStepper methodsFor: 'create'!

{Stepper} copy
	^AscendingArrayStepper
		make: self array
		with: self index
		with: lastValueInternal! !

!AscendingArrayStepper methodsFor: 'protected: create'!

create: array {ActualArray}
	super create: array.
	lastValueInternal _ array endOffset!

create: array {ActualArray} with: index {IntegerVar}
	super create: array with: index.
	lastValueInternal _ array endOffset!

create: array {ActualArray} with: start {IntegerVar} with: stop {IntegerVar}
	super create: array with: start.
	lastValueInternal _ stop DOTasLong! !

!AscendingArrayStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	self hasValue
		ifTrue: [^self array elementsArray fetch: self index DOTasLong]
		ifFalse: [^NULL]!

{BooleanVar} hasValue
	^self index <= lastValueInternal!

{void} step
	self setIndex: self index DOTasLong + 1! !

!AscendingArrayStepper methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << ' on ' << (self array subTableBetween: self index with: lastValueInternal)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AscendingArrayStepper class
	instanceVariableNames: ''!

(AscendingArrayStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!AscendingArrayStepper class methodsFor: 'create'!

{TableStepper} make: array {ActualArray}
	^ self create: array!

{TableStepper} make: array {ActualArray} with: index {IntegerVar}
	^ self create: array with: index!

{TableStepper} make: array {ActualArray} with: start {IntegerVar} with: stop {IntegerVar}
	^ self create: array with: start with: stop! !