'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:07 pm'!

Stepper subclass: #BoxProjectionStepper
	instanceVariableNames: '
		myRegion {GenericCrossRegion}
		myBoxIndex {Int32}
		myBoxLimit {Int32}
		myDimension {Int32}'
	classVariableNames: 'SomeSteppers {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
BoxProjectionStepper comment:
'Steps over all projections of some boxes. was not.a.type but this prevented compilation'!

(BoxProjectionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoxProjectionStepper methodsFor: 'create'!

{Stepper} copy
	"Return a new stepper which steps independently of me, but whose current 
	value is the same as mine, and which must produce a future history of values 
	which satisfies the same obligation that my contract obligates me to produce 
	now. Typically, this will mean that he must produce the same future history 
	that I'm going to produce. However, let's say that I am enumerating the 
	elements of a partial order in some full order which is consistent with the 
	partial order. If a copy of me is made after I'm part way through, then me 
	and my copy may produce any future history compatable both with the partial 
	order and the elements I've already produced by the time of the copy. Of 
	course, a subclass or a Stepper creating message (like 
	IntegerRegion::stepper()) may specify the more stringent requirement (that a 
	copy must produce the same sequence). 
	
	To prevent aliasing, Steppers should typically be passed by copy. See class 
	comment."

	Someone shouldImplement.
	^NULL "fodder"!

{void} destroy
	(SomeSteppers store: self) ifFalse: [super destroy]! !

!BoxProjectionStepper methodsFor: 'protected: create'!

create: region {GenericCrossRegion}
	
	super create.
	myRegion := region.
	myBoxIndex := Int32Zero.
	myBoxLimit := region boxCount.
	myDimension := Int32Zero.!

create: region {GenericCrossRegion}
	with: boxIndex {Int32}
	with: boxLimit {Int32}
	
	super create.
	myRegion := region.
	myBoxIndex := boxIndex.
	myBoxLimit := boxLimit.
	myDimension := Int32Zero.!

create: region {GenericCrossRegion}
	with: boxIndex {Int32}
	with: boxLimit {Int32}
	with: dimension {Int32}
	
	super create.
	myRegion := region.
	myBoxIndex := boxIndex.
	myBoxLimit := boxLimit.
	myDimension := dimension.! !

!BoxProjectionStepper methodsFor: 'operations'!

{Heaper wimpy} fetch

	myBoxIndex < myBoxLimit ifFalse:
		[^NULL].
	^self projection!

{BooleanVar} hasValue

	^myBoxIndex < myBoxLimit!

{void} step

	myBoxIndex < myBoxLimit ifTrue:
		[myDimension := myDimension + 1.
		myDimension < myRegion crossSpace axisCount ifFalse:
			[myBoxIndex := myBoxIndex + 1.
			myDimension := Int32Zero]].! !

!BoxProjectionStepper methodsFor: 'accessing'!

{Int32} dimension

	^myDimension!

{XnRegion} projection

	^myRegion boxProjection: myBoxIndex with: myDimension! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BoxProjectionStepper class
	instanceVariableNames: ''!

(BoxProjectionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoxProjectionStepper class methodsFor: 'create'!

make: region {GenericCrossRegion}
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^ self create: region]
		ifFalse: [^ (self new.Become: result) create: region]!

make: region {GenericCrossRegion}
	with: boxIndex {Int32}
	with: boxLimit {Int32}
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^ self create: region with: boxIndex with: boxLimit]
		ifFalse: [^ (self new.Become: result) create: region with: boxIndex with: boxLimit]! !

!BoxProjectionStepper class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeSteppers := InstanceCache make: 8!

linkTimeNonInherited
	SomeSteppers := NULL! !