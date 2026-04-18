'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:53 pm'!

XnRegion subclass: #RealRegion
	instanceVariableNames: '
		myStartsInside {BooleanVar}
		myTransitionVals {PrimFloatArray}
		myTransitionFlags {PrimIntegerArray}'
	classVariableNames: 'TheManager {RealManager} '
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(RealRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!RealRegion methodsFor: 'enumerating'!

{IntegerVar INLINE} count

	^TheManager count: self!

{ScruSet INLINE of: XnRegion} distinctions

	^TheManager distinctions: self!

{Stepper CLIENT INLINE of: RealRegion} intervals: order {OrderSpec default: NULL}
	"Essential. Break this up into disjoint intervals"
	
	^ self simpleRegions: order!

{BooleanVar CLIENT INLINE} isInterval
	"Whether this Region is a non-empty interval, i.e. if A, B in the Region and A <= C <= B then C is in the Region. This includes inequalities (e.g. {x | x > 5}) and the fullRegion in addition to ordinary two-ended intervals."
	
	^self isSimple!

{Stepper} simpleRegions: order {OrderSpec default: NULL} 

	^TheManager simpleRegions: self with: order!

{Stepper of: Position} stepper: order {OrderSpec default: NULL} 

	self isFinite ifFalse:
		[Heaper BLAST: #NotEnumerable].
	^RealStepper create: self secretTransitions! !

!RealRegion methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 

	self shouldNotImplement.
	^NULL "fodder"! !

!RealRegion methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^((self getCategory hashForEqual
		bitXor: (myTransitionVals contentsHash))
		bitXor: (myTransitionFlags contentsHash))
		bitXor: (myStartsInside ifTrue: [255] ifFalse: [UInt32Zero])!

{BooleanVar INLINE} hasMember: position {Position} 

	^TheManager hasMember: self with: position!

{BooleanVar CLIENT INLINE} isBoundedAbove
	"Same meaning as IntegerRegion::isBoundedAbove"
	
	^TheManager isBoundedRight: self!

{BooleanVar CLIENT INLINE} isBoundedBelow
	"Same meaning as IntegerRegion::isBoundedBelow"
	
	^TheManager isBoundedLeft: self!

{BooleanVar INLINE} isEmpty

	^TheManager isEmpty: self!

{BooleanVar INLINE} isEnumerable: order {OrderSpec default: NULL}
	"Any representable infinite set of real numbers is also not enumerable"

	^self isFinite!

{BooleanVar} isEqual: other {Heaper}

	other cast: RealRegion into: [ :region |
		^myStartsInside == region startsInside
			and: [self secretTransitions contentsEqual: region secretTransitions]]
	others:
		[^false].
	^false "fodder"!

{BooleanVar} isFinite

	^TheManager isFinite: self!

{BooleanVar} isFull

	^TheManager isFull: self!

{BooleanVar} isSimple

	^TheManager isSimple: self!

{BooleanVar} isSubsetOf: other {XnRegion}
	
	^TheManager isSubsetOf: self with: other! !

!RealRegion methodsFor: 'operations'!

{XnRegion INLINE} complement

	^TheManager complement: self!

{XnRegion INLINE} intersect: other {XnRegion} 

	^TheManager intersect: self with: other!

{XnRegion} simpleUnion: other {XnRegion} 

	^TheManager simpleUnion: self with: other!

{XnRegion} unionWith: other {XnRegion} 

	^TheManager unionWith: self with: other! !

!RealRegion methodsFor: 'secret'!

{PtrArray of: RealEdge} secretTransitions

	| result {PtrArray of: RealEdge} |
	result := (PrimSpec pointer array: myTransitionVals count) cast: PtrArray.
	Int32Zero almostTo: result count do: [: i {Int32} |
		| pos {RealPos} edge {RealEdge} |
		pos := RealPos make: (myTransitionVals floatAt: i).
		(myTransitionFlags integerAt: i) = IntegerVar0 ifTrue:
			[edge := BeforeReal make: pos]
		ifFalse:
			[edge := AfterReal make: pos].
		result at: i store: edge].
	^result!

{BooleanVar INLINE} startsInside

	^myStartsInside! !

!RealRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	TheManager printRegionOn: self with: oo! !

!RealRegion methodsFor: 'accessing'!

{XnRegion INLINE} asSimpleRegion

	^TheManager asSimpleRegion: self!

{CoordinateSpace INLINE} coordinateSpace
	
	^RealSpace make!

{RealPos CLIENT} lowerBound
	"The largest real number such that all the positions in the region are >= it.  Does not necessarily lie in the region.  For example, the region of all numbers > 2 has a lowerBound of 2."

	^(TheManager greatestLowerBound: self) cast: RealPos!

{RealPos CLIENT} upperBound
	"The smallest real number such that all the positions in the region are <= it.  Does not necessarily lie in the region.  For example, the region of all numbers < 2 has an upperBound of 2."

	^(TheManager leastUpperBound: self) cast: RealPos! !

!RealRegion methodsFor: 'creation'!

create: startsInside {BooleanVar} with: vals {PrimFloatArray} with: flags {PrimIntegerArray}

	super create.
	myStartsInside := startsInside.
	myTransitionVals := vals.
	myTransitionFlags := flags! !

!RealRegion methodsFor: 'smalltalk: defaults'!

{Stepper CLIENT of: RealRegion} intervals
	^self intervals: NULL! !

!RealRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myStartsInside _ receiver receiveBooleanVar.
	myTransitionVals _ receiver receiveHeaper.
	myTransitionFlags _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendBooleanVar: myStartsInside.
	xmtr sendHeaper: myTransitionVals.
	xmtr sendHeaper: myTransitionFlags.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RealRegion class
	instanceVariableNames: ''!

(RealRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!RealRegion class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	
	self REQUIRES: EdgeManager.
	TheManager := RealManager create.!

linkTimeNonInherited
	
	TheManager := NULL.! !

!RealRegion class methodsFor: 'creation'!

{RealRegion} make: startsInside {BooleanVar}
	with: transitions {PrimArray of: RealEdge}
	"Make a new region, reusing the given array. Noone else should ever modify it!!"

	| precision {Int32} spec {PrimSpec} transVals {PrimFloatArray} transFlags {PrimIntegerArray} tr {PtrArray} |
	tr := transitions cast: PtrArray.
	precision := Int32Zero.
	Int32Zero almostTo: transitions count do: [:i {Int32} |
		precision := precision max: ((tr get: i) cast: RealEdge) position precision].
	precision = 64 ifTrue:
		[spec := PrimSpec iEEE64]
	ifFalse: [precision = 32 ifTrue:
		[spec := PrimSpec iEEE32]
	ifFalse: [precision = 8 ifTrue:
		[spec := PrimSpec iEEE32.
		self thingToDo. "add an iEEE8 spec to the system and use it here"]
	ifFalse: [transitions count = Int32Zero ifTrue:
		[spec := PrimSpec iEEE64]
	ifFalse:
		[Heaper BLAST: #UnrecognizedPrecision]]]].
	transVals := (spec array: transitions count) cast: PrimFloatArray.
	transFlags := (PrimSpec uInt8 array: tr count) cast: PrimIntegerArray.
	self thingToDo. "add 'PrimSpec uInt1' to the system and use it here"
	
	Int32Zero almostTo: transitions count do: [:i {Int32} |
		| edge {RealEdge} flag {UInt1} |
		edge := ((tr get: i) cast: RealEdge).
		transVals at: i storeFloat: edge position asIEEE64.
		edge
			cast: BeforeReal into: [:after | flag := UInt32Zero]
			cast: AfterReal into: [:before | flag := 1].
		transFlags at: i storeInteger: flag].
		
	^self using: startsInside with: transVals with: transFlags!

{RealRegion} using: startsInside {BooleanVar} with: vals {PrimFloatArray} with: flags {PrimIntegerArray}

	^self create: startsInside with: vals with: flags! !

!RealRegion class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Stepper CLIENT of: RealRegion} intervals: order {OrderSpec default: NULL}
{BooleanVar CLIENT} isBoundedAbove
{BooleanVar CLIENT} isBoundedBelow
{BooleanVar CLIENT} isInterval
{XuReal CLIENT} lowerBound
{XuReal CLIENT} upperBound
"! !