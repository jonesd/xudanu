'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:42 pm'!

Stepper subclass: #PathRegionStepper
	instanceVariableNames: '
		myRegion {PathRegion}
		myKeyStepper {Stepper of: XuPosition}
		mySubStepper {Stepper of: XuPosition}
		myLastItem {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-path'!
PathRegionStepper comment:
'Iterates over all elements of a PathRegion usinga top-level stepper on the keys, and a sub stepper on the subordinate region`s Positions.'!

(PathRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!PathRegionStepper methodsFor: 'operations'!

{Heaper wimpy} fetch

	(myLastItem == NULL and: [myKeyStepper hasValue]) ifTrue:
		[myLastItem := PathPosition make: (myKeyStepper get cast: Position)
			with: (mySubStepper get cast: Position)].
	^myLastItem!

{BooleanVar} hasValue

	^myKeyStepper hasValue!

{void} step

	myKeyStepper hasValue ifTrue:
		[mySubStepper step.
		mySubStepper hasValue ifFalse:
			[myKeyStepper step.
			myKeyStepper hasValue ifTrue:
				[mySubStepper := (myRegion
					getSubRegion: (myKeyStepper get cast: Position)) stepper]]]! !

!PathRegionStepper methodsFor: 'create'!

{Stepper} copy

	^PathRegionStepper create: myRegion
		with: myKeyStepper copy
		with: mySubStepper copy
		with: myLastItem!

create: region {PathRegion}
	
	super create.
	myRegion := region.
	myKeyStepper := region keys stepper.
	myKeyStepper hasValue ifTrue:
		[mySubStepper := (region getSubRegion: (myKeyStepper get cast: Position)) stepper]
	ifFalse:
		[mySubStepper := NULL].
	myLastItem := NULL.!

create: region {PathRegion}
	with: keyStepper {Stepper}
	with: subStepper {Stepper}
	with: lastItem {Heaper}
	
	super create.
	myRegion := region.
	myKeyStepper := keyStepper.
	mySubStepper := subStepper.
	myLastItem := lastItem.! !