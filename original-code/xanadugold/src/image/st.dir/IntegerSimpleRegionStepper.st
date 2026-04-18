'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:18 pm'!

Stepper subclass: #IntegerSimpleRegionStepper
	instanceVariableNames: '
		myEdges {IntegerVarArray}
		myIndex {UInt32}
		myCount {UInt32}
		isLeftBounded {BooleanVar}
		mySimple {IntegerRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!

(IntegerSimpleRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!IntegerSimpleRegionStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	^mySimple!

{BooleanVar} hasValue
	^mySimple ~~ NULL!

{void} step
	isLeftBounded ifTrue: [myIndex _ myIndex + 2] ifFalse: [myIndex _ myIndex + 1].
	isLeftBounded _ true.
	myIndex < myCount
		ifTrue: [myIndex < (myCount - 1)
			ifTrue: [mySimple _ IntegerRegion make: (myEdges integerVarAt: myIndex)
				with: (myEdges integerVarAt: myIndex + 1)]
			ifFalse: [mySimple _ IntegerRegion after: (myEdges integerVarAt: myIndex)]]
		ifFalse: [mySimple _ NULL]! !

!IntegerSimpleRegionStepper methodsFor: 'unprotected create'!

create: edges {IntegerVarArray} with: count {UInt32} with: leftBounded {BooleanVar}
	super create.
	myEdges _ edges.
	myIndex _ Int32Zero.
	myCount _ count.
	isLeftBounded _ leftBounded.  
	count == Int32Zero ifTrue:
		[leftBounded ifTrue: [mySimple _ NULL] ifFalse: [mySimple _ IntegerRegion allIntegers]]
	ifFalse: [leftBounded not ifTrue:
		[mySimple _ IntegerRegion before: (edges integerVarAt: Int32Zero)]
	ifFalse: [count = 1 ifTrue:
		[mySimple _ IntegerRegion after: (edges integerVarAt: Int32Zero)]
	ifFalse:
		[mySimple _ IntegerRegion make: (edges integerVarAt: Int32Zero) with: (edges integerVarAt: 1)]]]!

create: edges {IntegerVarArray} with: index {UInt32} with: count {UInt32} with: leftBounded {BooleanVar} with: simple {IntegerRegion}
	super create.
	myEdges _ edges.
	myIndex _ index.
	myCount _ count.
	isLeftBounded _ leftBounded.
	mySimple _ simple! !

!IntegerSimpleRegionStepper methodsFor: 'create'!

{Stepper} copy
	^IntegerSimpleRegionStepper create: myEdges
		with: myIndex
		with: myCount
		with: isLeftBounded
		with: mySimple! !

!IntegerSimpleRegionStepper methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '('.
	self hasValue ifTrue: [oo << self fetch].
	oo << ')'! !