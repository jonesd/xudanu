'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:24 pm'!

CrossRegion subclass: #PointRegion
	instanceVariableNames: ''
	classVariableNames: 'TheEmptyPointRegion {PointRegion} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!
PointRegion comment:
'Instances represent two dimensional integer coordinate spaces.'!

(PointRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PointRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	self subclassResponsibility!

{CoordinateSpace} coordinateSpace
	^PointSpace make!

{ScruSet of: Region} distinctions

	self unimplemented.
	^NULL!

{PtrArray of: XnRegion} projections
	
	self subclassResponsibility!

{Stepper} simpleRegions: order {OrderSpec default: NULL}

	self subclassResponsibility! !

!PointRegion methodsFor: 'testing'!

{UInt32} hashForEqual
 	self subclassResponsibility!

{BooleanVar} hasMember: pos {Position}
 	self subclassResponsibility!

{BooleanVar} intersects: region {XnRegion}
 	self subclassResponsibility!

{BooleanVar} isEmpty
 	self subclassResponsibility!

{BooleanVar} isEnumerable: order {OrderSpec default: NULL}
	
	self subclassResponsibility!

{BooleanVar} isEqual: region {Heaper}
 	self subclassResponsibility!

{BooleanVar} isFinite
 	self subclassResponsibility!

{BooleanVar} isFull	

 	self subclassResponsibility!

{BooleanVar} isSimple
 	self subclassResponsibility!

{BooleanVar} isSubsetOf: region {XnRegion}
 	self subclassResponsibility! !

!PointRegion methodsFor: 'rectangle accessing'!

{IntegerVar} bottom
 	self subclassResponsibility!

{PointPos} corner
	
 	self subclassResponsibility!

{PointPos} extent
	"Return a point describing the simpleRegion of the occupied area."
	
 	self subclassResponsibility!

{IntegerVar} height
 	self subclassResponsibility!

{IntegerVar} left
 	self subclassResponsibility!

{PointPos} origin
	
 	self subclassResponsibility!

{IntegerVar} right
 	self subclassResponsibility!

{IntegerVar} top
 	self subclassResponsibility!

{IntegerVar} width
 	self subclassResponsibility! !

!PointRegion methodsFor: 'operations'!

{XnRegion} complement

	self subclassResponsibility!

{PointRegion} insetByInt: delta {IntegerVar} 
	"Answer a PointRegion that is inset from the receiver by delta"
	self subclassResponsibility!

{PointRegion} insetByPoint: delta {PointPos unused} 
	"Answer a PointRegion that is inset from the receiver by delta "
	self subclassResponsibility!

{XnRegion} intersect: region {XnRegion}
	"Iterate through the pairs of regions defined by a transition in either the
	 receiver of region.  Perform the primary operation on each of the
	 pairs of regions."
	self subclassResponsibility!

{XnRegion} minus: region {XnRegion}
	"Iterate through the pairs of regions defined by a transition in either the
	 receiver of region.  Perform the primary operation on each of the
	 pairs of regions."
	self subclassResponsibility!

{XnRegion} simpleUnion: region {XnRegion} 
	"return a simple region containing me and otherRegion."

	self subclassResponsibility!

{XnRegion} unionWith: region {XnRegion}
	"Iterate through the pairs of regions defined by a transition in either the
	 receiver of region.  Perform the primary operation on each of the
	 pairs of regions."
	self subclassResponsibility! !

!PointRegion methodsFor: 'enumerating'!

{Stepper of: CrossRegion} boxes

	self subclassResponsibility!

{IntegerVar} count
	self subclassResponsibility!

{BooleanVar} isBox
	self subclassResponsibility! !

!PointRegion methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !

!PointRegion methodsFor: 'smalltalk: passe'!

{PointRegion} insetBy: delta {Object} 
	"Answer a PointRegion that is inset from the receiver by delta. 
	"

	self passe! !

!PointRegion methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PointRegion class
	instanceVariableNames: ''!

(PointRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PointRegion class methodsFor: 'pseudo constructors'!

{PointRegion INLINE} allPoints
	^SlicePointRegion allSlicePoints!

{PointRegion INLINE} make
	^TheEmptyPointRegion!

make.IntegerRegion: region {IntegerRegion}
	^(SlicePointRegion make.IntegerRegion: region) canonicalForm!

make.IntegerRegion: xRegion {IntegerRegion} with: yRegion {IntegerRegion}
	"Create the cross product of the two regions"
	| odd {IntegerRegion} even {IntegerRegion} slices {PtrArray of: IntegerRegion} result {SlicePointRegion} |
	(xRegion isEmpty or: [yRegion isEmpty]) ifTrue:
		[^PointRegion make].
	yRegion isFull ifTrue:
		[^(SlicePointRegion make.IntegerRegion: xRegion) canonicalForm].
	(xRegion isFinite and: [xRegion isSimple and: [yRegion isFinite and: [yRegion isSimple]]])
		ifTrue: [^ PointRegion 
					make: xRegion start 
					with: yRegion start 
					with: xRegion stop 
					with: yRegion stop].
	yRegion isBoundedBelow
		ifTrue: [odd _ IntegerRegion make. even _ xRegion]
		ifFalse: [even _ IntegerRegion make. odd _ xRegion].
	slices _ PtrArray nulls: yRegion transitionCount.
	Int32Zero almostTo: yRegion transitionCount do: [ :i {Int32} |
		(i bitAnd: 1) == Int32Zero
			ifTrue: [slices at: i store: even]
			ifFalse: [slices at: i store: odd]].
	result _ SlicePointRegion
		create: odd 
		with: yRegion transitionCount 
		with: (IntegerRegion badlyViolatePrivacyOfIntegerRegionTransitions: yRegion)
		with: slices.
	^ result canonicalForm!

{PointRegion INLINE} make.IntegerVar: width {IntegerVar} with: height {IntegerVar}
	"Create a region from the origin to (width x height)."
	^PointRegion make: IntegerVar0 with: IntegerVar0 with: width with: height!

{PointRegion} make.PointTranslateDsp: dsp {PointTranslateDsp}
	"Create a region from the origin to (dsp of: origin)."
	^PointRegion make: IntegerVar0 with: IntegerVar0 with: dsp x with: dsp y!

make.XuPoint: point {PointPos} 
	^self make: point x with: point y with: point x + 1 with: point y + 1!

make.XuPoint: corner1 {PointPos} with: corner2 {PointPos}
	^PointRegion make: corner1 x with: corner1 y with: corner2 x with: corner2 y!

make: x1 {IntegerVar} with: y1 {IntegerVar} with: x2 {IntegerVar} with: y2 {IntegerVar}
	| left {IntegerVar} right {IntegerVar} top {IntegerVar} bottom {IntegerVar} |
	(x1 = x2 or: [y1 = y2]) ifTrue: [^ self make].
	x1 < x2
		ifTrue: [left _ x1. right _ x2]
		ifFalse: [left _ x2. right _ x1].
	y1 < y2
		ifTrue: [top _ y1. bottom _ y2]
		ifFalse: [top _ y2. bottom _ y1].

	^ RectanglePointRegion make: left with: top with: right with: bottom!

{PointRegion} regionExtent: point {PointPos} 
	^self make: IntegerVar0 with: IntegerVar0 with: point x with: point y!

{PointRegion} regionExtent: corner {PointPos} with: extent {PointPos} 
	^self make: corner x with: corner y with: corner x + extent x with: corner y + extent y! !

!PointRegion class methodsFor: 'smalltalk: smalltalk pcreate'!

make: a 
	(a isKindOf: IntegerRegion) ifTrue: [^self make.IntegerRegion: a].
	(a isKindOf: PointPos) ifTrue: [^self make.XuPoint: a].
	^self make.PointTranslateDsp: (a cast: PointTranslateDsp)!

make: a with: b 
	a isInteger ifTrue: [^self make.IntegerVar: a with: b].
	(a isKindOf: IntegerRegion) ifTrue: [^self make.IntegerRegion: a with: b].
	^self make.XuPoint: (a cast: PointPos) with: (b cast: PointPos)! !

!PointRegion class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: RectanglePointRegion.
	TheEmptyPointRegion _ RectanglePointRegion make: IntegerVar0 with: IntegerVar0 with: IntegerVar0 with: IntegerVar0!

linkTimeNonInherited
	TheEmptyPointRegion _ NULL.! !