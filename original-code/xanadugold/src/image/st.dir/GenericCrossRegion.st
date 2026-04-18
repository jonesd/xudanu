'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:09 pm'!

CrossRegion subclass: #GenericCrossRegion
	instanceVariableNames: '
		mySpace {CrossSpace}
		myCount {Int32}
		myRegions {PtrArray of: XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
GenericCrossRegion comment:
'Represents a region as a two-dimensional array of crosses of subregions.
 Was NOT.A.TYPE but that obstructed compilation.
I think this might work better if the array is lexically sorted, but I am not sure there is any meaningful way to do so. Thus there is no sorting assumed in the algorithms, although the protocol may occasionally suggest that there might be.

Eventually this implementation may save space by using NULL to represent repetitions of a sub region such that
	fetchBoxProjection (box, dim) == NULL
only if
	box > 0
	&& boxProjection (box, dim)->isEqual (boxProjection (box - 1, dim))
	&& (dim == 0
		|| fetchBoxProjection (box, dim - 1) == NULL)'!

(GenericCrossRegion getOrMakeCxxClassDescription)
	friends:
'friend class BoxAccumulator;
friend class BoxProjectionStepper;
friend class BoxStepper;
friend class GenericCrossDsp;
friend class GenericCrossSpace;
friend class CrossOrderSpec;
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!GenericCrossRegion methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^mySpace!

{IntegerVar} count

	| result {IntegerVar} boxes {BoxStepper} |
	result := IntegerVarZero.
	boxes := self boxStepper.
	[boxes hasValue] whileTrue:
		[ | sub {IntegerVar} |
		sub := 1.
		boxes projectionStepper forEach: [ :proj {XnRegion} |
			sub := sub * proj count].
		result := result + sub.
		boxes step].
	boxes destroy.
	^result!

{XnRegion} projection: index {Int32}

	| result {XnRegion} boxes {BoxStepper} |
	myCount = 1 ifTrue: [^self boxProjection: Int32Zero with: index].
	result := (mySpace axis: index) emptyRegion.
	boxes := self boxStepper.
	[boxes hasValue] whileTrue:
		[result := result unionWith: (boxes projection: index).
		boxes step].
	boxes destroy.
	^result!

{PtrArray of: XnRegion} projections

	| result {PtrArray of: XnRegion} boxes {BoxStepper} |
	result := PtrArray nulls: mySpace axisCount.
	UInt32Zero almostTo: result count do: [ :i {UInt32} |
		result at: i store: (mySpace axis: i) emptyRegion].
	boxes := self boxStepper.
	[boxes hasValue] whileTrue:
		[boxes unionBoxInto: result with: Int32Zero.
		boxes step].
	boxes destroy.
	^result!

{Position} theOne

	| result {PtrArray of: Position} |
	myCount = 1 ifFalse: [Heaper BLAST: #MustHaveSingleElement].
	result := PtrArray nulls: mySpace axisCount.
	Int32Zero almostTo: result count do: [ :i {Int32} |
		result at: i store: (self boxProjection: Int32Zero with: i) theOne].
	^mySpace crossOfPositions: result! !

!GenericCrossRegion methodsFor: 'protected:'!

{CrossSpace} crossSpace

	^mySpace! !

!GenericCrossRegion methodsFor: 'private:'!

{Int32} boxCount

	^myCount!

{XnRegion} boxProjection: box {Int32} with: dimension {Int32}
	"A region is at a given 2D place in the array"
	
	^(myRegions fetch: box * self crossSpace axisCount + dimension) cast: XnRegion!

{BoxProjectionStepper} boxProjectionStepper
	"A stepper over all projections of all boxes in the region"
	
	^BoxProjectionStepper make: self!

{BoxStepper} boxStepper
	"A stepper over all boxes"
	
	^BoxStepper make: self!

{BooleanVar} hasBoxProjection: other {XnRegion}
	with: box {Int32} with: dimension {Int32}
	"Whether a region is at a given 2D place in the array. Searches forward and backward through adjacent boxes which have the same hash value"
	
	| index {Int32} hash {UInt32} sub {XnRegion} |
	index := box.
	hash := other hashForEqual.
	[index >= Int32Zero and: [(sub := self boxProjection: index with: dimension) hashForEqual = hash]] whileTrue:
		[(sub isEqual: other) ifTrue:
			[^true].
		index := index - 1].
	index := box + 1.
	[index < myCount and: [(sub := self boxProjection: index with: dimension) hashForEqual = hash]] whileTrue:
		[(sub isEqual: other) ifTrue:
			[^true].
		index := index + 1].
	^false!

{PtrArray of: XnRegion} secretRegions
	"The array holding the regions. DO NOT MODIFY"
	
	^myRegions! !

!GenericCrossRegion methodsFor: 'testing'!

{UInt32} actualHashForEqual

	| result {UInt32} boxes {BoxStepper} |
	result := self getCategory hashForEqual.
	boxes := self boxStepper.
	[boxes hasValue] whileTrue:
		[result := result bitXor: boxes boxHash.
		boxes step].
	boxes destroy.
	^result!

{BooleanVar} hasMember: position {Position}

	| boxes {BoxStepper} |
	boxes := self boxStepper.
	[boxes hasValue] whileTrue:
		[(boxes boxHasMember: (position cast: ActualTuple)) ifTrue:
			[^true].
		boxes step].
	^false!

{BooleanVar} intersects: other {XnRegion}

	| mine {BoxStepper} others {BoxStepper} |
	mine := self boxStepper.
	[mine hasValue] whileTrue:
		[others := (other cast: GenericCrossRegion) boxStepper.
		[others hasValue] whileTrue:
			[(mine boxIntersects: others) ifTrue:
				[^true].
			others step].
		mine step].
	mine destroy.
	others destroy.
	^false!

{BooleanVar} isDistinction

	myCount > 1 ifTrue: [^false].
	myCount == Int32Zero ifTrue: [^true].
	self boxProjectionStepper forEach: [ :proj {XnRegion} |
		proj isDistinction ifFalse:
			[^false]].
	^true!

{BooleanVar} isEmpty

	^myCount == Int32Zero!

{BooleanVar} isEnumerable: order {OrderSpec unused default: NULL}
	
	Someone shouldImplement.
	^false "fodder"!

{BooleanVar} isEqual: other {Heaper}

	other cast: GenericCrossRegion into: [ :cross | | boxes {BoxStepper} |
		(cross boxCount = myCount and: [cross crossSpace isEqual: self crossSpace])
			ifFalse: [^false].
		boxes := self boxStepper.
		[boxes hasValue] whileTrue:
			[(boxes isBoxOf: cross) ifFalse:
				[^false].
			boxes step].
		boxes destroy.
		^true]
	others:
		[^false].
	^ false "compiler fodder"!

{BooleanVar} isFinite

	self boxProjectionStepper forEach: [ :sub {XnRegion} |
		sub isFinite ifFalse:
			[^false]].
	^true!

{BooleanVar} isFull

	myCount = 1 ifFalse: [^false].
	self boxProjectionStepper forEach: [ :sub {XnRegion} |
		sub isFull ifFalse: [^false]].
	^true!

{BooleanVar} isSimple

	myCount > 1 ifTrue: [^false].
	myCount == Int32Zero ifTrue: [^true].
	self boxProjectionStepper forEach: [ :proj {XnRegion} |
		proj isSimple ifFalse: [^false]].
	^true!

{BooleanVar} isSubsetOf: other {XnRegion}

	Ravi thingToDo. "figure out a more efficient algorithm - the one commented out below doesn't work"
	^super isSubsetOf: other
	"| others {BoxStepper} mine {BoxStepper} |
	others := other boxStepper.
	[others hasValue] whileTrue:
		[mine := self boxStepper.
		[mine hasValue] whileTrue:
			[(others boxIsSubsetOf: mine) ifFalse:
				[^false].
			mine step].
		others step].
	^true"! !

!GenericCrossRegion methodsFor: 'operations'!

{XnRegion} asSimpleRegion

	| result {PtrArray} projections {BoxProjectionStepper} |
	self isEmpty ifTrue: [^self].
	result := PtrArray nulls: mySpace axisCount.
	projections := self boxProjectionStepper.
	[projections hasValue] whileTrue:
		[(result fetch: projections dimension) == NULL ifTrue:
			[result at: projections dimension store: projections projection asSimpleRegion]
		ifFalse:
			[result at: projections dimension
				store: (((result fetch: projections dimension) cast: XnRegion) simpleUnion: projections projection)].
		projections step].
	projections destroy.
	^mySpace crossOfRegions: result!

{XnRegion} complement

	| result {XnRegion} boxes {BoxStepper} |
	self isEmpty ifTrue:
		[^mySpace fullRegion].
	boxes := self boxStepper.
	result := boxes boxComplement.
	boxes step.
	[boxes hasValue] whileTrue:
		[result := result intersect: boxes boxComplement.
		boxes step].
	boxes destroy.
	^result!

{XnRegion} intersect: region {XnRegion}

	region cast: GenericCrossRegion into: [ :other |
		| result {BoxAccumulator} smaller {GenericCrossRegion} larger {GenericCrossRegion}
		  bits {BoxStepper} piece {BoxAccumulator} |
		self boxCount < other boxCount
			ifTrue: [smaller := self. larger := other]
			ifFalse: [smaller := other. larger := self].
		smaller isEmpty
			ifTrue: [^smaller].
		bits := smaller boxStepper.
		result := NULL.
		piece := BoxAccumulator make: larger.
		[bits hasValue] whileTrue:
			[piece intersectWithBox: bits.
			result == NULL
				ifTrue: [result := piece]
				ifFalse: [result addAccumulatedBoxes: piece].
			bits step.
			bits hasValue
				ifTrue: [piece := BoxAccumulator make: larger]].
		bits destroy.
		result mergeBoxes.
		result removeDeleted.
		^result region].
	^ NULL "compiler fodder"!

{XnRegion} unionWith: region {XnRegion}

	| result {BoxAccumulator} |
	region cast: GenericCrossRegion into: [ :other |
		| stepper {BoxStepper} |
		result := BoxAccumulator make: self.
		stepper := other boxStepper.
		result unionWithBoxes: stepper.
		stepper destroy.
		result mergeBoxes.
		result removeDeleted.
		^result region].
	^ NULL "compiler fodder"! !

!GenericCrossRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	| boxes {BoxStepper} between {char star} |
	oo << '{'.
	boxes := self boxStepper.
	[boxes hasValue] whileTrue:
		[between := ''.
		boxes projectionStepper forEach: [ :proj {XnRegion} |
			oo << between.
			proj isFull
				ifTrue: [oo << '*']
				ifFalse: [oo << proj].
			between := ' x '].
		boxes step.
		boxes hasValue ifTrue:
			[oo << ', ']].
	boxes destroy.
	oo << '}'! !

!GenericCrossRegion methodsFor: 'enumerating'!

{Stepper of: CrossRegion} boxes

	^self boxStepper!

{ScruSet of: XnRegion} distinctions

	| result {Accumulator} ps {BoxProjectionStepper} |
	self isSimple ifFalse:
		[Heaper BLAST: #MustBeSimple].
	result := SetAccumulator make.
	ps := self boxProjectionStepper.
	ps forEach: [ :sub {XnRegion} |
		sub distinctions stepper forEach: [ :dist {XnRegion} |
			result step: (mySpace extrusion: ps dimension with: dist)]].
	^result value cast: ScruSet!

{BooleanVar} isBox

	^self isSimple!

{Stepper} simpleRegions: order {OrderSpec default: NULL} 

	order ~~ NULL ifTrue: [self unimplemented].
	^GenericCrossSimpleRegionStepper make: mySpace with: self boxStepper! !

!GenericCrossRegion methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec unused} 

	self isEmpty ifTrue: [^Stepper emptyStepper].
	Ravi thingToDo. "do a real stepper"
	self hack.
	^Stepper itemStepper: self theOne! !

!GenericCrossRegion methodsFor: 'protected: create'!

create: space {CrossSpace} with: count {Int32} with: regions {PtrArray of: XnRegion}

	super create.
	mySpace := space.
	myCount := count.
	myRegions := regions.! !

!GenericCrossRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySpace _ receiver receiveHeaper.
	myCount _ receiver receiveInt32.
	myRegions _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySpace.
	xmtr sendInt32: myCount.
	xmtr sendHeaper: myRegions.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GenericCrossRegion class
	instanceVariableNames: ''!

(GenericCrossRegion getOrMakeCxxClassDescription)
	friends:
'friend class BoxAccumulator;
friend class BoxProjectionStepper;
friend class BoxStepper;
friend class GenericCrossDsp;
friend class GenericCrossSpace;
friend class CrossOrderSpec;
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!GenericCrossRegion class methodsFor: 'private: pseudo constructors'!

{CrossRegion} empty: space {GenericCrossSpace}

	^self create: space with: Int32Zero with: PtrArray empty!

{CrossRegion} full: space {GenericCrossSpace}
	with: subSpaces {PtrArray of: CoordinateSpace}
	"Only used during construction; must pass the array in explicitly since the space isnt initialized yet"

	| result {PtrArray of: XnRegion} |
	result := PtrArray nulls: subSpaces count.
	Int32Zero almostTo: result count do: [ :dimension {Int32} |
		result at: dimension store: ((subSpaces fetch: dimension) cast: CoordinateSpace) fullRegion].
	^self create: space with: 1 with: result! !

!GenericCrossRegion class methodsFor: 'create'!

make: space {CrossSpace} with: count {Int32} with: regions {PtrArray of: XnRegion}
	^ self create: space with: count with: regions! !