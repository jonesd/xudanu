'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:02 pm'!

Heaper subclass: #EdgeManager
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-edge'!
EdgeManager comment:
'Manages the common code for regions which are represented as a sequence of EdgeTransitions. Each coordinate space should define a subclass which implements the appropriate methods, and then use it to do the various region operations. Clients of the region do not need to see any of these classes.'!

(EdgeManager getOrMakeCxxClassDescription)
	friends:
'friend class EdgeSimpleRegionStepper;
friend class EdgeAccumulator;
';
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!EdgeManager methodsFor: 'private:'!

{EdgeAccumulator} edgeAccumulator: startsInside {BooleanVar}
	"Create an accumulator which takes edges and creates a region"
	
	^EdgeAccumulator
		make: self
		with: startsInside!

{EdgeStepper} edgeStepper: region {XnRegion}
	"Create a stepper for iterating through the edges of the region"
	
	^EdgeStepper make: (self startsInside: region) not
		with: (self transitions: region)
		with: (self transitionsCount: region)!

{TransitionEdge} lowerEdge: region {XnRegion}

	| transitions {PtrArray of: TransitionEdge} |
	transitions := self transitions: region.
	((self startsInside: region)
			or: [(self transitionsCount: region) = Int32Zero])
		ifTrue: [Heaper BLAST: #InvalidRequest].
	^(transitions fetch: Int32Zero) cast: TransitionEdge!

{EdgeStepper} singleEdgeStepper: pos {Position}
	"Create a stepper for iterating through the edges of the region"
	
	^EdgeStepper make: false not
		with: (self posTransitions: pos)!

{TransitionEdge} upperEdge: region {XnRegion}

	| transitions {PtrArray of: TransitionEdge} transitionsCount {Int32} |
	transitions := self transitions: region.
	transitionsCount := self transitionsCount: region.
	((self isBoundedRight: region) not
			or: [transitionsCount == Int32Zero])
		ifTrue: [Heaper BLAST: #InvalidRequest].
	^(transitions fetch: (transitionsCount - 1)) cast: TransitionEdge! !

!EdgeManager methodsFor: 'testing'!

{BooleanVar} hasMember: region {XnRegion} with: pos {Position}

	| edges {EdgeStepper} edge {TransitionEdge} result {BooleanVar} |
	edges := self edgeStepper: region.
	[(edge := edges fetch cast: TransitionEdge) ~~ NULL] whileTrue:
		[(edge follows: pos) ifTrue:
			[result := edges isEntering not.
			edges destroy.
			^ result].
		edges step].
	result := edges isEntering not.
	edges destroy.
	^ result!

{BooleanVar} isBoundedLeft: region {XnRegion}
	"Same meaning as IntegerRegion::isBoundedLeft"
	
	^(self startsInside: region) not!

{BooleanVar} isBoundedRight: region {XnRegion}
	"Same meaning as IntegerRegion::isBoundedRight"
	
	^(((self transitionsCount: region) bitAnd: 1) == Int32Zero)
		~~ (self startsInside: region)!

{BooleanVar} isEmpty: region {XnRegion}

	^(self startsInside: region) not
		and: [(self transitionsCount: region) = Int32Zero]!

{BooleanVar} isFinite: region {XnRegion}
	"Here is one place where the *infinite* of the infinite divisibility assumed by OrderedRegion about the full ordering comes in (see class comment).  
	An interval whose left edge is not the same as the right edge is assumed to contain an infinite number of positions"
	
	| transitions {PtrArray of: TransitionEdge} transitionsCount {Int32} |
	transitions := self transitions: region.
	transitionsCount := self transitionsCount: region.
	((self startsInside: region) or: [(transitionsCount bitAnd: 1) ~~ Int32Zero]) ifTrue:
		[^false].
	Int32Zero almostTo: transitionsCount by: 2 do: [ :i {Int32} |
		(((transitions fetch: i) cast: TransitionEdge)
				isFollowedBy: ((transitions fetch: i + 1) cast: TransitionEdge))
			ifFalse: [^false]].
	^true!

{BooleanVar} isFull: region {XnRegion}

	^(self startsInside: region)
		and: [(self transitionsCount: region) = Int32Zero]!

{BooleanVar} isSimple: region {XnRegion}
	| testVal {Int32} |
	(self startsInside: region) ifTrue: [testVal _ 1] ifFalse: [testVal _ 2].
	^(self transitionsCount: region) <= testVal!

{BooleanVar} isSubsetOf: me {XnRegion} with: other {XnRegion}

	| mine {EdgeStepper} others {EdgeStepper} result {BooleanVar} |
	(self isEmpty: other)
		ifTrue: [^self isEmpty: me].
	mine := self edgeStepper: me.
	others := self edgeStepper: other.
	(mine hasValue or: [others hasValue])
		ifFalse: [
			result := mine isEntering or: [others isEntering not].
			mine destroy.
			others destroy.
			^ result].
	(mine isEntering not and: [others isEntering]) ifTrue: [mine destroy. others destroy. ^false].
	[mine hasValue and: [others hasValue]]
		whileTrue: 
			[(others getEdge isGE: mine getEdge) not
				ifTrue: 
					[(others isEntering not and: [mine isEntering not]) ifTrue: [mine destroy. others destroy. ^false].
					others step]
				ifFalse: 
					[(mine getEdge isGE: others getEdge) not
						ifTrue: 
							[(others isEntering and: [mine isEntering]) ifTrue: [mine destroy. others destroy. ^false].
							mine step]
						ifFalse: 
							[others isEntering ~~ mine isEntering ifTrue: [mine destroy. others destroy. ^false].
							others step.
							mine step]]].
	result := ((mine hasValue and: [others isEntering])
		or: [others hasValue and: [mine isEntering not]]) not.
	mine destroy.
	others destroy.
	^ result! !

!EdgeManager methodsFor: 'enumerating'!

{IntegerVar} count: region {XnRegion}
	"Because Edge Regions should only be used on infinitely divisible spaces (like rationals), if it's finite then it is bounded on both sides, and all the internal intervals are singletons"

	(self isFinite: region) ifFalse: [Heaper BLAST: #MustBeFinite].
	^(self transitionsCount: region) // 2! !

!EdgeManager methodsFor: 'accessing'!

{XnRegion} asSimpleRegion: region {XnRegion}

	(self isSimple: region) ifTrue: [^region].
	(self isBoundedLeft: region)
		ifTrue: [(self isBoundedRight: region)
			ifTrue: [^self makeNew: false with: ((PrimSpec pointer
				arrayWithTwo: (self lowerEdge: region) with: (self upperEdge: region)) cast: PtrArray)]
			ifFalse: [^self makeNew: false with: ((PrimSpec pointer
				arrayWith: (self lowerEdge: region)) cast: PtrArray)]]
		ifFalse: [(self isBoundedRight: region)
			ifTrue: [^self makeNew: true with: ((PrimSpec pointer
				arrayWith: (self upperEdge: region)) cast: PtrArray)]
			ifFalse: [^self makeNew: true with: PtrArray empty]]!

{Position} greatestLowerBound: region {XnRegion}
	"The largest position such that no other positions in the region are any less than it. In other words, this is the lower bounding element. We choose to avoid the terms 'lowerBound' and 'upperBound' as their meanings in IntegerRegion are significantly different. Here, both 'all numbers >= 3' and 'all numbers > 3' have a 'greatestLowerBound' of 3 even though the latter doesn't include 3. To tell whether a bound is included, good old 'hasMember' should do a fine job."

	^self edgePosition: (self lowerEdge: region)!

{Position} leastUpperBound: region {XnRegion}
	"The smallest position such that no other positions in the region are 
	any greater than it. In other words, this is the upper bounding element. 
	We choose to avoid the terms 'lowerBound' and 'upperBound' as 
	their meanings in IntegerRegion are significantly different. Here, both 
	'all numbers <= 3' and 'all numbers < 3' have a 'leastUpperBound' 
	of 3 even though the latter doesn't include 3. To tell whether a 
	bound is included, good old 'hasMember' should do a fine job."

	^self edgePosition: (self upperEdge: region)!

{XnRegion} simpleUnion: me {XnRegion} with: other {XnRegion}

	(self isEmpty: me) ifTrue: [^self asSimpleRegion: other].
	(self isEmpty: other) ifTrue: [^self asSimpleRegion: me].
	((self isBoundedLeft: me) and: [self isBoundedLeft: other])
		ifTrue: [((self isBoundedRight: me) and: [self isBoundedRight: other])
			ifTrue: [^self makeNew: false with: ((PrimSpec pointer
				arrayWithTwo: ((self lowerEdge: me) floor: (self lowerEdge: other))
				with: ((self upperEdge: me) ceiling: (self upperEdge: other))) cast: PtrArray)]
			ifFalse: [^self makeNew: false with: ((PrimSpec pointer arrayWith: ((self lowerEdge: me) floor: (self lowerEdge: other))) cast: PtrArray)]]
		ifFalse: [((self isBoundedRight: me) and: [self isBoundedRight: other])
			ifTrue: [^self makeNew: true with: ((PrimSpec pointer arrayWith: ((self upperEdge: me) ceiling: (self upperEdge: other))) cast: PtrArray)]
			ifFalse: [^self makeNew: true with: PtrArray empty]]! !

!EdgeManager methodsFor: 'printing'!

{void} printRegionOn: region {XnRegion} with: oo {ostream reference}

	(self isEmpty: region) ifTrue:
		[oo << '{}']
	ifFalse:
		[ | edges {EdgeStepper} previous {TransitionEdge} |
		edges := self edgeStepper: region.
		(self isSimple: region) ifFalse: [oo << '{'].
		edges isEntering ifFalse: [oo << '(-inf'].
		previous := NULL.
		edges forEach: [ :edge {TransitionEdge} |
			edge printTransitionOn: oo
				with: edges isEntering
				with: (previous ~~ NULL and: [previous touches: edge]).
			previous := edge].
		(self isBoundedRight: region) ifFalse: [oo << ' +inf)'].
		(self isSimple: region) ifFalse: [oo << '}']]! !

!EdgeManager methodsFor: 'operations'!

{XnRegion} complement: region {XnRegion}

	^self makeNew: (self startsInside: region) not with: (self transitions: region) with: (self transitionsCount: region)!

{ScruSet of: XnRegion} distinctions: region {XnRegion}

	| result {MuSet} |
	(self isSimple: region) ifFalse:
		[Heaper BLAST: #InvalidRequest].
	(self isEmpty: region) ifTrue:
		[^ImmuSet make with: region].
	(self isFull: region) ifTrue:
		[^ImmuSet make].
	(self transitionsCount: region) = 1 ifTrue:
		[^ImmuSet make with: region].
	result := MuSet make.
	result store: (self makeNew: false with: ((PrimSpec pointer arrayWith: (self lowerEdge: region)) cast: PtrArray)).
	result store: (self makeNew: true with: ((PrimSpec pointer arrayWith: (self upperEdge: region)) cast: PtrArray)).
	^result asImmuSet!

{XnRegion} intersect: meRegion {XnRegion} with: otherRegion {XnRegion}

	| mine {EdgeStepper} others {EdgeStepper} result {EdgeAccumulator} resultReg {XnRegion} |
	(self isEmpty: otherRegion)
		ifTrue: [^otherRegion].
	mine := self edgeStepper: meRegion.
	others := self edgeStepper: otherRegion.
	result := self edgeAccumulator: ((self startsInside: meRegion)
			and: [self startsInside: otherRegion]).
	[mine hasValue and: [others hasValue]] whileTrue:
		[ | me {TransitionEdge} other {TransitionEdge} |
		me := mine getEdge.
		other := others getEdge.
		(me isGE: other) not
			ifTrue:
				[others isEntering not ifTrue: [result edge: me].
				mine step]
			ifFalse:
				[mine isEntering not ifTrue: [result edge: other].
				others step]].
	(mine hasValue and: [others isEntering not]) ifTrue: [result edges: mine].
	(others hasValue and: [mine isEntering not]) ifTrue: [result edges: others].
	mine destroy.
	others destroy.
	resultReg := result region.
	result destroy.
	^ resultReg!

{Stepper} simpleRegions: region {XnRegion} with: order {OrderSpec default: NULL}

	order ~~ NULL ifTrue: 
		[self unimplemented].
	^EdgeSimpleRegionStepper make: self
		with: (self edgeStepper: region)!

{XnRegion} unionWith: meRegion {XnRegion} with: otherRegion {XnRegion}

	| mine {EdgeStepper} others {EdgeStepper} result {EdgeAccumulator} resultReg {XnRegion} |
	(self isEmpty: otherRegion)
		ifTrue: [^meRegion].
	mine := self edgeStepper: meRegion.
	others := self edgeStepper: otherRegion.
	result := self edgeAccumulator: ((self startsInside: meRegion)
			or: [self startsInside: otherRegion]).
	[mine hasValue and: [others hasValue]] whileTrue:
		[ | me {TransitionEdge} other {TransitionEdge} |
		me := mine getEdge.
		other := others getEdge.
		(me isGE: other) not
			ifTrue:
				[others isEntering ifTrue: [result edge: me].
				mine step]
			ifFalse:
				[mine isEntering ifTrue: [result edge: other].
				others step]].
	(mine hasValue and: [others isEntering]) ifTrue: [result edges: mine].
	(others hasValue and: [mine isEntering]) ifTrue: [result edges: others].
	mine destroy.
	others destroy.
	resultReg := result region.
	result destroy.
	^ resultReg!

{XnRegion} with: meRegion {XnRegion} with: newPos {Position}

	| mine {EdgeStepper} others {EdgeStepper} result {EdgeAccumulator} resultReg {XnRegion} |
	mine := self edgeStepper: meRegion.
	others := self singleEdgeStepper: newPos.
	result := self edgeAccumulator: (self startsInside: meRegion).
	[mine hasValue and: [others hasValue]] whileTrue:
		[ | me {TransitionEdge} other {TransitionEdge} |
		me := mine getEdge.
		other := others getEdge.
		(me isGE: other) not
			ifTrue:
				[others isEntering ifTrue: [result edge: me].
				mine step]
			ifFalse:
				[mine isEntering ifTrue: [result edge: other].
				others step]].
	(mine hasValue and: [others isEntering]) ifTrue: [result edges: mine].
	(others hasValue and: [mine isEntering]) ifTrue: [result edges: others].
	mine destroy.
	others destroy.
	resultReg := result region.
	result destroy.
	^ resultReg! !

!EdgeManager methodsFor: 'protected:'!

{Position} edgePosition: edge {TransitionEdge}
	"The position associated with the given edge. Blast if there is none"
	
	self subclassResponsibility!

{XnRegion} makeNew: startsInside {BooleanVar} with: transitions {PtrArray of: TransitionEdge}
	"Make a new region of the right type"
	
	self subclassResponsibility!

{XnRegion} makeNew: startsInside {BooleanVar} with: transitions {PtrArray of: TransitionEdge} with: count {Int32}
	"Make a new region of the right type"
	
	self subclassResponsibility!

{PtrArray of: TransitionEdge} posTransitions: pos {Position}

	self subclassResponsibility!

{BooleanVar} startsInside: region {XnRegion}

	self subclassResponsibility!

{PtrArray of: TransitionEdge} transitions: region {XnRegion}

	self subclassResponsibility!

{Int32} transitionsCount: region {XnRegion}

	self subclassResponsibility! !

!EdgeManager methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !