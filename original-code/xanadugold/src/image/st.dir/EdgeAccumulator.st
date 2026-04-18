'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:06 pm'!

Accumulator subclass: #EdgeAccumulator
	instanceVariableNames: '
		myManager {EdgeManager}
		myStartsInside {BooleanVar}
		myEdges {PtrArray of: TransitionEdge}
		myIndex {Int32}
		myPending {TransitionEdge}
		myResultGiven {BooleanVar NOCOPY}'
	classVariableNames: 'SomeAccumulators {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-EdgeRegion'!

(EdgeAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!EdgeAccumulator methodsFor: 'protected: create'!

create: manager {EdgeManager} with: startsInside {BooleanVar}
	
	super create.
	myManager := manager.
	myStartsInside := startsInside.
	myEdges := PtrArray nulls: 4.
	myIndex := -1.
	myPending := NULL.
	myResultGiven := false!

create: manager {EdgeManager}
	with: startsInside {BooleanVar}
	with: edges {PtrArray of: TransitionEdge}
	with: index {Int32}
	with: pending {TransitionEdge}
	
	super create.
	myManager := manager.
	myStartsInside _ startsInside.
	myEdges _ edges.
	myIndex := index.
	myPending _ pending.
	myResultGiven := false! !

!EdgeAccumulator methodsFor: 'creation'!

{Accumulator} copy
	| result {Heaper} |
	result := SomeAccumulators fetch.
	myResultGiven := true.
	result == NULL
		ifTrue: [
			^EdgeAccumulator create: myManager
				with: myStartsInside
				with: myEdges
				with: myIndex
				with: myPending]
		ifFalse: [
			^(EdgeAccumulator new.Become: result) create: myManager
				with: myStartsInside
				with: myEdges
				with: myIndex
				with: myPending]!

{void} destroy
	(SomeAccumulators store: self) ifFalse: [super destroy]! !

!EdgeAccumulator methodsFor: 'operations'!

{void} step: someObj {Heaper}
	self edge: (someObj cast: TransitionEdge)!

{Heaper} value
	^self region! !

!EdgeAccumulator methodsFor: 'edge operations'!

{void} edge: x {TransitionEdge}
	"add a transition at the given position. doing it again cancels it"
	myPending == NULL ifTrue:
		[myPending := x]
	ifFalse:
		[(myPending isEqual: x) ifTrue:
			[myPending := NULL]
		ifFalse:
			[self storeStep: myPending.
			myPending := x]].!

{void} edges: stepper {EdgeStepper}
	"add a whole bunch of edges at once, assuming that they are sorted and there are no duplicates"
	
	"do the first step manually in case it is the same as the current edge
	then do all the rest without checking for repeats"
		
	stepper hasValue ifTrue:
		[|edge {TransitionEdge} |
		self edge: stepper fetchEdge.
		stepper step.
		[(edge := stepper fetch cast: TransitionEdge) ~~ NULL] whileTrue: [
			myPending ~~ NULL ifTrue:
				[self storeStep: myPending].
			myPending := edge.
			stepper step]]!

{XnRegion} region
	"make a region out of the accumulated edges"

	myPending ~~ NULL ifTrue:
		[self storeStep: myPending.
		myPending := NULL].
	myResultGiven := true.
	^myManager makeNew: myStartsInside with: myEdges with: myIndex + 1! !

!EdgeAccumulator methodsFor: 'private:'!

{void} storeStep: edge {TransitionEdge}
	"Just store an edge into the array and increment the count"
	
	myIndex := myIndex + 1.
	myIndex = myEdges count
		ifTrue: [
			myEdges := (myEdges copyGrow: myEdges count) cast: PtrArray.
			myResultGiven := false]
		ifFalse: [
			myResultGiven ifTrue: [
				myEdges := myEdges copy cast: PtrArray.
				myResultGiven := false]].
	myEdges at: myIndex store: edge.! !

!EdgeAccumulator methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartEdgeAccumulator: rcvr {Rcvr unused}
	myResultGiven := false! !

!EdgeAccumulator methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myManager _ receiver receiveHeaper.
	myStartsInside _ receiver receiveBooleanVar.
	myEdges _ receiver receiveHeaper.
	myIndex _ receiver receiveInt32.
	myPending _ receiver receiveHeaper.
	self restartEdgeAccumulator: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myManager.
	xmtr sendBooleanVar: myStartsInside.
	xmtr sendHeaper: myEdges.
	xmtr sendInt32: myIndex.
	xmtr sendHeaper: myPending.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EdgeAccumulator class
	instanceVariableNames: ''!

(EdgeAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!EdgeAccumulator class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeAccumulators := InstanceCache make: 8!

linkTimeNonInherited
	SomeAccumulators := NULL! !

!EdgeAccumulator class methodsFor: 'create'!

make: manager {EdgeManager} with: startsInside {BooleanVar}
	| result {Heaper} |
	result := SomeAccumulators fetch.
	result == NULL
		ifTrue: [^ self create: manager with: startsInside]
		ifFalse: [^ (self new.Become: result) create: manager with: startsInside]! !