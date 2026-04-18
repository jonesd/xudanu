'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:28 pm'!

Stepper subclass: #SliceStepper
	instanceVariableNames: '
		myIndex {Int4}
		myPoints {SlicePointRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!
SliceStepper comment:
'Walk along one dimension of a nest region, fetching orthogonal slices.  the region message is one off the fetch message: before the first step, it represents the region before the first index.  After the last step, it represents the region after the last index.'!

(SliceStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SliceStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	self hasValue
		ifTrue: [^myPoints sliceAtIndex: myIndex]
		ifFalse: [^NULL]!

{BooleanVar} hasValue
	^myIndex < myPoints sliceCount!

{IntegerRegion} region
	^myPoints sliceAtIndex: myIndex!

{IntegerRegion} slice
	^myPoints sliceAtIndex: myIndex!

{void} step
	myIndex _ myIndex + 1!

{IntegerVar} y
	^myPoints sliceKeyAtIndex: myIndex! !

!SliceStepper methodsFor: 'create'!

{Stepper} copy
	^SliceStepper create: myIndex with: myPoints!

create: points {SlicePointRegion}
	super create.
	myIndex _ Int32Zero.
	myPoints _ points!

create: index {Int32} with: points {SlicePointRegion}
	super create.
	myIndex _ index.
	myPoints _ points! !

!SliceStepper methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '('.
	self hasValue ifTrue:
		[oo << self y << ' -> ' << self slice].
	oo << ')'! !