'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:14 pm'!

Accumulator subclass: #IntegerEdgeAccumulator
	instanceVariableNames: '
		myStartsInside {BooleanVar}
		myEdges {IntegerVarArray}
		myIndex {UInt32}
		havePending {BooleanVar}
		myPending {IntegerVar}'
	classVariableNames: 'SomeAccumulators {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!

(IntegerEdgeAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!IntegerEdgeAccumulator methodsFor: 'protected: creation'!

create: startsInside {BooleanVar} with: count {UInt32}
	super create.
	myStartsInside _ startsInside.
	myEdges _ IntegerVarArray zeros: count.
	myIndex _ Int32Zero.
	havePending _ false.
	myPending _ IntegerVar0!

create: startsInside {BooleanVar} with: edges {IntegerVarArray} with: index {UInt32} with: hasPending {BooleanVar} with: pending {IntegerVar}
	super create.
	myStartsInside _ startsInside.
	myEdges _ edges.
	myIndex _ index.
	havePending _ hasPending.
	myPending _ pending! !

!IntegerEdgeAccumulator methodsFor: 'creation'!

{Accumulator} copy
	| result {Heaper} |
	result := SomeAccumulators fetch.
	result == NULL
		ifTrue: [
			^IntegerEdgeAccumulator create: myStartsInside with: myEdges with: myIndex with: havePending with: myPending]
		ifFalse: [	
				^(IntegerEdgeAccumulator new.Become: result)
					create: myStartsInside with: myEdges with: myIndex with: havePending with: myPending]!

{void} destroy
	(SomeAccumulators store: self) ifFalse: [super destroy]! !

!IntegerEdgeAccumulator methodsFor: 'operations'!

{void} step: someObj {Heaper}
	self edge: (someObj cast: IntegerPos) asIntegerVar!

{Heaper} value
	^self region! !

!IntegerEdgeAccumulator methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self region << ')'! !

!IntegerEdgeAccumulator methodsFor: 'edge operations'!

{void} edge: x {IntegerVar}
	"add a transition at the given position. doing it again cancels it.  This particular coding is used for C++ inlinability"
	havePending ifTrue:
		[myPending = x
			ifTrue:
				[havePending _ false]
			ifFalse:
				[myEdges at: myIndex storeIntegerVar: myPending.
				myIndex _ myIndex + 1.
				myPending _ x]]
	ifFalse:
		[havePending _ true.
		myPending _ x].!

{void} edges: stepper {IntegerEdgeStepper}
	"add a whole bunch of edges at once, assuming that they are sorted and there are no duplicates"
	stepper hasValue ifTrue:
		[self edge: stepper edge.
		stepper step.
		stepper hasValue ifTrue:
			[havePending ifFalse:
				[myPending _ stepper edge.
				havePending _ true.
				stepper step].
			[stepper hasValue] whileTrue:
				[myEdges at: myIndex storeIntegerVar: myPending.
				myIndex _ myIndex + 1.
				myPending _ stepper edge.
				stepper step]]]!

{IntegerRegion} region
	"make a region out of the accumulated edges"
	
	havePending ifTrue:
		[myEdges at: myIndex storeIntegerVar: myPending.
		^IntegerRegion create: myStartsInside with: myIndex + 1 with: myEdges]
	ifFalse:
		[myIndex == Int32Zero ifTrue:
			[myStartsInside
				ifTrue: [^IntegerRegion allIntegers]
				ifFalse: [^IntegerRegion make]]
		ifFalse: 
			[^IntegerRegion create: myStartsInside with: myIndex with: myEdges]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerEdgeAccumulator class
	instanceVariableNames: ''!

(IntegerEdgeAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!IntegerEdgeAccumulator class methodsFor: 'creation'!

make: startsInside {BooleanVar} with: count {UInt32}
	| result {Heaper} |
	result := SomeAccumulators fetch.
	result == NULL
		ifTrue: [^ self create: startsInside with: count]
		ifFalse: [^ (self new.Become: result) create: startsInside with: count]! !

!IntegerEdgeAccumulator class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeAccumulators := InstanceCache make: 16!

linkTimeNonInherited
	SomeAccumulators := NULL! !