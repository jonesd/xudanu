'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:45 pm'!

Accumulator subclass: #BoxAccumulator
	instanceVariableNames: '
		mySpace {CrossSpace}
		myRegions {PtrArray of: XnRegion}
		myIndex {Int32}'
	classVariableNames: 'SomeAccumulators {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-cross'!
BoxAccumulator comment:
'was NOT.A.TYPE but this prevented compilation '!

(BoxAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoxAccumulator methodsFor: 'creation'!

{Accumulator} copy
	| result {Heaper} |
	result := SomeAccumulators fetch.
	result == NULL
		ifTrue: [^BoxAccumulator create: mySpace with: (myRegions copy cast: PtrArray) with: myIndex]
		ifFalse: [^(BoxAccumulator new.Become: result) create: mySpace with: (myRegions copy cast: PtrArray) with: myIndex]! !

!BoxAccumulator methodsFor: 'protected: creation'!

create: region {GenericCrossRegion}

	super create.
	mySpace := region crossSpace.
	myRegions := region secretRegions copy cast: PtrArray.
	myIndex := region boxCount.!

create: space {CrossSpace} with: expectedBoxCount {Int32}

	super create.
	mySpace := space.
	myRegions := PtrArray nulls: space axisCount * expectedBoxCount.
	myIndex := Int32Zero.!

create: space {CrossSpace}
	with: regions {PtrArray unused of: XnRegion}
	with: expectedBoxCount {Int32}

	super create.
	mySpace := space.
	myRegions := PtrArray nulls: space axisCount * expectedBoxCount.
	myIndex := Int32Zero.
	Ravi shouldImplement. "shouldn't we be doing something with the 'regios' argument?"! !

!BoxAccumulator methodsFor: 'private:'!

{void} aboutToAdd
	"Make sure there is room to add a box"
	
	myIndex * mySpace axisCount < myRegions count ifFalse:
		[myRegions := (myRegions copyGrow: (myIndex + 1) * mySpace axisCount) cast: PtrArray].!

{Int32} addSubstitutedBox: current {Int32} with: dimension {Int32}
	with: newRegion {XnRegion}
	"Add a new box which is just like a current one except for the projection on one dimension. Return its index"
	
	self aboutToAdd.
	myRegions at: myIndex * mySpace axisCount
		storeMany: myRegions
		with: mySpace axisCount
		with: current * mySpace axisCount.
	myRegions at: myIndex * mySpace axisCount + dimension
		store: newRegion.
	myIndex := myIndex + 1.
	^myIndex - 1!

{Int32} boxCount

	self knownBug. "includes deleted boxes"
	^myIndex!

{XnRegion} boxProjection: box {Int32} with: dimension {Int32}
	"Change a projection of a box"
	
	^(myRegions fetch: box * mySpace axisCount + dimension) cast: XnRegion!

{void} deleteBox: box {Int32}
	"Mark a box as deleted"
	
	myRegions at: box * mySpace axisCount store: NULL!

{BooleanVar} distributeUnion: added {Int32}
	with: start {Int32}
	with: stop {Int32}
	
	"Take my box at added
		and distribute it over my existing boxes from start to stop - 1
		meanwhile taking pieces out of my box at remainder
			and delete it if it becomes empty
	Return true if there is still something left in the remainder"
	
	start almostTo: stop do: [ :index {Int32} |
		(self splitUnion: added with: index with: stop)
			ifFalse: [^false]].
	^true!

{Int32} index

	^myIndex!

{BooleanVar} isDeleted: box {Int32}
	"Whether the box has been deleted"
	
	^(myRegions fetch: box * mySpace axisCount) == NULL!

{PtrArray of: XnRegion} secretRegions

	^myRegions!

{BooleanVar} splitUnion: added {Int32}
	with: current {Int32}
	with: stop {Int32}
	
	"Take my box at added
		and union it with my box at current
		delete it if it becomes empty
	Return true if there is still something left in the added box"
	
	| dimension {Int32} addedRegion {XnRegion} currentRegion {XnRegion} common {XnRegion}
	  newAdded {Int32} extraCurrent {XnRegion} extraAdded {XnRegion} |
	
	(self isDeleted: current) ifTrue: [^true].
	dimension := Int32Zero.
	[dimension + 1 < mySpace axisCount] whileTrue:
		["see if the added intersects the current in this dimension"
		addedRegion := self boxProjection: added with: dimension.
		currentRegion := self boxProjection: current with: dimension.
		self thingToDo. "Add protocol for tri-delta: gives triple (a-b, a&b, b-a)"
		common := addedRegion intersect: currentRegion.
		common isEmpty ifTrue:
			[^true].
		
		"split out the part of current that doesn't intersect"
		extraCurrent := currentRegion minus: common.
		extraCurrent isEmpty ifFalse:
			[self addSubstitutedBox: current
				with: dimension with: extraCurrent.
			self storeBoxProjection: current with: dimension with: common].
		
		"split out the part of the added that doesn't intersect"
		extraAdded := addedRegion minus: common.
		extraAdded isEmpty ifFalse:
			[newAdded := self addSubstitutedBox: added
				with: dimension with: extraAdded.
			self distributeUnion: newAdded with: current + 1 with: stop.
			self storeBoxProjection: added with: dimension with: common].
		
		dimension := dimension + 1].
	
	"union the added into the last dimension of the current box"
	addedRegion := self boxProjection: added with: dimension.
	currentRegion := self boxProjection: current with: dimension.
	self storeBoxProjection: current with: dimension with: (currentRegion unionWith: addedRegion).
	self deleteBox: added.
	^false!

{void} storeBoxProjection: box {Int32} with: dimension {Int32} with: region {XnRegion}
	"Change a projection of a box"
	
	myRegions at: box * mySpace axisCount + dimension store: region!

{void} tryMergeBoxes: i {Int32} with: j {Int32}
	"If two boxes differ by only one projection, union the second into the first and delete the second"
	
	| unequal {Int32} |
	unequal := -1.
	Int32Zero almostTo: mySpace axisCount do: [ :dim {Int32} |
		((self boxProjection: i with: dim) isEqual: (self boxProjection: j with: dim))
			ifFalse:
				[unequal >= Int32Zero
					ifTrue: [^VOID].
				unequal := dim]].
	self storeBoxProjection: i with: unequal
		with: ((self boxProjection: i with: unequal)
			unionWith: (self boxProjection: j with: unequal)).
	self deleteBox: j.! !

!BoxAccumulator methodsFor: 'operations'!

{void} addAccumulatedBoxes: other {BoxAccumulator}
	"Add in all the boxes in another accumulator"
	
	Int32Zero almostTo: other index do: [ :box {Int32} |
		(other isDeleted: box) ifFalse:
			[self aboutToAdd.
			myRegions at: myIndex * mySpace axisCount
				storeMany: other secretRegions
				with: mySpace axisCount
				with: box * mySpace axisCount.
			myIndex := myIndex + 1]]!

{Int32} addBox: box {BoxStepper}
	"Add the current box to the end of the array"
	
	^self addProjections: box region secretRegions
		with: box boxIndex!

{void} addInverseTransformedBox: box {BoxStepper} with: dsp {GenericCrossDsp}
	"Add the current box, transformed by the inverse of the dsp"
	
	| base {Int32} |
	self aboutToAdd.
	base := mySpace axisCount * myIndex.
	Int32Zero almostTo: mySpace axisCount do: [ :dimension {Int32} |
		myRegions at: base + dimension
			store: ((dsp subMapping: dimension) inverseOfAll: (box projection: dimension))].
	myIndex := myIndex + 1.!

{Int32} addProjections: projections {PtrArray of: XnRegion}
	with: boxIndex {Int32}
	"Add a box to the end of the array"
	
	self aboutToAdd.
	myRegions at: myIndex * mySpace axisCount
		storeMany: projections
		with: mySpace axisCount
		with: boxIndex * mySpace axisCount.
	myIndex := myIndex + 1.
	^myIndex - 1!

{void} addTransformedBox: box {BoxStepper} with: dsp {GenericCrossDsp}
	"Add the current box, transformed by the dsp"
	
	| base {Int32} |
	self aboutToAdd.
	base := myIndex * mySpace axisCount.
	Int32Zero almostTo: mySpace axisCount do: [ :dimension {Int32} |
		myRegions at: base + dimension
			store: ((dsp subMapping: dimension) ofAll: (box projection: dimension))].
	myIndex := myIndex + 1.!

{void} intersectWithBox: box {BoxStepper}
	"Intersect the current region with a box. May leave the result uncanonicalized"
	
	Int32Zero almostTo: myIndex do: [ :i {Int32} |
		(box intersectBoxInto: myRegions with: i) ifFalse:
			[self deleteBox: i]].!

{void} mergeBoxes
	"merge boxes which differ in only one projection"
	
	Ravi thingToDo. "hash lookup"
	Int32Zero almostTo: myIndex do: [ :i {Int32} |
		(self isDeleted: i) ifFalse:
			[Int32Zero almostTo: myIndex do: [ :j {Int32} |
				(i == j or: [self isDeleted: j]) ifFalse:
					[self tryMergeBoxes: i with: j]]]]!

{XnRegion} region
	"The current region in the accumulator. CLIENT MUST KNOW THAT IT IS CANONICAL"
	
	^GenericCrossRegion make: mySpace
		with: myIndex
		with: ((myRegions copy: myIndex * mySpace axisCount) cast: PtrArray)!

{void} removeDeleted
	"Remove boxes which have been deleted"
	
	| to {Int32} from {Int32} |
	from := to := Int32Zero.
	[from < myIndex] whileTrue:
		[(self isDeleted: from)  ifFalse:
			[from > to ifTrue:
				[myRegions at: to * mySpace axisCount
					storeMany: myRegions
					with: mySpace axisCount
					with: from * mySpace axisCount].
			to := to + 1].
		from := from + 1].
	myIndex := to!

{void} step: someObj {Heaper}

	self unionWithBoxes: (someObj cast: GenericCrossRegion) boxStepper!

{void} unionWithBox: box {BoxStepper}
	"Add the current box to the accumulator"
	
	| initialIndex {Int32} addedIndex {Int32} |
	initialIndex := myIndex.
	addedIndex := self addBox: box.
	self distributeUnion: addedIndex with: Int32Zero with: initialIndex.!

{void} unionWithBoxes: boxes {BoxStepper}
	"Add a sequence of disjoint boxes to the accumulator"
	
	myIndex = Int32Zero ifTrue:
		[[boxes hasValue] whileTrue:
			[self addBox: boxes.
			boxes step]]
	ifFalse:
		[[boxes hasValue]
			whileTrue:
				[self unionWithBox: boxes.
				boxes step]]!

{Heaper} value

	^self region! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BoxAccumulator class
	instanceVariableNames: ''!

(BoxAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!BoxAccumulator class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeAccumulators := InstanceCache make: 8!

linkTimeNonInherited
	SomeAccumulators := NULL! !

!BoxAccumulator class methodsFor: 'creation'!

make: region {GenericCrossRegion}
	| result {Heaper} |
	result := SomeAccumulators fetch.
	result == NULL
		ifTrue: [^ self create: region]
		ifFalse: [^ (self new.Become: result) create: region]!

make: space {CrossSpace} with: expectedBoxCount {Int32}
	| result {Heaper} |
	result := SomeAccumulators fetch.
	result == NULL
		ifTrue: [^ self create: space with: expectedBoxCount]
		ifFalse: [^ (self new.Become: result) create: space with: expectedBoxCount]! !