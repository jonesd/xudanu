'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:56 pm'!

XnRegion subclass: #SequenceRegion
	instanceVariableNames: '
		myStartsInside {BooleanVar}
		myTransitions {PtrArray NOCOPY of: SequenceEdge}
		myTransitionsCount {Int32}'
	classVariableNames: '
		TheEmptySequenceRegion {SequenceRegion} 
		TheFullSequenceRegion {SequenceRegion} 
		TheManager {SequenceManager} '
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
SequenceRegion comment:
'Represents a Region of Sequences. We can efficiently represent unions of intervals, delimited either by individual sequences or by a match with all sequences prefixed by some sequence up to some index.'!

(SequenceRegion getOrMakeCxxClassDescription)
	friends:
'/* friends for class SequenceRegion */

friend class Sequence;
friend class SequenceSpace;
friend class SequenceMapping;
friend class SequenceManager;
';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!SequenceRegion methodsFor: 'create'!

create: startsInside {BooleanVar} with: transitions {PtrArray of: TransitionEdge}

	super create.
	myStartsInside := startsInside.
	myTransitions := transitions.
	myTransitionsCount := transitions count.!

create: startsInside {BooleanVar} with: transitions {PtrArray of: TransitionEdge} with: count {Int32}

	super create.
	myStartsInside := startsInside.
	myTransitions := transitions.
	myTransitionsCount := count! !

!SequenceRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion

	^TheManager asSimpleRegion: self!

{CoordinateSpace} coordinateSpace

	^SequenceSpace make!

{Sequence} lowerBound
	"The largest sequence such that all the positions in the region are >= it.  Does not necessarily lie in the region.  For example, the region of all numbers > 2.3 has a lowerBound of 2.3. Mathematically, this is called the 'greatest lower bound'."

	^(TheManager greatestLowerBound: self) cast: Sequence!

{Sequence CLIENT} lowerEdge
	"Essential. The Sequence associated with the lower edge of the Region. To find out where the boundary is in relation to this sequence, check lowerEdgeType. BLASTS if unbounded below."
	
	myTransitionsCount = Int32Zero ifTrue:
		[Heaper BLAST: #InvalidRequest].
	^((myTransitions fetch: Int32Zero) cast: SequenceEdge) sequence!

{IntegerVar CLIENT} lowerEdgePrefixLimit
	"Essential. If lowerEdgeType is prefix, then it includes an Sequence matching each integer in the lowerEdge up to and including lowerEdgePrefixLimit."
	
	myTransitionsCount = Int32Zero ifTrue:
		[Heaper BLAST: #InvalidRequest].
	(myTransitions fetch: Int32Zero) cast: BeforeSequencePrefix into:
		[ :prefix | prefix limit].
	^ -1 "compiler fodder"!

{Int32 CLIENT} lowerEdgeType
	"Essential. The kind of Sequence associated with the lower edge of the Region. If SequenceRegion::inclusive then it includes the lowerEdge; if exclusive, then it does not; if prefix, then it includes any Sequence matching each integer in the lowerEdge up to and including lowerEdgePrefixLimit."
	
	myTransitionsCount = Int32Zero ifTrue:
		[Heaper BLAST: #InvalidRequest].
	(myTransitions fetch: Int32Zero) cast: BeforeSequence into:
		[ :before | ^SequenceRegion INCLUSIVE]
	cast: AfterSequence into:
		[ :after | ^SequenceRegion EXCLUSIVE]
	cast: BeforeSequencePrefix into:
		[ :prefix | ^SequenceRegion PREFIX].
	^ -1 "compiler fodder"!

{Sequence} upperBound
	"The smallest Sequence such that all the positions in the region are <= it.  Does not necessarily lie in the region.  For example, the region of all numbers < 2.3 has an upperBound of 2.3. Mathematically, this is called the 'least upper bound'."

	^(TheManager leastUpperBound: self) cast: Sequence!

{Sequence CLIENT} upperEdge
	"Essential. The Sequence associated with the upper edge of the Region. To find out where the boundary is in relation to this sequence, check upperEdgeType. BLASTS if unbounded below."
	
	myTransitionsCount = Int32Zero ifTrue:
		[Heaper BLAST: #InvalidRequest].
	^((myTransitions fetch: myTransitionsCount - 1) cast: SequenceEdge) sequence!

{IntegerVar CLIENT} upperEdgePrefixLimit
	"Essential. If upperEdgeType is prefix, then it includes a Sequence matching each integer in the upperEdge up to and including upperEdgePrefixLimit."
	
	myTransitionsCount = Int32Zero ifTrue:
		[Heaper BLAST: #InvalidRequest].
	(myTransitions fetch: myTransitionsCount - 1) cast: BeforeSequencePrefix into:
		[ :prefix | prefix limit].
	^IntegerVarZero "fodder"!

{Int32 CLIENT} upperEdgeType
	"Essential. The kind of Sequence associated with the upper edge of the Region. If SequenceRegion::inclusive then it includes the upperEdge; if exclusive, then it does not; if prefix, then it includes any Sequence matching each integer in the upperEdge up to and including upperEdgePrefixLimit."
	
	myTransitionsCount = Int32Zero ifTrue:
		[Heaper BLAST: #InvalidRequest].
	(myTransitions fetch: Int32Zero) cast: BeforeSequence into:
		[ :before | ^SequenceRegion EXCLUSIVE]
	cast: AfterSequence into:
		[ :after | ^SequenceRegion INCLUSIVE]
	cast: BeforeSequencePrefix into:
		[ :prefix | ^SequenceRegion PREFIX].
	^ -1 "compiler fodder"! !

!SequenceRegion methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(self getCategory hashForEqual
		bitXor: (myTransitions elementsHash: myTransitionsCount))
		bitXor: (myStartsInside ifTrue: [255] ifFalse: [UInt32Zero])!

{BooleanVar} hasMember: position {Position} 

	^TheManager hasMember: self with: position!

{BooleanVar CLIENT INLINE} isBoundedAbove
	"Same meaning as IntegerRegion::isBoundedAbove"
	
	^TheManager isBoundedRight: self!

{BooleanVar CLIENT INLINE} isBoundedBelow
	"Same meaning as IntegerRegion::isBoundedBelow"
	
	^TheManager isBoundedLeft: self!

{BooleanVar} isEmpty

	^TheManager isEmpty: self!

{BooleanVar} isEnumerable: order {OrderSpec unused default: NULL}

	^self isFinite!

{BooleanVar} isEqual: other {Heaper}

	other cast: SequenceRegion into: [ :region |
		^myStartsInside == region startsInside
			and: [myTransitionsCount == region secretTransitionsCount
			and: [myTransitions elementsEqual: Int32Zero with: region secretTransitions with: Int32Zero with: myTransitionsCount]]]
	others:
		[^false].
	^ false "compiler fodder"!

{BooleanVar} isFinite

	^TheManager isFinite: self!

{BooleanVar} isFull

	^TheManager isFull: self!

{BooleanVar} isSimple

	^TheManager isSimple: self!

{BooleanVar} isSubsetOf: other {XnRegion}
	
	^TheManager isSubsetOf: self with: other! !

!SequenceRegion methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 

	self shouldNotImplement.
	^NULL "fodder"! !

!SequenceRegion methodsFor: 'enumerating'!

{IntegerVar} count

	^TheManager count: self!

{ScruSet of: XnRegion} distinctions

	^TheManager distinctions: self!

{Stepper CLIENT INLINE of: SequenceRegion} intervals: order {OrderSpec default: NULL}
	"Essential. Break this up into disjoint intervals"
	
	^ self simpleRegions: order!

{BooleanVar CLIENT INLINE} isInterval
	"Whether this Region is a non-empty interval, i.e. if A, B in the Region and A <= C <= B then C is in the Region. This includes inequalities (e.g. {x | x > 5.3}) and the fullRegion in addition to ordinary two-ended intervals."
	
	^self isSimple!

{Stepper} simpleRegions: order {OrderSpec default: NULL} 

	^TheManager simpleRegions: self with: order!

{Stepper of: Position} stepper: order {OrderSpec default: NULL} 

	self isFinite ifFalse:
		[Heaper BLAST: #NotEnumerable].
	^SequenceStepper create: myTransitions with: myTransitionsCount.! !

!SequenceRegion methodsFor: 'operations'!

{XnRegion} complement

	^TheManager complement: self!

{XnRegion} intersect: other {XnRegion} 

	^TheManager intersect: self with: other!

{XnRegion} simpleUnion: other {XnRegion} 

	^TheManager simpleUnion: self with: other!

{XnRegion} unionWith: other {XnRegion} 

	^TheManager unionWith: self with: other!

{XnRegion} with: pos {Position} 

	^TheManager with: self with: pos! !

!SequenceRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	TheManager printRegionOn: self with: oo! !

!SequenceRegion methodsFor: 'secret'!

{PtrArray INLINE of: SequenceEdge} secretTransitions

	^myTransitions!

{Int32 INLINE} secretTransitionsCount

	^myTransitionsCount!

{BooleanVar INLINE} startsInside

	^myStartsInside! !

!SequenceRegion methodsFor: 'smalltalk: defaults'!

{Stepper CLIENT of: SequenceRegion} intervals
	^self intervals: NULL! !

!SequenceRegion methodsFor: 'hooks:'!

{void RECEIVE.HOOK} receiveSequenceRegion: rcvr {Rcvr}
	myTransitions := PtrArray nulls: myTransitionsCount.
	Int32Zero almostTo: myTransitionsCount do: [:i {Int32} |
		myTransitions at: i store: rcvr receiveHeaper]!

{void SEND.HOOK} sendSequenceRegion: xmtr {Xmtr}
	Int32Zero almostTo: myTransitionsCount do: [:i {Int32} |
		xmtr sendHeaper: (myTransitions fetch: i)]! !

!SequenceRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myStartsInside _ receiver receiveBooleanVar.
	myTransitionsCount _ receiver receiveInt32.
	self receiveSequenceRegion: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendBooleanVar: myStartsInside.
	xmtr sendInt32: myTransitionsCount.
	self sendSequenceRegion: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SequenceRegion class
	instanceVariableNames: ''!

(SequenceRegion getOrMakeCxxClassDescription)
	friends:
'/* friends for class SequenceRegion */

friend class Sequence;
friend class SequenceSpace;
friend class SequenceMapping;
friend class SequenceManager;
';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!SequenceRegion class methodsFor: 'smalltalk: passe'!

{SequenceRegion} with: sequence {Sequence}
	self passe.
	^self create: false
		with: (PrimSpec pointer arrayWithTwo: (BeforeSequence make: sequence)
			with: (AfterSequence make: sequence))! !

!SequenceRegion class methodsFor: 'pseudo constructors'!

{SequenceRegion} above: sequence {Sequence}

	^self create: false
		with: ((PrimSpec pointer arrayWith: (BeforeSequence make: sequence)) cast: PtrArray)!

{SequenceRegion} below: sequence {Sequence}

	^self create: true
		with: ((PrimSpec pointer arrayWith: (AfterSequence make: sequence)) cast: PtrArray)!

{SequenceRegion INLINE} empty
	
	^TheEmptySequenceRegion!

{SequenceRegion INLINE} full
	
	^TheFullSequenceRegion!

{SequenceRegion} prefixedBy: sequence {Sequence} with: limit {IntegerVar}
	"All sequences matching the given up to and including the number at limit"
	
	^self create: false
		     with: ((PrimSpec pointer
					arrayWithTwo: (BeforeSequencePrefix below: sequence with: limit)
						       with: (BeforeSequencePrefix above: sequence with: limit)) cast: PtrArray)!

{SequenceRegion} strictlyAbove: sequence {Sequence}

	^self create: false
		with: ((PrimSpec pointer arrayWith: (AfterSequence make: sequence)) cast: PtrArray)!

{SequenceRegion} strictlyBelow: sequence {Sequence}

	^self create: true
		with: ((PrimSpec pointer arrayWith: (BeforeSequence make: sequence)) cast: PtrArray)! !

!SequenceRegion class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	
	self REQUIRES: EdgeManager.
	TheManager := SequenceManager create.
	self REQUIRES: Sequence.
	self REQUIRES: SequenceSpace.
	self REQUIRES: PtrArray.
	TheEmptySequenceRegion := self create: false with: PtrArray empty.
	TheFullSequenceRegion := self create: true with: PtrArray empty.!

linkTimeNonInherited
	
	TheManager := NULL.
	TheEmptySequenceRegion := NULL.
	TheFullSequenceRegion := NULL.! !

!SequenceRegion class methodsFor: 'private:'!

{SequenceRegion} using: startsInside {BooleanVar}
	with: transitions {PtrArray of: TransitionEdge}
	"Make a new region, reusing the given array. No one else should ever modify it!!"

	^self create: startsInside with: transitions! !

!SequenceRegion class methodsFor: 'constants'!

{Int32 constFn CLIENT INLINE} EXCLUSIVE
	^2!

{Int32 constFn CLIENT INLINE} INCLUSIVE
	^1!

{Int32 constFn CLIENT INLINE} PREFIX
	^3! !

!SequenceRegion class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Int32 constFn CLIENT INLINE} EXCLUSIVE
{Int32 constFn CLIENT INLINE} INCLUSIVE
{Int32 constFn CLIENT INLINE} PREFIX
{Stepper CLIENT of: SequenceRegion} intervals: order {OrderSpec default: NULL}
{BooleanVar CLIENT} isBoundedAbove
{BooleanVar CLIENT} isBoundedBelow
{BooleanVar CLIENT} isInterval
{Sequence CLIENT} lowerEdge
{IntegerVar CLIENT} lowerEdgePrefixLimit
{Int32 CLIENT} lowerEdgeType
{Sequence CLIENT} upperEdge
{IntegerVar CLIENT} upperEdgePrefixLimit
{Int32 CLIENT} upperEdgeType
"! !