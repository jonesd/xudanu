'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:44 pm'!

TableStepper subclass: #OffsetArrayStepper
	instanceVariableNames: '
		myArrayStepper {TableStepper}
		myDsp {Dsp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(OffsetArrayStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!OffsetArrayStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	^ myArrayStepper fetch!

{Heaper wimpy} get
	^ myArrayStepper get!

{BooleanVar} hasValue
	^myArrayStepper hasValue!

{void} step
	myArrayStepper step! !

!OffsetArrayStepper methodsFor: 'special'!

{IntegerVar} index
	^myDsp ofInt: myArrayStepper index!

{Position} position
	^myDsp of: myArrayStepper position! !

!OffsetArrayStepper methodsFor: 'protected: create'!

create.Stepper: onStepper {TableStepper} with: aDsp {Dsp} 
	
	super create.
	myArrayStepper _ onStepper.
	myDsp _ aDsp! !

!OffsetArrayStepper methodsFor: 'create'!

{Stepper} copy
	^ OffsetArrayStepper make: (myArrayStepper copy cast: TableStepper) with: myDsp! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OffsetArrayStepper class
	instanceVariableNames: ''!

(OffsetArrayStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!OffsetArrayStepper class methodsFor: 'smalltalk: creation'!

create.Stepper: aStepper
	^ self new create.Stepper: aStepper!

create.Stepper: aStepper with: aDsp
	^ self new create.Stepper: aStepper with: aDsp! !

!OffsetArrayStepper class methodsFor: 'create'!

{TableStepper} make: arrayStepper {TableStepper} with: aDsp {Dsp} 
	^self create.Stepper: arrayStepper with: aDsp! !