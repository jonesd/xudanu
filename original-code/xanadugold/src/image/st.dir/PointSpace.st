'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:25 pm'!

CrossSpace subclass: #PointSpace
	instanceVariableNames: ''
	classVariableNames: 'TheSpace {PointSpace} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!
PointSpace comment:
'A two-dimensional space of Integer X Integer'!

(PointSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #PSEUDO.COPY; yourself)!

!PointSpace methodsFor: 'create'!

create
	super create.
	self finishCreate: (SlicePointRegion using: (IntegerSpace make emptyRegion cast: IntegerRegion))
		with: (SlicePointRegion using: (IntegerSpace make fullRegion cast: IntegerRegion))
		with: (PointTranslateDsp make: IntegerVar0 with: IntegerVarZero)
		with: NULL
		with: NULL.
	[[Dean shouldImplement] class] smalltalkOnly. "should pass a canonical UpOrder at least"! !

!PointSpace methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	aStream << self getCategory name << '('
	
	<< ' not really implemented ' << ') '! !

!PointSpace methodsFor: 'testing'!

{UInt32} hashForEqual

	^self getCategory hashForEqual + 1!

{BooleanVar INLINE} isEqual: anObject {Heaper}

	^anObject isKindOf: PointSpace! !

!PointSpace methodsFor: 'making'!

{Mapping} crossOfMappings: subMappings {(PtrArray of: Mapping | NULL) default: NULL}

	| x {Heaper} y {Heaper} |
	subMappings == NULL
		ifTrue: [^self identityDsp].
	x := subMappings fetch: Int32Zero.
	x ~~ NULL ifTrue:
		[x cast: IntegerMapping into: [ :xDsp |
			y := subMappings fetch: 1.
			y ~~ NULL ifTrue:
				[y cast: IntegerMapping into: [ :yDsp |
					^PointTranslateDsp create: xDsp with: yDsp translation]
				others:
					[self unimplemented]]
			ifFalse:
				[^PointTranslateDsp create: xDsp with: IntegerVarZero]]
		others:
			[self unimplemented]].
	y := subMappings fetch: 1.
	y ~~ NULL ifTrue:
		[y cast: IntegerMapping into: [ :yDsp |
			^PointTranslateDsp create: (IntegerSpace make identityDsp cast: IntegerMapping)
				with: yDsp translation]
		others:
			[self unimplemented]]
	ifFalse:
		[^self identityDsp cast: IntegerMapping].
	^NULL "fodder"!

{CrossOrderSpec INLINE} crossOfOrderSpecs: subOrderings {(PtrArray of: OrderSpec | NULL) default: NULL}
	with: subSpaceOrdering {PrimIntArray default: NULL}

	^CrossOrderSpec make: self with: subOrderings with: subSpaceOrdering!

{Tuple} crossOfPositions: coordinates {PtrArray of: Position}

	^PointPos create: ((coordinates fetch: Int32Zero) cast: IntegerPos) asIntegerVar
		with: ((coordinates fetch: 1) cast: IntegerPos) asIntegerVar!

{CrossRegion} crossOfRegions: subRegions {PtrArray of: XnRegion | NULL}

	| x {IntegerRegion} y {IntegerRegion} |
	x := (subRegions fetch: Int32Zero) cast: IntegerRegion.
	x == NULL ifTrue:
		[x := IntegerSpace make fullRegion cast: IntegerRegion].
	y := (subRegions fetch: 1) cast: IntegerRegion.
	y == NULL ifTrue:
		[y := IntegerSpace make fullRegion cast: IntegerRegion].
	^PointRegion make.IntegerRegion: x with: y!

{CrossRegion} extrusion: dimension {Int32} with: subRegion {XnRegion}

	dimension == Int32Zero ifTrue:
		[^PointRegion make.IntegerRegion: (subRegion cast: IntegerRegion)
			with: (IntegerSpace make fullRegion cast: IntegerRegion)]
	ifFalse: [dimension = 1 ifTrue:
		[^PointRegion make.IntegerRegion: (IntegerSpace make fullRegion cast: IntegerRegion)
			with: (subRegion cast: IntegerRegion)]
	ifFalse:
		[Heaper BLAST: #IndexOutOfBounds. ^NULL]]! !

!PointSpace methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PointSpace class
	instanceVariableNames: ''!

(PointSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #PSEUDO.COPY; yourself)!

!PointSpace class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	TheSpace _ self create!

linkTimeNonInherited
	TheSpace _ NULL! !

!PointSpace class methodsFor: 'rcvr pseudo constructors'!

{Heaper} make.Rcvr: rcvr {Rcvr}
	(rcvr cast: SpecialistRcvr) registerIbid: TheSpace.
	^TheSpace! !

!PointSpace class methodsFor: 'pseudo constructors'!

{PointSpace INLINE} make 
	^TheSpace! !