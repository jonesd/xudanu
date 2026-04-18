'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:27 pm'!

Accumulator subclass: #SliceAccumulator
	instanceVariableNames: '
		myFirstSlice {IntegerRegion}
		mySliceKeys {IntegerVarArray}
		mySliceRegions {PtrArray of: IntegerRegion}
		myIndex {Int32}
		myCount {Int32}
		myLastSlice {IntegerRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!

(SliceAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SliceAccumulator methodsFor: 'operations'!

{void} step: something {Heaper as: (Pair of: IntegerPos and: IntegerRegion)}
	self slice: ((something cast: Pair) left cast: IntegerPos) asIntegerVar
		with: ((something cast: Pair) right cast: IntegerRegion)!

{Heaper} value
	^self region! !

!SliceAccumulator methodsFor: 'slice accessing'!

{PointRegion} region
	^SlicePointRegion create: myFirstSlice with: myIndex
			with: mySliceKeys with: mySliceRegions!

{void} slice: y {IntegerVar} with: slice {IntegerRegion}
	(myLastSlice isEqual: slice) ifFalse:
		[mySliceKeys at: myIndex storeIntegerVar: y.
		mySliceRegions at: myIndex store: slice.
		myIndex _ myIndex + 1.
		myLastSlice _ slice]! !

!SliceAccumulator methodsFor: 'creation'!

{Accumulator} copy
	^SliceAccumulator create: myFirstSlice
			with: ((mySliceKeys copy: myCount) cast: IntegerVarArray)
			with: ((mySliceRegions copy: myCount) cast: PtrArray)
			with: myIndex
			with: myCount
			with: myLastSlice!

create: first {IntegerRegion} with: count {Int32}
	super create.
	myFirstSlice _ first.
	mySliceKeys _ IntegerVarArray zeros: (count max: 1).
	mySliceRegions _ PtrArray nulls: (count max: 1).
	myIndex _ Int32Zero.
	myCount _ count.
	myLastSlice _ first!

create: first {IntegerRegion} with: keys {IntegerVarArray} with: slices {PtrArray of: IntegerRegion} with: index {Int32} with: count {Int32} with: last {IntegerRegion}
	super create.
	myFirstSlice _ first.
	mySliceKeys _ keys.
	mySliceRegions _ slices.
	myIndex _ index.
	myCount _ count.
	myLastSlice _ last! !

!SliceAccumulator methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self region << ')'! !