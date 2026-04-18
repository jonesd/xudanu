'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:06 pm'!

Stepper subclass: #EdgeSimpleRegionStepper
	instanceVariableNames: '
		myManager {EdgeManager}
		myEdges {EdgeStepper}
		mySimple {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-EdgeRegion'!
EdgeSimpleRegionStepper comment:
'Consider this a "protected" class.  See class comment in EdgeAccumulator'!

(EdgeSimpleRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EdgeSimpleRegionStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	^mySimple!

{BooleanVar} hasValue
	^mySimple ~~ NULL!

{void} step

	| startsInside {BooleanVar} one {TransitionEdge} two {TransitionEdge} |
	"if there are no more edges
		then the stepper is empty
		
	remember whether we're entering or leaving the region
	fetch the first edge
	if there is no first edge
		then remember the edges are gone
		if we were already in the region
			then there is the full region
			else we're empty
	else there is a first edge, so
		if we start outside and there is another edge
			then get it and make a two-sided region
			else make a one-side region"
	
	myEdges == NULL ifTrue:
		[mySimple := NULL.
		^VOID].
	
	startsInside := myEdges isEntering not.
	one := myEdges fetchEdge.
	one == NULL ifTrue:
		[myEdges := NULL.
		(startsInside and: [mySimple == NULL]) ifTrue:
			[mySimple := myManager makeNew: true with: PtrArray empty]
		ifFalse:
			[mySimple := NULL]]
	ifFalse:
		[myEdges step.
		(startsInside not and: [myEdges hasValue]) ifTrue:
			[two := myEdges fetchEdge.
			myEdges step.
			mySimple := myManager makeNew: startsInside
				with: ((PrimSpec pointer arrayWithTwo: one with: two) cast: PtrArray)]
		ifFalse:
			[mySimple := myManager makeNew: startsInside
				with: ((PrimSpec pointer arrayWith: one) cast: PtrArray)]].! !

!EdgeSimpleRegionStepper methodsFor: 'create'!

{Stepper} copy
	| step {EdgeStepper} |
	"can't to ?: with SPTRs"
	step := myEdges.
	step ~~ NULL ifTrue:
		[step := myEdges copy cast: EdgeStepper].
	^ EdgeSimpleRegionStepper create: myManager with: step with: mySimple! !

!EdgeSimpleRegionStepper methodsFor: 'protected: create'!

create: manager {EdgeManager} with: edges {EdgeStepper}

	super create.
	myManager := manager.
	myEdges := edges.
	mySimple := NULL.
	self step.!

create: manager {EdgeManager}
	with: edges {EdgeStepper | NULL}
	with: simple {XnRegion | NULL}
	
	super create.
	myManager := manager.
	myEdges := edges.
	mySimple := simple! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EdgeSimpleRegionStepper class
	instanceVariableNames: ''!

(EdgeSimpleRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EdgeSimpleRegionStepper class methodsFor: 'create'!

make: manager {EdgeManager} with: edges {EdgeStepper}
	^ self create: manager with: edges! !