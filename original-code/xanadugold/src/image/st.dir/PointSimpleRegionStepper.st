'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:25 pm'!

Stepper subclass: #PointSimpleRegionStepper
	instanceVariableNames: '
		myY {IntegerRegion}
		myXs {Stepper}
		myPoints {PointRegion}
		myIndex {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!

(PointSimpleRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PointSimpleRegionStepper methodsFor: 'operations'!

{Heaper wimpy} fetch 
	myXs hasValue
		ifTrue: [^PointRegion make.IntegerRegion: (myXs fetch quickCast: IntegerRegion) with: myY]
		ifFalse: [^NULL]!

{BooleanVar} hasValue
	^myXs hasValue!

{void} step
	myXs step.
	self verifyStep! !

!PointSimpleRegionStepper methodsFor: 'create'!

{Stepper} copy
	^PointSimpleRegionStepper create: myY with: myXs copy with: myPoints with: myIndex!

create: points {SlicePointRegion}
	super create.
	myPoints _ points.
	points firstSlice isEmpty ifTrue:
		[myXs _ (points sliceAtIndex: Int32Zero) simpleRegions.
		myIndex _ Int32Zero]
	ifFalse:
		[myXs _ points firstSlice simpleRegions.
		myIndex _ -1].
	self computeY!

create: y {IntegerRegion} with: xs {Stepper} with: points {PointRegion} with: index {Int32}
	super create.
	myY _ y.
	myXs _ xs.
	myPoints _ points.
	myIndex _ index! !

!PointSimpleRegionStepper methodsFor: 'private: private'!

{void} computeY
	"Compute the section of the Y axis we are working on"
	| sliceRegion {SlicePointRegion wimpy} |
	sliceRegion _ myPoints cast: SlicePointRegion.
	myIndex < (sliceRegion sliceCount - 1)
		ifTrue: [myIndex < Int32Zero
			ifTrue: [myY _ IntegerRegion before: sliceRegion firstSliceKey]
			ifFalse: [myY _ IntegerRegion make: (sliceRegion sliceKeyAtIndex: myIndex)
				with: (sliceRegion sliceKeyAtIndex: myIndex + 1)]]
		ifFalse: [sliceRegion sliceCount == Int32Zero
			ifTrue: [myY _ IntegerRegion allIntegers]
			ifFalse: [myY _ IntegerRegion after: sliceRegion lastSliceKey]]!

{void} verifyStep
	"If we finished stepping across X in a given y area, then step down in y and try X again"
	| sliceRegion {SlicePointRegion} |
	sliceRegion _ myPoints cast: SlicePointRegion.
	[myXs hasValue not and: [myIndex < (sliceRegion sliceCount - 1)]] whileTrue: 
		[myIndex _ myIndex + 1.
		myXs _ (sliceRegion sliceAtIndex: myIndex) simpleRegions].
	self computeY! !