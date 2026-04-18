'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:26 pm'!

PointRegion subclass: #RectanglePointRegion
	instanceVariableNames: '
		myLeft {IntegerVar}
		myTop {IntegerVar}
		myRight {IntegerVar}
		myBottom {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!
RectanglePointRegion comment:
'Instances represent two dimensional integer coordinate spaces.  This is a simple rectangular point region, for those millions of cases where it''s all ya need.'!

(RectanglePointRegion getOrMakeCxxClassDescription)
	friends:
'/* friends for class RectanglePointRegion */
friend SPTR(RectanglePointRegion) rectanglePointRegion (IntegerVar left, IntegerVar top, IntegerVar right, IntegerVar bottom);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RectanglePointRegion methodsFor: 'testing'!

{UInt32} hashForEqual
 	^ (myLeft DOTasLong bitXor: (myRight * myBottom) DOTasLong) bitXor: myTop DOTasLong!

{BooleanVar} hasMember: pos {Position}
 	
 	| pnt {PointPos} lx {IntegerVar} ly {IntegerVar} | 
 	pnt _ pos cast: PointPos.
 	(lx _ pnt x) < myLeft ifTrue: [^ false]
 	ifFalse: [lx >= myRight ifTrue: [^ false]
 	ifFalse: [(ly _ pnt y) < myTop ifTrue: [^ false]
 	ifFalse: [ly >= myBottom ifTrue: [^ false]]]].
 	^ true!

{BooleanVar} intersects: region {XnRegion}

	region
		cast: RectanglePointRegion into: [:rect |
 			rect right <= myLeft
 				ifTrue: [^false]
 			ifFalse: [rect left >= myRight
 				ifTrue: [^false]
 			ifFalse: [rect bottom <= myTop
 				ifTrue: [^false]
 			ifFalse: [rect top >= myBottom
 				ifTrue: [^false]]]].
 			^true]
 		others: [^region intersects: self].
	^false "fodder"!

{BooleanVar} isEmpty
 	^ myLeft == myRight or: [myTop == myBottom]!

{BooleanVar} isEnumerable: order {OrderSpec unused default: NULL}
	
	^true!

{BooleanVar} isEqual: region {Heaper} 

	region
		cast: RectanglePointRegion into: [:other |
			^myLeft == other left and: 
				[myRight == other right and: 
				[myTop == other top and: 
				[myBottom == other bottom]]]]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFinite
 	^ true!

{BooleanVar} isFull	

 	^ false!

{BooleanVar} isSimple
 	^ true!

{BooleanVar} isSubsetOf: region {XnRegion}

	(PointRegion make basicCast: Heaper star) == region ifTrue: [^ PointRegion make == self].
  	(PointRegion make == self basicCast: Heaper star) ifTrue: [^ region isEmpty not].
 	region 
 		cast: RectanglePointRegion into: [:other |
 			myLeft < other left ifTrue: [^ false]
 			ifFalse: [myRight > other right ifTrue: [^ false]
 			ifFalse: [myTop < other top ifTrue: [^ false]
 			ifFalse: [myBottom > other bottom ifTrue: [^ false]]]].
 			^ true]
 		others: [^self asSlicePointRegion isSubsetOf: region].
	^false "fodder"! !

!RectanglePointRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	^ self!

{PtrArray of: XnRegion} projections
	
	^ (PrimSpec pointer
		arrayWithTwo: (IntegerRegion make: myLeft with: myRight)
		with: (IntegerRegion make: myBottom with: myTop)) cast: PtrArray!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL}

	^ RectangleRegionStepper create: self! !

!RectanglePointRegion methodsFor: 'rectangle accessing'!

{IntegerVar} bottom
 	^ myBottom!

{PointPos} corner
	^ PointPos make: myRight with: myBottom!

{PointPos} extent
	"Return a point describing the simpleRegion of the occupied area."
	
 	^ PointPos make: myRight - myLeft with: myBottom - myTop!

{IntegerVar} height
 	^ myBottom - myTop!

{IntegerVar} left
 	^ myLeft!

{PointPos} origin
	^ PointPos make: myLeft with: myTop!

{IntegerVar} right
 	^ myRight!

{IntegerVar} top
 	^ myTop!

{IntegerVar} width
 	^ myRight - myLeft! !

!RectanglePointRegion methodsFor: 'operations'!

{XnRegion} complement

	PointRegion make == self ifTrue: [^ PointRegion allPoints].
	^self asSlicePointRegion complement!

{PointRegion} insetByInt: delta {IntegerVar} 
	"Answer a PointRegion that is inset from the receiver by delta"

	^RectanglePointRegion
		create: myLeft + delta
		with: myTop + delta
		with: myRight - delta
		with: myBottom - delta!

{PointRegion} insetByPoint: delta {PointPos} 
	"Answer a PointRegion that is inset from the receiver by delta"

	^RectanglePointRegion
		create: myLeft + delta x
		with: myTop + delta y
		with: myRight - delta x
		with: myBottom - delta y!

{XnRegion} intersect: region {XnRegion}

	| newLeft {IntegerVar} newTop {IntegerVar}
	  newRight {IntegerVar} newBottom {IntegerVar} |
	region coordinateSpace == PointSpace make 
		ifFalse: [Heaper BLAST: #IncompatibleRegions].
	region
		cast: RectanglePointRegion into: [:other |
			newLeft _ myLeft max: other left.
			newTop _ myTop max: other top.
			newRight _ myRight min: other right.
			newBottom _ myBottom min: other bottom.
			newLeft < newRight ifFalse: [^ PointRegion make].
			newTop < newBottom ifFalse: [^ PointRegion make].
			^RectanglePointRegion 
				create: newLeft 
				with: newTop 
				with: newRight 
				with: newBottom]
		others: [^region intersect: self].
	^NULL "fodder"!

{XnRegion} minus: region {XnRegion}
	"wimp out on this one..."
	PointRegion make == self ifTrue: [^ self].
	(PointRegion make basicCast: Heaper star) == region ifTrue: [^ region].
	^self asSlicePointRegion minus: region!

{XnRegion} simpleUnion: region {XnRegion} 
	"return a simple region containing me and otherRegion."

	| other {RectanglePointRegion} newLeft {IntegerVar}
newTop {IntegerVar}
	 newRight {IntegerVar} newBottom {IntegerVar} |
	(region coordinateSpace == PointSpace make) ifFalse: [Heaper BLAST: #IncompatibleRegions].
	(region isFinite and: [region isSimple]) ifFalse: [^
region simpleUnion: self].
	other _ region basicCast: RectanglePointRegion.
	newLeft _ myLeft min: other left.
	newTop _ myTop min: other top.
	newRight _ myRight max: other right.
	newBottom _ myBottom max: other bottom.
	newLeft < newRight ifFalse: [^ PointRegion make].
	newTop < newBottom ifFalse: [^ PointRegion make].
	^ RectanglePointRegion create: newLeft with: newTop with:
newRight with: newBottom!

{XnRegion} unionWith: region {XnRegion}
	(region isKindOf: RectanglePointRegion) 
		ifTrue: [^ self simpleUnion: region]
		ifFalse: [^ region unionWith: self]! !

!RectanglePointRegion methodsFor: 'enumerating'!

{Stepper of: CrossRegion} boxes

	^Stepper itemStepper: self!

{IntegerVar} count
	^ self height * self width!

{BooleanVar} isBox
	
	^true! !

!RectanglePointRegion methodsFor: 'protected: creation'!

create: left {IntegerVar} with: top {IntegerVar} with: right {IntegerVar} with: bottom {IntegerVar}

	super create.
	myLeft _ left.
	myTop _ top.
	myRight _ right.
	myBottom _ bottom! !

!RectanglePointRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	PointRegion make == self
		ifTrue: [oo << 'PointRegion(empty)']
		ifFalse: [oo << 'Rect(' << myLeft << 'x' << myTop << ', ' << myRight << 'x' << myBottom << ')']! !

!RectanglePointRegion methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 

	self unimplemented.
	^NULL "fodder"! !

!RectanglePointRegion methodsFor: 'converting'!

{SlicePointRegion} asSlicePointRegion

	^SlicePointRegion
		make: myLeft
		with: myTop
		with: myRight
		with: myBottom! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RectanglePointRegion class
	instanceVariableNames: ''!

(RectanglePointRegion getOrMakeCxxClassDescription)
	friends:
'/* friends for class RectanglePointRegion */
friend SPTR(RectanglePointRegion) rectanglePointRegion (IntegerVar left, IntegerVar top, IntegerVar right, IntegerVar bottom);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RectanglePointRegion class methodsFor: 'pseudo constructors'!

make: left {IntegerVar} with: top {IntegerVar} with: right {IntegerVar} with: bottom {IntegerVar}

	^ self create: left with: top with: right with: bottom! !