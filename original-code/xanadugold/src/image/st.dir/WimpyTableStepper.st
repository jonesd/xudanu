'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:28 pm'!

TableStepper subclass: #WimpyTableStepper
	instanceVariableNames: 'myStepper {TableStepper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-stuff'!

(WimpyTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!WimpyTableStepper methodsFor: 'create'!

{Stepper} copy
	^WimpyTableStepper create: (myStepper copy cast: TableStepper)!

create: stepper {TableStepper}
	super create.
	myStepper _ stepper! !

!WimpyTableStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	| result {Heaper} |
	result _ myStepper fetch.
	result == NULL ifTrue: [^NULL].
	^ (result cast: WimpyCell) value!

{BooleanVar} hasValue
	^myStepper hasValue!

{void} step

	myStepper step! !

!WimpyTableStepper methodsFor: 'special'!

{Position} position
	^myStepper position! !