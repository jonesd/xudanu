'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:12 pm'!

CrossRegion subclass: #UnionCrossRegion
	instanceVariableNames: '
		mySpace {CrossSpace}
		mySimpleRegions {ImmuSet of: CrossRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
UnionCrossRegion comment:
'Default implementation of the union of any number of simple cross regions other than one.  The union of exactly one cross region should simply be represented by that cross region itself.

When I am the union of more than one simple cross region, them I am a complex region.  When I am the union of zero simple cross regions, then I am the empty region for my space.  Because I represent the empty region by not holding onto any other regions, I have to separately remember what space I''m from.'!

(UnionCrossRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!UnionCrossRegion methodsFor: 'testing'!

{BooleanVar} hasMember: atPos {Position} 
	
	self simpleRegions forEach: [:sr {CrossRegion} |
		(sr hasMember: atPos) ifTrue:
			[^true]].
	^false!

{BooleanVar} isEmpty
	
	^mySimpleRegions isEmpty!

{BooleanVar} isEnumerable: order {OrderSpec unused default: NULL}
	
	self simpleRegions forEach: [:sr {CrossRegion} |
		(sr isEnumerable: order) ifFalse:
			[^false]].
	
	self knownBug. "Just because all my component SimpleRegions are themselves enumerable in the specified order doesn't mean that I am (See XuRegion::stepper).  Recall that the definition of enumerable is that any given position will eventually be reached by the enumeration.  If all but one of my components are finite and the remaining one is enumerable, then I am enumerable.  If any of my components are not enumerable, then I am not enumerable.  In the remaining cases, I don't know how to figure it out.
	
	Note that this method still satisfies the weaker operational requirement that iff I say I am enumerable, I will return a properly formed stepper.  The issue is whether the stepper will eventually step to any given position."
	
	^true!

{BooleanVar} isEqual: other {Heaper}
	
	MarkM shouldImplement!

{BooleanVar} isFinite
	
	self simpleRegions forEach: [:sr {CrossRegion} |
		sr isFinite ifFalse:
			[^false]].
	^true!

{BooleanVar CLIENT} isFull

	^false!

{BooleanVar} isSimple
	
	^self isEmpty! !

!UnionCrossRegion methodsFor: 'enumerating'!

{IntegerVar} count
	
	| result {IntegerVar} |
	result := Int32Zero.
	self disjointSimpleRegions forEach: [:sr {CrossRegion} |
		result := result + sr count].
	^result!

{ScruSet of: XnRegion} distinctions
	
	self isEmpty ifFalse:
		[Heaper BLAST: #InvalidRequest].
	^ImmuSet make with: self!

{Stepper} simpleRegions: order {OrderSpec default: NULL} 
	
	order ~~ NULL ifTrue:
		[self unimplemented].
	^mySimpleRegions stepper! !

!UnionCrossRegion methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	^mySpace!

{PtrArray of: XnRegion} projections
	
	| subSpaces {PtrArray of: CoordinateSpace} result {PtrArray of: XnRegion} |
	subSpaces := mySpace axes.
	result := PtrArray nulls: subSpaces count.
	Int32Zero almostTo: subSpaces count do: [:i {Int32} |
		result at: i store: ((subSpaces fetch: i) cast: CoordinateSpace) emptyRegion].
	self simpleRegions forEach: [:sr {CrossRegion} |
		| projs {PtrArray of: XnRegion} |
		projs := sr projections.
		Int32Zero almostTo: subSpaces count do: [:i {Int32} |
			result at: i store: 
				(((result fetch: i) cast: XnRegion) unionWith: ((projs fetch: i) cast: XnRegion))]].
	^result! !

!UnionCrossRegion methodsFor: 'operations'!

{XnRegion} asSimpleRegion

	| projs {PtrArray of: XnRegion} newProjs {PtrArray of: XnRegion} |
	"The asSimpleRegion of a cross region is the cross of the asSimpleRegions of its projections"
	
	projs := self projections.
	newProjs := PtrArray nulls: projs count.
	Int32Zero almostTo: projs count do: [:i {Int32} |
		newProjs at: i store: ((projs fetch: i) cast: XnRegion) asSimpleRegion].
	^SimpleCrossRegion make: mySpace with: newProjs!

{XnRegion} complement

	| result {XnRegion} |
	"The complement of the union is the intersection of the complements"
	
	result := mySpace fullRegion.
	self simpleRegions forEach: [:sr {CrossRegion} |
		result := result intersect: sr complement].
	^result!

{XnRegion} intersect: other {XnRegion} 
	
	| acc {Accumulator} |
	acc := SetAccumulator make.
	self simpleRegions forEach: [:sr1 {CrossRegion} |
		(other intersect: sr1) simpleRegions forEach: [:sr2 {CrossRegion} |
			acc step: sr2]].
	^UnionCrossRegion make: mySpace with: (acc value cast: ScruSet)!

{XnRegion} unionWith: other {XnRegion}

	| acc {Accumulator} |
	acc := Accumulator ptrArray.
	self simpleRegions forEach: [:sr1 {CrossRegion} |
		acc step: sr1].
	other simpleRegions forEach: [:sr2 {CrossRegion} |
		acc step: sr2].
	^UnionCrossRegion make: mySpace with: (acc value cast: ScruSet)! !

!UnionCrossRegion methodsFor: 'private: creation'!

create: space {CrossSpace} with: simpleRegions {ScruSet of: CrossRegion}

	super create.
	mySpace := space.
	mySimpleRegions := simpleRegions asImmuSet! !

!UnionCrossRegion methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec}

	| result {Stepper of: Position} |
	result := Stepper emptyStepper.
	self simpleRegions forEach: [:sr {CrossRegion} |
		result := MergeStepper make: result with: (sr stepper: order) with: order].
	^result! !

!UnionCrossRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	| prefix {Character star} |
	oo << ${.
	prefix := ''.
	mySimpleRegions stepper forEach: [ :simple {XuRegion} |
		oo << prefix << simple.
		prefix := ' U '].
	oo << ${! !

!UnionCrossRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySpace _ receiver receiveHeaper.
	mySimpleRegions _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySpace.
	xmtr sendHeaper: mySimpleRegions.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnionCrossRegion class
	instanceVariableNames: ''!

(UnionCrossRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!UnionCrossRegion class methodsFor: 'pseudoconstructors'!

{CrossRegion} make: space {CrossSpace} with: simpleRegions {ScruSet of: CrossRegion}
	"Given a space and a set of simple regions from the space, make the region which is the union of those simple regions.  The space is provided since, in the case of the empty set, we need to know which space we're supposed to construct the empty region of."
	
	simpleRegions stepper forEach: [:sr {CrossRegion} |
		sr isSimple assert: 'Must be simple'].
	simpleRegions count = 1 ifTrue: 
		[^simpleRegions theOne cast: CrossRegion].
	[MarkM shouldImplement] class. "further canonicalization requirements"
	^self create: space with: simpleRegions! !