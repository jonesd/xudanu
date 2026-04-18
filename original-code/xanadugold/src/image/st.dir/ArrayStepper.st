'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:38 pm'!

TableStepper subclass: #ArrayStepper
	instanceVariableNames: '
		arrayInternal {ActualArray}
		indexInternal {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(ArrayStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!ArrayStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	self subclassResponsibility!

{Heaper wimpy} get
	^arrayInternal intGet: indexInternal!

{BooleanVar} hasValue
	self subclassResponsibility!

{void} step
	self subclassResponsibility! !

!ArrayStepper methodsFor: 'special'!

{IntegerVar} index
	^indexInternal!

{Position} position
	^indexInternal integer! !

!ArrayStepper methodsFor: 'protected: accessing'!

{ActualArray} array
	^arrayInternal!

{void} setIndex: i {Int32}
	indexInternal _ i! !

!ArrayStepper methodsFor: 'create'!

{Stepper} copy
	self subclassResponsibility! !

!ArrayStepper methodsFor: 'protected: create'!

create: array {MuArray}
	super create.
	arrayInternal _ array copy cast: ActualArray.
	indexInternal _ Int32Zero!

create: array {MuArray} with: index {IntegerVar}
	super create.
	arrayInternal _ array copy cast: ActualArray.
	indexInternal _ index DOTasLong! !