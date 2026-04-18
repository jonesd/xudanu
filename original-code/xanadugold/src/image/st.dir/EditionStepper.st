'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:44 pm'!

TableStepper subclass: #EditionStepper
	instanceVariableNames: '
		myKeys {Stepper of: Position}
		myEdition {FeEdition}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nbacken'!

(EditionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!EditionStepper methodsFor: 'create'!

{Stepper} copy

	^EditionStepper create: myKeys copy with: myEdition!

create: keys {Stepper of: Position} with: edition {FeEdition}
	
	super create.
	myKeys := keys.
	myEdition := edition.! !

!EditionStepper methodsFor: 'special'!

{Position} position

	^myKeys get cast: Position! !

!EditionStepper methodsFor: 'operations'!

{Heaper wimpy} fetch

	myKeys hasValue
		ifTrue: [^myEdition get: (myKeys fetch cast: Position)]
		ifFalse: [^NULL]!

{BooleanVar} hasValue

	^myKeys hasValue!

{void} step
	myKeys step! !