'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:11 pm'!

CrossRegion subclass: #SimpleCrossRegion
	instanceVariableNames: 'myProjections {PtrArray of: XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
SimpleCrossRegion comment:
'Default implementation of a rectangular cross of simple regions.  Such a cross is itself considered simple.  Note that the code in here doesn''t have to handle the case of an empty cross region because that is handled by EmptyCrossRegion.  Niether does it need to handle the case of a non-full distinction because that is handled by CrossDistinction.  As a special canonicalization case, this class handles a full cross region even though that is a distinction, since there is no one natural canonical way for CrossDistinction to do so. [Can`t you just have dimension = -1? /ravi/3/31/92/]'!

(SimpleCrossRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SimpleCrossRegion methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	| spaces {PtrArray of: CoordinateSpace} |
	spaces := PtrArray nulls: myProjections count.
	Int32Zero almostTo: spaces count do: [:i {Int32} |
		spaces at: i store: (self projection: i) coordinateSpace].
	^CrossSpace make: spaces!

{PtrArray of: XnRegion} projections
	
	^myProjections! !

!SimpleCrossRegion methodsFor: 'testing'!

{BooleanVar} hasMember: atPos {Position} 
	
	| tuple {Tuple} |
	tuple := atPos cast: Tuple.
	Int32Zero almostTo: myProjections count do: [:i {Int32} |
		((self projection: i) hasMember: (tuple coordinate: i)) ifFalse:
			[^false]].
	^true!

{BooleanVar} isEmpty
	"Empties must use EmptyCrossRegion instead"
	
	^false!

{BooleanVar} isEnumerable: order {OrderSpec default: NULL}
	"A cross of simple regions is enumerable in a cross-ordering iff the simple region of the most significant dimension is enumerable in its component of the ordering, and the simple regions of all less significant dimensions are finite."
	
	| ord {CrossOrderSpec}
	  dim {Int32} |
	  
	myProjections count = Int32Zero ifTrue:
		[^true].

	order == NULL ifTrue:
		[ord := self coordinateSpace getAscending cast: CrossOrderSpec]
	ifFalse:
		[ord := order cast: CrossOrderSpec].

	dim := ord lexOrder integerAt: Int32Zero.
	((self projection: dim) isEnumerable: (ord subOrder: dim)) ifFalse:
		[^false].
	1 almostTo: myProjections count do: [:i {Int32} |
		dim := ord lexOrder integerAt: i.
		(self projection: dim) isFinite ifFalse:
			[^false]].
	^true!

{BooleanVar} isEqual: other {Heaper}
	
	other 
		cast: CrossRegion into: [:cr |
			^cr isSimple and: [myProjections contentsEqual: cr projections]]
		others: [^false]!

{BooleanVar} isFinite
	"Even though an infinite region cross an empty region is still finite, such a case would use EmptyCrossRegion instead, so the code below works."
	
	Int32Zero almostTo: myProjections count do: [:i {Int32} |
		(self projection: i) isFinite ifFalse:
			[^false]].
	^true!

{BooleanVar CLIENT} isFull

	^false!

{BooleanVar} isSimple
	
	^true! !

!SimpleCrossRegion methodsFor: 'enumerating'!

{IntegerVar} count
	"Even though the cross of an infinite region and an empty region has a count of zero and the code below would BLAST instead, this is still correct because the problematic case is empty and would therefore use EmptyCrossRegion"
	
	| result {IntegerVar} |
	result := 1.
	Int32Zero almostTo: myProjections count do: [:i {Int32} |
		result := result * (self projection: i) count].
	^result!

{ScruSet of: XnRegion} distinctions

	| space {CrossSpace} acc {Accumulator} |
	self isFull ifTrue:
		[^ImmuSet make].
	space := self coordinateSpace cast: CrossSpace.
	acc := SetAccumulator make.
	Int32Zero almostTo: myProjections count do: [:i {Int32} |
		(self projection: i) distinctions stepper forEach: [:dist {XnRegion} |
			acc step: (CrossDistinction make: space with: i with: dist)]].
	^acc value cast: ScruSet!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL} 

	^Stepper itemStepper: self!

{Stepper of: Position} stepper: order {OrderSpec default: NULL}

	| space {CrossSpace} 
	  ord {CrossOrderSpec} 
	  steppers {PtrArray of: (Stepper of: Position)} |
	  
	space := self coordinateSpace cast: CrossSpace.
	order == NULL ifTrue:
		[ord := space ascending cast: CrossOrderSpec]
	ifFalse:
		[ord := order cast: CrossOrderSpec].
	steppers := PtrArray nulls: myProjections count.
	Int32Zero almostTo: myProjections count do: [:i {Int32} |
		steppers at: i store: ((self projection: i) stepper: (ord subOrder: i))].
	^TupleStepper make: space with: steppers with: ord lexOrder! !

!SimpleCrossRegion methodsFor: 'private: creation'!

create: projections {PtrArray of: XnRegion}

	super create.
	myProjections := projections! !

!SimpleCrossRegion methodsFor: 'operations'!

{XnRegion} asSimpleRegion

	^self!

{XnRegion} complement

	| acc {Accumulator} |
	"The complement of the intersection of distinctions is the union of the complement of distinctions"
	
	acc := SetAccumulator make.
	self distinctions stepper forEach: [:dist {CrossRegion} |
		acc step: dist complement].
	^UnionCrossRegion make: (self coordinateSpace cast: CrossSpace) with: (acc value cast: ScruSet)!

{XnRegion} intersect: other {XnRegion} 
	
	| newProjs {PtrArray of: XnRegion} o {CrossRegion} |
	other isSimple not ifTrue:
		[^other intersect: self].
	o := other cast: CrossRegion.
	newProjs := PtrArray nulls: myProjections count.
	Int32Zero almostTo: newProjs count do: [:i {Int32} |
		newProjs at: i store: ((self projection: i) intersect: (o projection: i))].
	^SimpleCrossRegion make: (self coordinateSpace cast: CrossSpace) with: newProjs!

{XnRegion} unionWith: other {XnRegion} 
	
	| acc {Accumulator} |
	acc := SetAccumulator make.
	acc step: self.
	other simpleRegions forEach: [:sr {CrossRegion} |
		acc step: sr].
	^UnionCrossRegion make: (self coordinateSpace cast: CrossSpace) with: (acc value cast: ScruSet)! !

!SimpleCrossRegion methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 

	| space {CrossSpace} 
	  steppers {PtrArray of: (Stepper of: Position)} |
	  
	space := self coordinateSpace cast: CrossSpace.
	steppers := PtrArray nulls: myProjections count.
	Int32Zero almostTo: myProjections count do: [:i {Int32} |
		steppers at: i store: ((self projection: i) stepper: ((order cast: CrossOrderSpec) subOrder: i))].
	^TupleStepper make: space with: steppers with: (order cast: CrossOrderSpec) lexOrder! !

!SimpleCrossRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << ${.
	Int32Zero almostTo: myProjections count do: [ :i {Int32} |
		i > Int32Zero ifTrue:
			[oo << ' x '].
		oo << (myProjections fetch: i)].
	oo << $}! !

!SimpleCrossRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myProjections _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myProjections.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SimpleCrossRegion class
	instanceVariableNames: ''!

(SimpleCrossRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SimpleCrossRegion class methodsFor: 'pseudoconstructors'!

{CrossRegion} make: space {CrossSpace} with: projections {PtrArray of: XnRegion}

	Int32Zero almostTo: projections count do: [:i {Int32} |
		((projections fetch: i) cast: XnRegion) isSimple assert: 'Must use UnionCrossRegion otherwise'.
		((projections fetch: i) cast: XnRegion) isEmpty ifTrue:
			[^space emptyRegion cast: CrossRegion]].
	^self create: projections! !