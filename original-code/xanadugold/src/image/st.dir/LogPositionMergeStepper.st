'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:11 pm'!

Stepper subclass: #LogPositionMergeStepper
	instanceVariableNames: '
		myAStepper {ChangeLogStepper}
		myBStepper {ChangeLogStepper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!
LogPositionMergeStepper comment:
'This class is used to merge a pair of ChangeLogStepper streams together based on the position of the current record of the steppers'!



!LogPositionMergeStepper methodsFor: 'private: operations'!

{Stepper} nextStepper

	myAStepper hasValue
		ifTrue: [myBStepper hasValue
			ifTrue: [(myAStepper position >= myBStepper position)
				ifTrue: [^ myAStepper]
				ifFalse: [^ myBStepper]]
			ifFalse: [^ myAStepper]]
		ifFalse: [^ myBStepper]! !

!LogPositionMergeStepper methodsFor: 'operations'!

{Heaper} fetch

	^ self nextStepper fetch!

{BooleanVar} hasValue
	^ self nextStepper hasValue!

{void} step
	"If I am currently exhausted (see Stepper::hasValue()), then it is an error to 
	step me. The result of doing so isn't currently specified (we probably should 
	specify it to BLAST, but I know that the implementation doesn't currently live 
	up to that spec). 
	
	If I am not exhausted, then this advances me to my next state. If my current 
	value (see Stepper::get()) was my final value, then I am now exhausted, 
	otherwise my new current value is the next value."

	self nextStepper hasValue 
		ifTrue: [self nextStepper step]
		ifFalse: [self error: 'hasValue is FALSE']! !

!LogPositionMergeStepper methodsFor: 'create'!

{Stepper} copy
	
	^ self class create: myAStepper copy with: myBStepper copy!

create: a {ChangeLogStepper} with: b {ChangeLogStepper}

	super create.
	myAStepper _ a.
	myBStepper _ b! !