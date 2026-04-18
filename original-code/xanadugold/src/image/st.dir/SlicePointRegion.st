'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:28 pm'!

PointRegion subclass: #SlicePointRegion
	instanceVariableNames: '
		myFirstSlice {IntegerRegion}
		mySliceKeys {IntegerVarArray}
		mySliceRegions {PtrArray of: IntegerRegion}
		mySliceCount {Int4}'
	classVariableNames: '
		TheEmptyIntegerVarArray {IntegerVarArray} 
		TheEmptyPtrArray {PtrArray} 
		TheFullPointRegion {SlicePointRegion} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!
SlicePointRegion comment:
'Instances represent two dimensional integer coordinate spaces.  If I can possibly help it, I''ll not install a choice of orientation (which way is up).  This is a nest coordinate space because it''s organized first by Y, then by X.'!

(SlicePointRegion getOrMakeCxxClassDescription)
	friends:
'friend class PointTranslateDsp;
friend class PointSpace;
friend SPTR(PointRegion) pointRegion (IntegerRegion * region);
friend SPTR(PointRegion) pointRegion (IntegerRegion * xRegion, IntegerRegion * yRegion);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SlicePointRegion methodsFor: 'testing'!

{UInt32} hashForEqual
 	^((myFirstSlice hashForEqual
 		bitXor: (mySliceKeys elementsHash: mySliceCount))
 		bitXor: (mySliceRegions elementsHash: mySliceCount))
 		bitXor: mySliceCount * 17!

{BooleanVar} hasMember: pos {Position}
	| point {PointPos star} |
	point _ pos cast: PointPos.
	^(self sliceAt: point y) hasIntMember: point x!

{BooleanVar} intersects: region {XnRegion}
	"Iterate through the pairs of regions defined by a transition in either the
	 receiver of region.  Perform the primary operation on each of the
	 pairs of regions."
	 
	| other {SlicePointRegion} mine {SliceStepper} his {SliceStepper} useMe {BooleanVar}
	  useHim {BooleanVar} myRegion {XnRegion} hisRegion {XnRegion} |
	(PointRegion make basicCast: Heaper star) == region ifTrue: [^ false].
	region
		cast: SlicePointRegion into: [:spr |
			other _ spr]
		cast: RectanglePointRegion into: [ :rpr |
			other := rpr asSlicePointRegion].
	myRegion _ myFirstSlice.
	hisRegion _ other firstSlice.
	(myRegion intersects: hisRegion) ifTrue: [^true].
	mine _ self sliceStepper.
	his _ other sliceStepper.
	[(useMe _ mine hasValue) or: [his hasValue]] whileTrue: 
			[useHim _ his hasValue.
			(useMe and: [useHim]) ifTrue:
				[useMe _ mine y <= his y.
				useHim _ his y <= mine y].
			useMe ifTrue:
				[myRegion _ mine slice.
				mine step].
			useHim ifTrue:
				[hisRegion _ his slice.
				his step].
			(myRegion intersects: hisRegion) ifTrue: [^true]].
	^false!

{BooleanVar} isEmpty
	^myFirstSlice isEmpty and: [mySliceCount = Int32Zero]!

{BooleanVar} isEnumerable: order {OrderSpec default: NULL}
	
	self isFinite ifTrue:
		[^true].
	self unimplemented.
	^false "fodder"!

{BooleanVar} isEqual: region {Heaper}

	region
		cast: SlicePointRegion into: [:other |
			^other sliceCount = mySliceCount
			 and: [(other firstSlice isEqual: myFirstSlice)
			 and: [(other sliceKeys elementsEqual: Int32Zero
			 	with: mySliceKeys
			 	with: Int32Zero
			 	with: mySliceCount)
			 and: [(other sliceRegions elementsEqual: Int32Zero
			 	with: mySliceRegions
			 	with: Int32Zero
			 	with: mySliceCount)]]]]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFinite
	myFirstSlice isEmpty ifFalse: [^false].
	Int32Zero almostTo: mySliceCount do: [:i {Int32} | (self sliceAtIndex: i) isFinite ifFalse: [^false]].
	^self lastSlice isEmpty!

{BooleanVar} isFull	

	^myFirstSlice isFull and: [mySliceCount == Int32Zero]!

{BooleanVar} isSimple
	mySliceCount == Int32Zero ifTrue:
		[^myFirstSlice isSimple]
	ifFalse: [mySliceCount = 1 ifTrue:
		[^(myFirstSlice isEmpty and: [(self sliceAtIndex: Int32Zero) isSimple])
			or: [(self sliceAtIndex: Int32Zero) isEmpty and: [myFirstSlice isSimple]]]
	ifFalse: [mySliceCount = 2 ifTrue:
		[^myFirstSlice isEmpty and: [(self sliceAtIndex: Int32Zero) isSimple and: [(self sliceAtIndex: 1) isEmpty]]]
	ifFalse:
		[^false]]]!

{BooleanVar} isSubsetOf: region {XnRegion}
	"Iterate through the pairs of regions defined by a transition in either the
	 receiver of region.  Perform the primary operation on each of the
	 pairs of regions."
	 
	| other {SlicePointRegion} mine {SliceStepper} his {SliceStepper} useMe {BooleanVar}
	  useHim {BooleanVar} myRegion {XnRegion} hisRegion {XnRegion} |
	(PointRegion make basicCast: Heaper star) == region ifTrue: [^ false].
	region
		cast: SlicePointRegion into: [:spr |
			other _ spr]
		cast: RectanglePointRegion into: [ :rpr |
			other := rpr asSlicePointRegion].
	myRegion _ myFirstSlice.
	hisRegion _ other firstSlice.
	(myRegion isSubsetOf: hisRegion) ifFalse: [^false].
	mine _ self sliceStepper.
	his _ other sliceStepper.
	[(useMe _ mine hasValue) or: [his hasValue]] whileTrue: 
			[useHim _ his hasValue.
			(useMe and: [useHim]) ifTrue:
				[useMe _ mine y <= his y.
				useHim _ his y <= mine y].
			useMe ifTrue:
				[myRegion _ mine slice.
				mine step].
			useHim ifTrue:
				[hisRegion _ his slice.
				his step].
			(myRegion isSubsetOf: hisRegion) ifFalse: [^false]].
	^true! !

!SlicePointRegion methodsFor: 'display accessing'!

{IntegerVar} bottom
	self lastSlice isEmpty
		ifTrue: [mySliceCount == Int32Zero
				ifTrue: [Heaper BLAST: #EmptyRegion]
				ifFalse: [^self lastSliceKey]]
		ifFalse: [Heaper BLAST: #NotEnumerable].
	^IntegerVarZero "fodder"!

{PointPos} corner
	
	^PointPos make: self right with: self bottom!

{PointPos} extent
	"Return a point describing the simpleRegion of the occupied area."
	
	^PointPos make: self width with: self height!

{IntegerVar} height
	(myFirstSlice isEmpty and: [self lastSlice isEmpty])
		ifTrue: [mySliceCount == Int32Zero
			ifTrue: [Heaper BLAST: #EmptyRegion] 
			ifFalse: [^self lastSliceKey - self firstSliceKey]]
		ifFalse:  [Heaper BLAST: #NotEnumerable].
	^IntegerVarZero "fodder"!

{IntegerVar} left
	| slice {IntegerRegion} |
	myFirstSlice isEmpty not ifTrue: [Heaper BLAST: #NotEnumerable].
	self sliceCount ~~ 2 ifTrue: [Heaper BLAST: #NotSimple].
	slice _ self sliceAtIndex: Int32Zero.
	slice isBoundedBelow ifFalse: [Heaper BLAST: #NotEnumerable].
	^ slice start!

{PointPos} origin
	
	^PointPos make: self left with: self top!

{IntegerVar} right
	| slice {IntegerRegion} |
	myFirstSlice isEmpty not ifTrue: [Heaper BLAST: #NotEnumerable].
	self sliceCount ~~ 2 ifTrue: [Heaper BLAST: #NotSimple].
	slice _ self sliceAtIndex: Int32Zero.
	slice isBoundedAbove ifFalse: [Heaper BLAST: #NotEnumerable].
	^ slice stop!

{IntegerVar} top

	(myFirstSlice isEmpty)
		ifTrue: [mySliceCount == Int32Zero 
			ifTrue: [Heaper BLAST: #EmptyRegion] 
			ifFalse: [^self firstSliceKey]]
		ifFalse:  [Heaper BLAST: #NotEnumerable].
	^IntegerVarZero "fodder"!

{IntegerVar} width

	^ self right - self left! !

!SlicePointRegion methodsFor: 'slice accessing'!

{IntegerRegion} firstSlice
	^myFirstSlice!

{IntegerVar} firstSliceKey
	mySliceCount > Int32Zero assert: 'invalid request'.
	^mySliceKeys integerVarAt: Int32Zero!

{IntegerRegion} lastSlice
	mySliceCount == Int32Zero
		ifTrue: [^myFirstSlice]
		ifFalse: [^(mySliceRegions fetch: mySliceCount - 1) cast: IntegerRegion]!

{IntegerVar} lastSliceKey
	mySliceCount > Int32Zero assert: 'invalid request'.
	^mySliceKeys integerVarAt: (mySliceCount - 1)!

{IntegerRegion} simpleX
	"the simple X region"
	| result {XnRegion} |
	result _ myFirstSlice asSimpleRegion.
	Int32Zero almostTo: mySliceCount do: [ :i {Int32} |
		result _ result simpleUnion: (self sliceAtIndex: i)].
	^result quickCast: IntegerRegion!

{IntegerRegion} simpleY
	"the simple Y region"
	mySliceCount == Int32Zero ifTrue:
		[myFirstSlice isEmpty
			ifTrue: [^IntegerRegion make]
			ifFalse: [^IntegerRegion allIntegers]].
	myFirstSlice isEmpty
		ifTrue: [self lastSlice isEmpty
			ifTrue: [^IntegerRegion make: self firstSliceKey with: self lastSliceKey]
			ifFalse: [^IntegerRegion after: self firstSliceKey]]
		ifFalse: [self lastSlice isEmpty
			ifTrue: [^IntegerRegion before: self lastSliceKey]
			ifFalse: [^IntegerRegion allIntegers]]!

{IntegerRegion} sliceAt: y {IntegerVar}
	| i {Int32} |
	i _ Int32Zero.
	[i < mySliceCount and: [y >= (mySliceKeys integerVarAt: i)]] whileTrue:
		[i _ i + 1].
	^self sliceAtIndex: i - 1!

{IntegerRegion} sliceAtIndex: i {Int32}
	i = -1 ifTrue: [^myFirstSlice].
	^(mySliceRegions fetch: i) quickCast: IntegerRegion!

{Int32} sliceCount
	^mySliceCount!

{IntegerVar} sliceKeyAtIndex: i {Int32}
	^mySliceKeys integerVarAt: i!

{SliceStepper} sliceStepper
	^SliceStepper create: self! !

!SlicePointRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	| slices {XnRegion} |
	self isSimple ifTrue: [^self].	
	slices _ myFirstSlice asSimpleRegion.
	Int32Zero almostTo: mySliceCount do: [ :i {Int32} |
		slices _ slices simpleUnion: (self sliceAtIndex: i)].
	^PointRegion make.IntegerRegion: (slices cast: IntegerRegion) with: self simpleY!

{CoordinateSpace} coordinateSpace
	^PointSpace make!

{ScruSet of: Region} distinctions

	self unimplemented.
	^NULL!

{PtrArray of: XnRegion} projections
	
	| y {XnRegion} |
	y := myFirstSlice.
	UInt32Zero almostTo: mySliceCount do: [ :i {Int32} |
		y := y unionWith: ((mySliceRegions fetch: i) cast: XnRegion)].
	^(PrimSpec pointer
		arrayWithTwo: (IntegerRegion using: myFirstSlice isEmpty not
			with: mySliceCount with: mySliceKeys)
		with: y) cast: PtrArray!

{Stepper} simpleRegions: order {OrderSpec default: NULL}

	order ~~ NULL ifTrue:
		[self unimplemented].
	self isSimple ifTrue: 
		[self isEmpty
			ifTrue: [^Stepper emptyStepper]
			ifFalse: [^Stepper itemStepper: self]].
	^PointSimpleRegionStepper create: self! !

!SlicePointRegion methodsFor: 'operations'!

{XnRegion} complement

	| resultArray {PtrArray of: IntegerRegion} result {SlicePointRegion} |
	(TheFullPointRegion basicCast: Heaper star) == self ifTrue: [^PointRegion make].
	PointRegion make == self ifTrue: [^TheFullPointRegion].
	mySliceCount == Int32Zero ifTrue:
		[result _ SlicePointRegion
			create: (myFirstSlice complement quickCast: IntegerRegion)
			with: mySliceCount
			with: mySliceKeys
			with: mySliceRegions.
		^ result canonicalForm].
	resultArray _ PtrArray nulls: mySliceCount.
	Int32Zero almostTo: mySliceCount do: [:i {Int32} | 
		resultArray at: i store: (self sliceAtIndex: i) complement].
	result _ SlicePointRegion
		create: (myFirstSlice complement quickCast: IntegerRegion)
		with: mySliceCount
		with: mySliceKeys
		with: resultArray.
	^ result canonicalForm!

{PointRegion} insetByInt: delta {IntegerVar} 
	"Answer a PointRegion that is inset from the receiver by delta"
	| top {IntegerVar} left {IntegerVar} right {IntegerVar} bottom {IntegerVar} |
	self isSimple ifFalse: [Heaper BLAST: #NOT.U.SIMPLE.U.REGION].
	top _ self top.
	left _ self left.
	right _ self right.
	bottom _ self bottom.
	^ PointRegion make: top + delta with: left + delta with: right - delta with: bottom - delta!

{PointRegion} insetByPoint: delta {PointPos unused} 
	"Answer a PointRegion that is inset from the receiver by delta "
	self unimplemented.
	^NULL!

{XnRegion} intersect: region {XnRegion}
	"Iterate through the pairs of regions defined by a transition in either the
	 receiver of region.  Perform the primary operation on each of the
	 pairs of regions."
	| other {SlicePointRegion star} key {IntegerVar} result {SliceAccumulator}
	  mine {SliceStepper} his {SliceStepper}
	  useMe {BooleanVar} useHim {BooleanVar}
	  myRegion {XnRegion} hisRegion {XnRegion} |
	(PointRegion make basicCast: Heaper star) == region ifTrue: [^ PointRegion make].
	region
		cast: SlicePointRegion into: [:spr |
			other _ spr]
		cast: RectanglePointRegion into: [ :rpr |
			other := rpr asSlicePointRegion].
	myRegion _ myFirstSlice.
	hisRegion _ other firstSlice.
	result _ SliceAccumulator create: ((myRegion intersect: hisRegion) quickCast: IntegerRegion)
		with: mySliceCount + other sliceCount.
	mine _ self sliceStepper.
	his _ other sliceStepper.
	[(useMe _ mine hasValue) or: [his hasValue]] whileTrue: 
			[useHim _ his hasValue.
			(useMe and: [useHim]) ifTrue:
				[useMe _ mine y <= his y.
				useHim _ his y <= mine y].
			useMe ifTrue:
				[myRegion _ mine slice.
				key _ mine y.
				mine step].
			useHim ifTrue:
				[hisRegion _ his slice.
				key _ his y.
				his step].
			result slice: key with: ((myRegion intersect: hisRegion) quickCast: IntegerRegion)].
	^(result region cast: SlicePointRegion) canonicalForm!

{XnRegion} minus: region {XnRegion}
	"Iterate through the pairs of regions defined by a transition in either the
	 receiver of region.  Perform the primary operation on each of the
	 pairs of regions."
	| other {SlicePointRegion star} key {IntegerVar} result {SliceAccumulator}
	  mine {SliceStepper} his {SliceStepper}
	  useMe {BooleanVar} useHim {BooleanVar}
	  myRegion {XnRegion} hisRegion {XnRegion} |
	(PointRegion make basicCast: Heaper star) == region ifTrue: [^ self canonicalForm].
	region
		cast: SlicePointRegion into: [:spr |
			other _ spr]
		cast: RectanglePointRegion into: [ :rpr |
			other := rpr asSlicePointRegion].
	myRegion _ myFirstSlice.
	hisRegion _ other firstSlice.
	result _ SliceAccumulator create: ((myRegion minus: hisRegion)  quickCast: IntegerRegion)
		with: mySliceCount + other sliceCount.
	mine _ self sliceStepper.
	his _ other sliceStepper.
	[(useMe _ mine hasValue) or: [his hasValue]] whileTrue: 
			[useHim _ his hasValue.
			(useMe and: [useHim]) ifTrue:
				[useMe _ mine y <= his y.
				useHim _ his y <= mine y].
			useMe ifTrue:
				[myRegion _ mine slice.
				key _ mine y.
				mine step].
			useHim ifTrue:
				[hisRegion _ his slice.
				key _ his y.
				his step].
			result slice: key with:( (myRegion minus: hisRegion) quickCast: IntegerRegion)].
	^(result region cast: SlicePointRegion) canonicalForm!

{XnRegion} simpleUnion: region {XnRegion} 
	"return a simple region containing me and otherRegion."

	| other {SlicePointRegion} simpleX {XnRegion} |
	(PointRegion make basicCast: Heaper star) == region ifTrue: [^ self asSimpleRegion].
	region
		cast: SlicePointRegion into: [:spr |
			other _ spr]
		cast: RectanglePointRegion into: [ :rpr |
			other := rpr asSlicePointRegion].
	simpleX _ myFirstSlice simpleUnion: other firstSlice.
	Int32Zero almostTo: mySliceCount do: [:i {Int32} | simpleX _ simpleX simpleUnion: (self sliceAtIndex: i)].
	Int32Zero almostTo: other sliceCount do: [:j {Int32} | simpleX _ simpleX simpleUnion: (other sliceAtIndex: j)].
	^PointRegion make.IntegerRegion: (simpleX quickCast: IntegerRegion)
		with: ((self simpleY simpleUnion: other simpleY)
				quickCast: IntegerRegion)!

{XnRegion} unionWith: region {XnRegion} 
	"Iterate through the pairs of regions defined by a transition in either 
	the receiver of region. Perform the primary operation on each of the 
	pairs of regions."

	| other {SlicePointRegion wimpy} key {IntegerVar} result {SliceAccumulator} 
	 mine {SliceStepper} his {SliceStepper} useMe {BooleanVar} useHim {BooleanVar} 
	 myRegion {XnRegion} hisRegion {XnRegion} |
	
	(PointRegion make basicCast: Heaper star) == region ifTrue: [^ self].
	region
		cast: SlicePointRegion into: [:spr |
			other _ spr]
		cast: RectanglePointRegion into: [ :rpr |
			other := rpr asSlicePointRegion].
	myRegion _ myFirstSlice.
	hisRegion _ other firstSlice.
	result _ SliceAccumulator create: ((myRegion unionWith: hisRegion) quickCast: IntegerRegion)
				with: mySliceCount + other sliceCount.
	mine _ self sliceStepper.
	his _ other sliceStepper.
	[(useMe _ mine hasValue) or: [his hasValue]]
		whileTrue: 
			[useHim _ his hasValue.
			(useMe and: [useHim])
				ifTrue: [useMe _ mine y <= his y.
					useHim _ his y <= mine y].
			useMe ifTrue: 
					[myRegion _ mine slice.
					key _ mine y.
					mine step].
			useHim ifTrue: 
					[hisRegion _ his slice.
					key _ his y.
					his step].
			result slice: key with: ((myRegion unionWith: hisRegion)
					quickCast: IntegerRegion)].
	^ (result region cast: SlicePointRegion) canonicalForm! !

!SlicePointRegion methodsFor: 'private:'!

{PointRegion} canonicalForm
	| fs {IntegerRegion} |
	self isEmpty ifTrue: [^PointRegion make].
	myFirstSlice isEmpty ifFalse: [^self].
	self sliceCount == 2 ifFalse: [^self].
	(fs _ self sliceAtIndex: Int32Zero) isFinite ifFalse: [^self].
	fs isSimple ifFalse: [^self].
	(self sliceAtIndex: 1) isEmpty ifFalse: [^self].
	^RectanglePointRegion
		make: self left
		with: self top
		with: self right
		with: self bottom!

{IntegerVarArray} sliceKeys
	^mySliceKeys!

{PtrArray of: IntegerRegion} sliceRegions	
	^mySliceRegions! !

!SlicePointRegion methodsFor: 'creation'!

create: first {IntegerRegion} with: count {Int32} with: keys {IntegerVarArray} with: slices {PtrArray of: IntegerRegion}
	super create.
	myFirstSlice _ first.
	mySliceCount _ count.
	mySliceKeys _ keys.
	mySliceRegions _ slices! !

!SlicePointRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	| slices {SliceStepper} |
	self isEmpty ifTrue:
		[oo << '{}'. ^VOID].
	oo << self getCategory name << '(' << myFirstSlice.
	slices _ self sliceStepper.
	slices forEach: [ :region {IntegerRegion} |
		oo << ', ' << slices y << '->' << region].
	oo << ')'! !

!SlicePointRegion methodsFor: 'enumerating'!

{Stepper of: CrossRegion} boxes

	^self simpleRegions!

{IntegerVar} count
	| result {IntegerVar} |
	(self lastSlice isEmpty and: [myFirstSlice isEmpty]) ifFalse:
		[Heaper BLAST: #NotEnumerable].
	result _ IntegerVar0.
	Int32Zero almostTo: mySliceCount - 1 do: [ :i {Int32} |
		result _ result + (((mySliceKeys integerVarAt: i + 1) - (mySliceKeys integerVarAt: i)) * (self sliceAtIndex: i) count)].
	^result!

{BooleanVar} isBox
	
	mySliceCount >= 1 ifTrue:
		[(myFirstSlice isEmpty or: [(self sliceAt: Int32Zero) isEmpty])
			ifFalse: [^false]].
	1 almostTo: mySliceCount do: [ :i {Int32} |
		(i \\ 2) = Int32Zero ifTrue:
			[((self sliceAt: i) isEqual: (self sliceAt: Int32Zero))
				ifFalse: [^false]]
		ifFalse:
			[((self sliceAt: i) isEqual: myFirstSlice)
				ifFalse: [^false]]].
	^true! !

!SlicePointRegion methodsFor: 'smalltalk: passe'!

{PointRegion} insetBy: delta {Object} 
	"Answer a PointRegion that is inset from the receiver by delta. 
	"

	self passe! !

!SlicePointRegion methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 

	self unimplemented.
	^NULL "fodder"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SlicePointRegion class
	instanceVariableNames: ''!

(SlicePointRegion getOrMakeCxxClassDescription)
	friends:
'friend class PointTranslateDsp;
friend class PointSpace;
friend SPTR(PointRegion) pointRegion (IntegerRegion * region);
friend SPTR(PointRegion) pointRegion (IntegerRegion * xRegion, IntegerRegion * yRegion);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SlicePointRegion class methodsFor: 'pseudo constructors'!

{PointRegion} allSlicePoints
	^TheFullPointRegion!

make.IntegerRegion: region {IntegerRegion}
	^self create: region with: Int32Zero with: TheEmptyIntegerVarArray with: TheEmptyPtrArray!

make: x1 {IntegerVar} with: y1 {IntegerVar} with: x2 {IntegerVar} with: y2 {IntegerVar}

	| top {IntegerVar} bottom {IntegerVar} left {IntegerVar} right {IntegerVar}
	  keys {IntegerVarArray} slices {PtrArray of: IntegerRegion} |
	x1 < x2
		ifTrue: [left _ x1. right _ x2]
		ifFalse: [left _ x2. right _ x1].
	y1 < y2
		ifTrue: [top _ y1. bottom _ y2]
		ifFalse: [top _ y2. bottom _ y1].
	keys _ IntegerVarArray zeros: 2.
	slices _ PtrArray nulls: 2.
	keys at: Int32Zero storeIntegerVar: top.
	slices at: Int32Zero store: (IntegerRegion make: left with: right).
	keys at: 1 storeIntegerVar: bottom.
	slices at: 1 store: IntegerRegion make.
	^SlicePointRegion create: IntegerRegion make with: 2 with: keys with: slices! !

!SlicePointRegion class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: IntegerVarArray.
	self REQUIRES: PtrArray.
	self REQUIRES: IntegerRegion.
	TheEmptyIntegerVarArray _ IntegerVarArray zeros: 1.
	TheEmptyPtrArray _ PtrArray nulls: 1.
	TheFullPointRegion _ SlicePointRegion create: IntegerRegion allIntegers with: Int32Zero
		with: TheEmptyIntegerVarArray with: TheEmptyPtrArray.!

linkTimeNonInherited
	TheEmptyIntegerVarArray _ NULL.
	TheEmptyPtrArray _ NULL.
	TheFullPointRegion _ NULL! !

!SlicePointRegion class methodsFor: 'private:'!

{PointRegion} using: firstSlice {IntegerRegion}

	^self create: firstSlice
		with: Int32Zero	
		with: (IntegerVarArray zeros: Int32Zero)
		with: PtrArray empty! !