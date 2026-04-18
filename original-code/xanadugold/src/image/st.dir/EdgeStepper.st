'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:07 pm'!

Stepper subclass: #EdgeStepper
	instanceVariableNames: '
		myEntering {BooleanVar}
		myEdges {PtrArray of: TransitionEdge}
		myEdgesCount {Int32}
		myIndex {Int32}'
	classVariableNames: 'SomeEdgeSteppers {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-EdgeRegion'!
EdgeStepper comment:
'A single instance of this class is cached.  To take advantage of this, a method
that uses EdgeSteppers should explicitly destroy at least one of them.
Consider this a "protected" class.  See class comment in EdgeAccumulator.'!

(EdgeStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EdgeStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch

	myIndex < myEdgesCount
		ifTrue: [^myEdges fetch: myIndex]
		ifFalse: [^NULL]!

{BooleanVar} hasValue

	^myIndex < myEdgesCount!

{void} step

	self hasValue ifTrue:
		[myEntering := myEntering not.
		myIndex := myIndex + 1]! !

!EdgeStepper methodsFor: 'edge accessing'!

{TransitionEdge | NULL} fetchEdge

	myIndex < myEdgesCount
		ifTrue: [^(myEdges fetch: myIndex) cast: TransitionEdge]
		ifFalse: [^NULL]!

{TransitionEdge} getEdge

	myIndex < myEdgesCount
		ifTrue: [^(myEdges fetch: myIndex) cast: TransitionEdge]
		ifFalse: [Heaper BLAST: #EmptyStepper].
	^NULL "fodder"!

{BooleanVar} isEntering
	"whether the current transition is entering or leaving the set"
	^myEntering! !

!EdgeStepper methodsFor: 'protected: create'!

create: entering {BooleanVar} with: edges {PtrArray of: TransitionEdge} with: count {Int32}

	super create.
	myEntering := entering.
	myEdges := edges.
	myEdgesCount := count.
	myIndex := Int32Zero!

create: entering {BooleanVar} with: edges {PtrArray of: TransitionEdge} with: count {Int32} with: index {Int32}

	super create.
	myEntering := entering.
	myEdges := edges.
	myEdgesCount := count.
	myIndex := index! !

!EdgeStepper methodsFor: 'create'!

{Stepper} copy

	^EdgeStepper create: myEntering
		with: myEdges
		with: myEdgesCount
		with: myIndex! !

!EdgeStepper methodsFor: 'destroy'!

{void} destroy
	(SomeEdgeSteppers store: self) ifFalse:
		[super destroy]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EdgeStepper class
	instanceVariableNames: ''!

(EdgeStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EdgeStepper class methodsFor: 'create'!

make: entering {BooleanVar} with: edges {PtrArray of: TransitionEdge}
	| result {Heaper} |
	result := SomeEdgeSteppers fetch.
	result == NULL ifTrue: [
		^ self create: entering with: edges with: edges count]
	ifFalse: [
		^ (self new.Become: result) create: entering with: edges with: edges count]!

make: entering {BooleanVar} with: edges {PtrArray of: TransitionEdge} with: count {Int32}
	| result {Heaper} |
	result := SomeEdgeSteppers fetch.
	result == NULL ifTrue: [
		^ self create: entering with: edges with: count]
	ifFalse: [
		^ (self new.Become: result) create: entering with: edges with: count]! !

!EdgeStepper class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeEdgeSteppers := InstanceCache make: 16!

linkTimeNonInherited
	SomeEdgeSteppers := NULL! !