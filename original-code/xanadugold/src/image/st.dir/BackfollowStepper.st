'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:39 pm'!

TableStepper subclass: #BackfollowStepper
	instanceVariableNames: '
		stepperInternal {TableStepper}
		valueInternal {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(BackfollowStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BackfollowStepper methodsFor: 'operations'!

{Heaper wimpy | NULL} fetch
	^stepperInternal fetch!

{Heaper wimpy} get
	^stepperInternal get!

{BooleanVar} hasValue
	^stepperInternal hasValue!

{void} step
	stepperInternal step.
	self verifyEntry! !

!BackfollowStepper methodsFor: 'special'!

{IntegerVar} index
	^stepperInternal index!

{Position} position
	^stepperInternal position! !

!BackfollowStepper methodsFor: 'create'!

{Stepper} copy
	^BackfollowStepper create: (stepperInternal copy cast: TableStepper) with: valueInternal!

create: stepper {TableStepper} with: value {Heaper}
	super create.
	stepperInternal _ stepper.
	valueInternal _ value.
	self verifyEntry! !

!BackfollowStepper methodsFor: 'private: private'!

{void} verifyEntry
	| flag {BooleanVar} |
	flag _ true.
	[flag and: [stepperInternal hasValue]]
		whileTrue: [(flag _ (stepperInternal fetch isEqual: valueInternal) not)
						ifTrue: [stepperInternal step]]! !