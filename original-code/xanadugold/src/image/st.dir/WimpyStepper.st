'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:34 pm'!

Stepper subclass: #WimpyStepper
	instanceVariableNames: 'myStepper {Stepper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Wimpy'!

(WimpyStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!WimpyStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	| result {Heaper} |
	result _ myStepper fetch.
	result ~~ NULL ifTrue: [result _ (result cast: WimpyCell) value].
	^result!

{BooleanVar} hasValue
	^myStepper hasValue!

{void} step
	myStepper step! !

!WimpyStepper methodsFor: 'create'!

{Stepper} copy
	^WimpyStepper create: myStepper copy!

create: stepper {Stepper}
	super create.
	myStepper _ stepper! !