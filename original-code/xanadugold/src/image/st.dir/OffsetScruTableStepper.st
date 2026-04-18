'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:44 pm'!

TableStepper subclass: #OffsetScruTableStepper
	instanceVariableNames: '
		myTableStepper {TableStepper}
		myDsp {Dsp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Steppers'!

(OffsetScruTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!OffsetScruTableStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	^ myTableStepper fetch!

{Heaper wimpy} get
	^ myTableStepper get!

{BooleanVar} hasValue
	^myTableStepper hasValue!

{void} step
	myTableStepper step! !

!OffsetScruTableStepper methodsFor: 'special'!

{IntegerVar} index
	^myDsp ofInt: myTableStepper index!

{Position} position
	^myDsp of: myTableStepper position! !

!OffsetScruTableStepper methodsFor: 'create'!

{Stepper} copy
	^ OffsetScruTableStepper create.Stepper: (myTableStepper copy cast: TableStepper) with: myDsp!

create.Stepper: onStepper {TableStepper} with: aDsp {Dsp} 
	
	super create.
	myTableStepper _ onStepper.
	myDsp _ aDsp! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OffsetScruTableStepper class
	instanceVariableNames: ''!

(OffsetScruTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!OffsetScruTableStepper class methodsFor: 'smalltalk: smalltalk creation'!

create.Stepper: aStepper with: aDsp
	^ self new create.Stepper: aStepper with: aDsp! !