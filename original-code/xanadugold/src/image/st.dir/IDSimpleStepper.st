'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:21 pm'!

Stepper subclass: #IDSimpleStepper
	instanceVariableNames: '
		myRegion {IDRegion}
		myBackends {Stepper | NULL of: Sequence}
		myIDs {Stepper | NULL of: (XnRegion of: Integer)}
		myValue {IDRegion | NULL}
		myInexplicit {IDRegion | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-id'!

(IDSimpleStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!IDSimpleStepper methodsFor: 'create'!

{Stepper} copy
	
	^IDSimpleStepper create: myRegion with: myBackends copy with: myIDs copy with: myInexplicit!

create: region {IDRegion}

	super create.
	myRegion := region.
	myBackends := region explicitBackends stepper.
	myBackends hasValue
		ifTrue: [myIDs := (region iDNumbersFrom: (myBackends fetch cast: Sequence)) simpleRegions]
		ifFalse: [myIDs := NULL. myBackends := NULL].
	myValue := NULL.
	myInexplicit := region fetchInexplicit!

create: region {IDRegion} with: backends {Stepper of: Sequence} with: iDs {Stepper of: XnRegion} with: inexplicit {IDRegion | NULL}

	super create.
	myRegion := region.
	myBackends := backends.
	myIDs := iDs.
	myValue := NULL.
	myInexplicit := inexplicit.! !

!IDSimpleStepper methodsFor: 'operations'!

{Heaper wimpy} fetch

	myInexplicit ~~ NULL ifTrue:
		[^myInexplicit].
	(myValue == NULL and: [myBackends ~~ NULL]) ifTrue:
		[myValue := (myRegion coordinateSpace cast: IDSpace)
			oldIDs: (myBackends fetch cast: Sequence)
			with: (myIDs fetch cast: IntegerRegion)].
	^myValue!

{BooleanVar} hasValue

	^myInexplicit ~~ NULL or: [myBackends ~~ NULL]!

{void} step
	myInexplicit ~~ NULL ifTrue:
		[myInexplicit := NULL]
	ifFalse: [myBackends ~~ NULL ifTrue:
		[myValue := NULL.
		myIDs step.
		myIDs hasValue ifFalse:
			[myBackends step.
			myBackends hasValue ifFalse:
				[myBackends := NULL.
				myIDs := NULL.
				^VOID].
			myIDs := (myRegion iDNumbersFrom: (myBackends fetch cast: Sequence)) simpleRegions]]]! !