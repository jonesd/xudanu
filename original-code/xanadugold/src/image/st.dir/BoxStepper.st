'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:07 pm'!

Stepper subclass: #BoxStepper
	instanceVariableNames: '
		myRegion {GenericCrossRegion}
		myIndex {Int32}
		myValue {XnRegion | NULL}'
	classVariableNames: 'SomeSteppers {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
BoxStepper comment:
'Steps over all boxes. was NOT.A.TYPE but this prevented compilation'!

(BoxStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoxStepper methodsFor: 'operations'!

{Heaper wimpy} fetch

	myIndex >= myRegion boxCount
		ifTrue: [^NULL].
	myValue == NULL ifTrue:
		[myValue := GenericCrossRegion
						make: myRegion crossSpace
						with: 1
						with: ((myRegion secretRegions
											copy: myRegion crossSpace axisCount
											with: myIndex * myRegion crossSpace axisCount) cast: PtrArray)].
	^myValue!

{BooleanVar} hasValue

	^myIndex < myRegion boxCount!

{void} step

	myIndex < myRegion boxCount ifTrue:
		[myIndex := myIndex + 1.
		myValue := NULL]! !

!BoxStepper methodsFor: 'create'!

{Stepper} copy
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^BoxStepper create: myRegion with: myIndex with: myValue]
		ifFalse: [^(BoxStepper new.Become: result) create: myRegion with: myIndex with: myValue]!

{void} destroy
	(SomeSteppers store: self) ifFalse: [super destroy]! !

!BoxStepper methodsFor: 'protected: create'!

create: region {GenericCrossRegion}
	
	super create.
	myRegion := region.
	myIndex := Int32Zero.
	myValue := NULL.!

create: region {GenericCrossRegion} with: index {Int32} with: value {XnRegion | NULL}
	
	super create.
	myRegion := region.
	myIndex := index.
	myValue := value.! !

!BoxStepper methodsFor: 'accessing'!

{GenericCrossRegion} boxComplement
	"The complement of this box"
	
	| result {BoxAccumulator} extrusion {PtrArray of: XnRegion} |
	result := BoxAccumulator make: myRegion crossSpace
		with: myRegion crossSpace axisCount.
	Int32Zero almostTo: myRegion crossSpace axisCount do:
		[ :dimension {Int32} | | special {XnRegion} |
		extrusion := PtrArray nulls: myRegion crossSpace axisCount.
		Int32Zero almostTo: dimension do: [ :i {Int32} |
			extrusion at: i store: (self projection: i)].
		special := (self projection: dimension) complement.
		special isEmpty ifFalse:
			[extrusion at: dimension store: special.
			dimension + 1 almostTo: myRegion crossSpace axisCount do: [ :i {Int32} |
				extrusion at: i store: (myRegion crossSpace axis: i) fullRegion].
			result addProjections: extrusion with: Int32Zero]].
	^result region cast: GenericCrossRegion!

{BoxAccumulator} boxComplementAccumulator
	"The complement of this box"
	
	| result {BoxAccumulator} extrusion {PtrArray of: XnRegion} |
	result := BoxAccumulator make: myRegion crossSpace
		with: myRegion crossSpace axisCount.
	Int32Zero almostTo: myRegion crossSpace axisCount do: [ :dimension {Int32} |
		extrusion := PtrArray nulls: myRegion crossSpace axisCount.
		Int32Zero almostTo: dimension do: [ :i {Int32} |
			extrusion at: i store: (self projection: i)].
		extrusion at: dimension store: (self projection: dimension) complement.
		dimension + 1 almostTo: myRegion crossSpace axisCount do: [ :i {Int32} |
			extrusion at: i store: (myRegion crossSpace axis: i) fullRegion].
		result addProjections: extrusion with: Int32Zero].
	^result!

{UInt32} boxHash

	| result {UInt32} |
	result := UInt32Zero.
	self projectionStepper forEach: [ :sub {XnRegion} |
		result := result bitXor: sub hashForEqual].
	^result!

{BooleanVar} boxHasMember: tuple {ActualTuple}
	"Whether my current box contains a position"
	
	| mine {BoxProjectionStepper} |
	mine := self projectionStepper.
	[mine hasValue] whileTrue:
		[(mine projection hasMember: (tuple positionAt: mine dimension)) ifFalse:
			[^false].
		mine step].
	mine destroy.
	^true!

{Int32} boxIndex

	^myIndex!

{BooleanVar} boxIntersects: other {BoxStepper}
	"Whether my current box intersects others current box"
	
	| mine {BoxProjectionStepper} others {BoxProjectionStepper} |
	mine := self projectionStepper.
	others := other projectionStepper.
	[mine hasValue] whileTrue:
		[(mine projection intersects: others projection) ifFalse:
			[^false].
		mine step.
		others step].
	mine destroy.
	others destroy.
	^true!

{BooleanVar} boxIsEqual: other {BoxStepper}
	"Whether my current box isEqual others current box"
	
	| mine {BoxProjectionStepper} others {BoxProjectionStepper} |
	mine := self projectionStepper.
	others := other projectionStepper.
	[mine hasValue] whileTrue:
		[(mine projection isEqual: others projection) ifFalse:
			[^false].
		mine step.
		others step].
	mine destroy.
	others destroy.
	^true!

{BooleanVar} boxIsSubsetOf: other {BoxStepper}
	"Whether my current box isSubsetOf others current box"
	
	| mine {BoxProjectionStepper} others {BoxProjectionStepper} |
	mine := self projectionStepper.
	others := other projectionStepper.
	[mine hasValue] whileTrue:
		[(mine projection isSubsetOf: others projection) ifFalse:
			[^false].
		mine step.
		others step].
	mine destroy.
	others destroy.
	^true!

{BooleanVar} intersectBoxInto: result {PtrArray of: XnRegion} with: boxIndex {Int32}
	"Intersect each projection in the box into the array. Return false if the result is empty, stopping at the first dimension for which the intersection is empty."
	
	| mine {BoxProjectionStepper} proj {XnRegion} base {Int32} |
	base := myRegion crossSpace axisCount * boxIndex.
	mine := self projectionStepper.
	[mine hasValue] whileTrue:
		[result at: base + mine dimension
			store: (proj := ((result fetch: base + mine dimension) cast: XnRegion)
				intersect: mine projection).
		proj isEmpty ifTrue: [^false].
		mine step].
	mine destroy.
	^true!

{BooleanVar} isBoxOf: other {GenericCrossRegion}
	"Whether my box is also a box in the other region"
	
	| others {BoxStepper} |
	others := other boxStepper.
	[others hasValue] whileTrue:
		[(self boxIsEqual: others)
			ifTrue: [^true].
		others step].
	^false!

{XnRegion} projection: dimension {Int32}
	"The projection of my current box into one dimension"
	
	^myRegion boxProjection: myIndex with: dimension!

{BoxProjectionStepper} projectionStepper
	"A stepper over all the projections in the current box"
	
	^BoxProjectionStepper make: myRegion
		with: myIndex
		with: myIndex + 1!

{GenericCrossRegion} region

	^myRegion!

{void} unionBoxInto: result {PtrArray of: XnRegion} with: boxIndex {Int32}
	"Union each projection in the box into the array"
	
	| mine {BoxProjectionStepper} base {Int32} |
	base := myRegion crossSpace axisCount * boxIndex.
	mine := self projectionStepper.
	[mine hasValue] whileTrue:
		[result at: base + mine dimension
			store: (((result fetch: base + mine dimension) cast: XnRegion)
				unionWith: mine projection).
		mine step].
	mine destroy.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BoxStepper class
	instanceVariableNames: ''!

(BoxStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoxStepper class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeSteppers := InstanceCache make: 8!

linkTimeNonInherited
	SomeSteppers := NULL! !

!BoxStepper class methodsFor: 'create'!

make: region {GenericCrossRegion}
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^ self create: region]
		ifFalse: [^ (self new.Become: result) create: region]! !