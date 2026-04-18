'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:33 pm'!

Stepper subclass: #EmptyStepper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-stepper'!
EmptyStepper comment:
'This is a Stepper when you just want to step across a single item.'!

(EmptyStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!EmptyStepper methodsFor: 'protected: destruct'!

{void} destruct
	"This object is a canonical single instance, so its destructor should only be called after main has exited."

	'if (!!Initializer::inStaticDestruction()) BLAST(SanityViolation);' translateOnly.
	super destruct! !

!EmptyStepper methodsFor: 'create'!

{Stepper} copy
	^ self!

{void} destroy
	"No"! !

!EmptyStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	^ NULL!

{BooleanVar} hasValue
	^ false!

{void} step! !