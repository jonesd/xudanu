'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:26 pm'!

CrossMapping subclass: #PointTranslateDsp
	instanceVariableNames: '
		myX {IntegerMapping}
		myY {IntegerVar}'
	classVariableNames: 'TheIdentityPointDsp {PointTranslateDsp} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!

(PointTranslateDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PointTranslateDsp methodsFor: 'combining'!

{Dsp} compose: other {Dsp} 

	| dsp {PointTranslateDsp} |
	(TheIdentityPointDsp basicCast: Heaper star) == self
		ifTrue: [^ other]
		ifFalse: [(TheIdentityPointDsp basicCast: Heaper star) == other ifTrue: [^ self]].
	dsp _ other cast: PointTranslateDsp.
	^PointTranslateDsp create: ((myX compose: dsp xDsp) quickCast: IntegerMapping)
		with: (myY + dsp y)!

{Mapping} inverse

	^PointTranslateDsp create: (myX inverse cast: IntegerMapping) with: myY negated!

{Dsp INLINE} inverseCompose: other {Dsp}

	^ other minus: self!

{Dsp} minus: other {Dsp} 

	| dsp {PointTranslateDsp} |
	dsp _ other cast: PointTranslateDsp.
	^PointTranslateDsp create: ((myX minus: dsp xDsp) cast: IntegerMapping)
		with: (myY - dsp y)! !

!PointTranslateDsp methodsFor: 'create'!

create: x {IntegerMapping} with: y {IntegerVar}
	super create.
	myX _ x.
	myY _ y! !

!PointTranslateDsp methodsFor: 'testing'!

{UInt32} hashForEqual
	^myX hashForEqual bitXor: myY DOTasLong * 31!

{BooleanVar} isEqual: other {Heaper}
	"Should have same offset and reversal"
	
	other
		cast: PointTranslateDsp into: [:ptd |
			^(ptd xDsp isEqual: myX)
			 and: [ptd y == myY]]
		others: [^false].
	^ false. "compiler fodder"!

{BooleanVar} isIdentity
	^myY == IntegerVar0 and: [myX isIdentity]! !

!PointTranslateDsp methodsFor: 'accessing'!

{CoordinateSpace INLINE} coordinateSpace

	^PointSpace make!

{Dsp} subMapping: index {Int32}

	index = Int32Zero ifTrue:
		[^myX].
	index = 1 ifTrue:
		[^IntegerMapping make: myY].
	Heaper BLAST: #IndexOutOfBounds. ^NULL!

{PtrArray of: Dsp} subMappings

	^(PrimSpec pointer arrayWithTwo: myX
		with: (IntegerMapping make: myY)) cast: PtrArray!

{IntegerVar INLINE} x
	^myX translation!

{IntegerMapping INLINE} xDsp
	^myX!

{IntegerVar INLINE} y
	^ myY! !

!PointTranslateDsp methodsFor: 'transforming'!

{Position} inverseOf: something {Position}

	| point {PointPos} |
	(TheIdentityPointDsp basicCast: Heaper star) == self ifTrue: [^ something].
	point _ something cast: PointPos.
	^PointPos make: (myX inverseOfInt: point x) with: point y - myY!

{XnRegion} inverseOfAll: something {XnRegion} 

	(TheIdentityPointDsp basicCast: Heaper star) == self ifTrue: [^something].
	something
		cast: SlicePointRegion into: [:spr |
			| result {SliceAccumulator} slices {SliceStepper} |
			result _ SliceAccumulator create: ((myX inverseOfAll: spr firstSlice)
							quickCast: IntegerRegion)
						with: spr sliceCount.
			(slices _ spr sliceStepper) 
				forEach: [:each {IntegerRegion} | 
					result slice: slices y - myY with: ((myX inverseOfAll: each)
						cast: IntegerRegion)].
			^result region]
		cast: RectanglePointRegion into: [:rpr |
			^RectanglePointRegion
				make: (myX inverseOfInt: rpr left)
				with: rpr top - myY
				with: (myX inverseOfInt: rpr right)
				with: rpr bottom - myY].
	^NULL "fodder"!

{Position} of: something {Position}

	| point {PointPos} |
	(TheIdentityPointDsp basicCast: Heaper star) == self ifTrue: [^ something].
	point _ something cast: PointPos.
	^PointPos make: (myX ofInt: point x) with: point y + myY!

{XnRegion} ofAll: something {XnRegion} 

	(TheIdentityPointDsp basicCast: Heaper star) == self ifTrue: [^something].
	something
		cast: SlicePointRegion into: [:spr |
			| result {SliceAccumulator} slices {SliceStepper} |
			result _ SliceAccumulator create: ((myX ofAll: spr firstSlice)
							quickCast: IntegerRegion)
						with: spr sliceCount.
			(slices _ spr sliceStepper) 
				forEach: [:each {IntegerRegion} | 
					result slice: slices y + myY with: ((myX ofAll: each)
						cast: IntegerRegion)].
			^result region]
		cast: RectanglePointRegion into: [:rpr |
			^RectanglePointRegion
				make: (myX ofInt: rpr left)
				with: rpr top + myY
				with: (myX ofInt: rpr right)
				with: rpr bottom + myY].
	^NULL "fodder"! !

!PointTranslateDsp methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << self getCategory name << '(' << myX translation << ', ' << myY << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PointTranslateDsp class
	instanceVariableNames: ''!

(PointTranslateDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PointTranslateDsp class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self REQUIRES: IntegerMapping.
	TheIdentityPointDsp _ PointTranslateDsp create: IntegerMapping make with: IntegerVar0!

linkTimeNonInherited
	TheIdentityPointDsp _ NULL! !

!PointTranslateDsp class methodsFor: 'pseudo constructors'!

{PointTranslateDsp INLINE} make
	^TheIdentityPointDsp!

make: point {PointPos}
	^PointTranslateDsp create: (IntegerMapping make: point x) with: point y!

make: x {IntegerVar} with: y {IntegerVar}
	^self create: (IntegerMapping make: x) with: y! !