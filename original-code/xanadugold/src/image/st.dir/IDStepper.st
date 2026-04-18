'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:21 pm'!

Stepper subclass: #IDStepper
	instanceVariableNames: '
		myRegion {IDRegion}
		myBackends {Stepper | NULL of: Sequence}
		myIDs {Stepper | NULL of: IntegerPos}
		myValue {ID | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-id'!

(IDStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!IDStepper methodsFor: 'create'!

{Stepper} copy
	
	^IDStepper create: myRegion with: myBackends copy with: myIDs copy!

create: region {IDRegion}

	super create.
	myRegion := region.
	myBackends := region backends stepper.
	myBackends hasValue
		ifTrue: [myIDs := (region iDNumbersFrom: (myBackends fetch cast: Sequence)) stepper]
		ifFalse: [myIDs := NULL. myBackends := NULL].
	myValue := NULL.!

create: region {IDRegion} with: backends {Stepper of: Sequence} with: iDs {Stepper of: IntegerPos}
	super create.
	myRegion := region.
	myBackends := backends.
	myIDs := iDs.
	myValue := NULL.! !

!IDStepper methodsFor: 'operations'!

{Heaper wimpy} fetch

	(myValue == NULL and: [myBackends ~~ NULL]) ifTrue:
		[myValue := ID using: myRegion fetchSpace
			with: (myBackends fetch cast: Sequence)
			with: (myIDs fetch cast: IntegerPos) asIntegerVar].
	^myValue!

{BooleanVar} hasValue

	^myBackends ~~ NULL!

{void} step
	myBackends ~~ NULL ifTrue:
		[myValue := NULL.
		myIDs step.
		myIDs hasValue ifFalse:
			[myBackends step.
			myBackends hasValue ifFalse:
				[myBackends := NULL.
				myIDs := NULL.
				^VOID].
			myIDs := (myRegion iDNumbersFrom: (myBackends fetch cast: Sequence)) stepper]]! !