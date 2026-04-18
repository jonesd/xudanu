'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:16 pm'!

XnRegion subclass: #IntegerRegion
	instanceVariableNames: '
		myStartsInside {BooleanVar}
		myTransitionCount {UInt32}
		myTransitions {IntegerVarArray}'
	classVariableNames: '
		AllIntegers {IntegerRegion} 
		EmptyIntegerRegion {IntegerRegion} 
		LastAfterRegion {IntegerRegion} 
		LastAfterStart {IntegerVar} 
		LastBeforeEnd {IntegerVar} 
		LastBeforeRegion {IntegerRegion} 
		LastInterval {IntegerRegion} 
		LastLeft {IntegerVar} 
		LastRight {IntegerVar} 
		LastSingleton {IntegerVar} 
		LastSingletonRegion {IntegerRegion} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!
IntegerRegion comment:
'An IntegerRegion can be thought of as the disjoint union of intervals and inequalities.  The interesting cases to look at are:
	
	The distinctions:
		1) The empty region
		2) The full region
		3) A "left" inequality -- e.g., everything less that 3.
		4) A "right" inequality -- e.g., everything greater than or equal to 7
		
	The non-distinction simple regions:
		5) An interval -- e.g., from 3 inclusive to 7 exclusive
		
	The non-simple regions:
		6) A disjoint union of (in order) an optional left inequality, a set of 
			intervals, and an optional right inequality.  
		
	If a non-empty region has a least element, then it "isBoundedLeft".  Otherwise it extends leftwards indefinitely.  Similarly, if a non-empty region has a greatest element, then it "isBoundedRight".  Otherwise it extends rightwards indefinitely.  (We may figuratively speak of the region extending towards + or - infinity, but we have purposely avoided introducing any value which represents an infinity.)
	
	Looking at cases again:
		1) "isBoundedLeft" and "isBoundedRight" since it doesn''t extent 
			indenfinitely in either direction.  (A danger to watch out for is that 
			this still has niether a greatest nor a least element).
		2) niether.
		3) "isBoundedRight"
		4) "isBoundedLeft"
		5) "isBoundedLeft" and "isBoundedRight"
		6) "isBoundedLeft" iff doesn''t include a left inequality,
			"isBoundedRight" iff doesn''t include a right inequality.
			
	An efficiency note:  Currently many of the method which could be doing an O(log) binary search (such as hasMember) are instead doing a linear search.  This will be fixed if it turns out to be a problem in practice.
	
	See OrderedRegion.'!

(IntegerRegion getOrMakeCxxClassDescription)
	friends:
'friend class ID;
friend class IntegerMapping;
friend class IntegerSpace;
friend class PointRegion;
friend class SlicePointRegion;
';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!IntegerRegion methodsFor: 'accessing'!

{XnRegion} asSimpleRegion
	"Will always return the smallest simple region which contains all my positions"

	self isSimple ifTrue: [^self].
	self isBoundedBelow
		ifTrue: [self isBoundedAbove
			ifTrue: [^IntegerRegion make: self start with: self stop]
			ifFalse: [^IntegerRegion after: self start]]
		ifFalse: [self isBoundedAbove
			ifTrue: [^IntegerRegion before: self stop]
			ifFalse: [^IntegerRegion allIntegers]]!

{XnRegion} beforeLast
	"the region before the last element of the set.  
	What on earth is this for? (Yes, I've looked at senders)"

	myTransitionCount == Int32Zero ifTrue:
		[^self].
	self isBoundedAbove
		ifTrue: [^IntegerRegion before: self stop]
		ifFalse: [^IntegerRegion allIntegers]!

{XnRegion} compacted
	"transform the region into a simple region with left bound 0 
	(or -inf if unbounded).
	What on earth is this for? (Yes, I've looked at senders)"

	"((IntegerRegion make: 3 with: 7) unionWith: (IntegerRegion before: -10)) compacted"
	self isBoundedBelow
		ifTrue: [self isBoundedAbove
			ifTrue: [^IntegerRegion make: IntegerVar0 with: self count]
			ifFalse: [^IntegerRegion after: IntegerVar0]]
		ifFalse: [self isBoundedAbove
			ifTrue: [^IntegerRegion before: ((myTransitions integerVarAt: Int32Zero)
				+ (self intersect: (IntegerRegion after: (myTransitions integerVarAt: Int32Zero))) count)]
			ifFalse: [^IntegerRegion allIntegers]]!

{Mapping} compactor
	"A mapping to transform the region into a simple region with left bound 0 (or -inf if unbounded). The domain of the mapping is precisely this region.
	This is primarily used in XuText Waldos, which only deal with contiguous zero-based regions of data."

	"((IntegerRegion make: 3 with: 7) unionWith: (IntegerRegion after: 10)) compactor"
	| result {Mapping} end {IntegerVar} index {UInt32} simple {IntegerRegion} sub {Mapping} |
	myTransitionCount == Int32Zero ifTrue: [^IntegerMapping make restrict: self].
	result _ NULL.
	myStartsInside ifTrue:
		[end _ myTransitions integerVarAt: Int32Zero.
		index _ 1]
	ifFalse:
		[end _ IntegerVar0.
		index _ Int32Zero].
	[index < myTransitionCount] whileTrue:
		[simple _ self simpleRegionAtIndex: index.
		sub _ (IntegerMapping make: end - simple start) restrict: simple.
		result == NULL
			ifTrue: [result _ sub]
			ifFalse: [result _ result combine: sub].
		simple isBoundedAbove ifTrue:
			[end _ end + simple count].
		index _ index + 2].
	result ~~ NULL
		ifTrue: [^result restrict: self]
		ifFalse: [^IntegerMapping make restrict: self]!

{CoordinateSpace INLINE} coordinateSpace
	^IntegerSpace make!

{BooleanVar} isCompacted
	"True if this is either empty or a simple region with lower bound of either 0 or -infinity. Equivalent to
		this->compacted()->isEqual (this)"
	
	myStartsInside
		ifTrue: [^myTransitionCount = 1]
		ifFalse: [^myTransitionCount = Int32Zero
			or: [myTransitionCount = 2
				and: [(myTransitions integerVarAt: Int32Zero) = IntegerVar0]]]!

{IntegerVar} nearestIntHole: index {IntegerVar}
	"This is a hack for finding the smallest available index to allocate that is not in a particular region (a table domain, for example)."
	
	| edges {IntegerEdgeStepper} test {BooleanVar} |
	edges _ self edgeStepper.
	[edges hasValue] whileTrue:
		[index < edges edge ifTrue:
			[edges isEntering
				ifTrue: [edges destroy. ^index]
				ifFalse:
					[| result {IntegerVar}|
					result := edges edge.
					edges destroy.
					^ result]].
		edges step].
	test := edges isEntering.
	edges destroy.
	test
		ifTrue: [^index]
		ifFalse: [Heaper BLAST: #NoHole].
	^IntegerVarZero "fodder"!

{IntegerRegion} runAt: pos {IntegerVar} 
	"The region starting from pos (inclusive) and going until the next transition. If I contain pos, then I return the longest contiguous region starting at pos of positions I contain. If I don't contain pos, then I return the longest contiguous region starting at pos of positions I do not contain."

	Int32Zero almostTo: myTransitionCount do: [:i {UInt32} | (myTransitions integerVarAt: i)
			> pos ifTrue: [^IntegerRegion make: pos with: (myTransitions integerVarAt: i)]].
	^IntegerRegion after: pos!

{IntegerVar CLIENT} start
	"I have a start only if I'm not empty and I am isBoundedBelow. I report as my start the smallest position I *do* contain, which is one greater than the largest position I do not contain. The lower bound of the interval from 3 inclusive to 7 exclusive is 3. 
	See 'stop', you may be surprised."

	(myStartsInside or: [myTransitionCount == Int32Zero])
		ifTrue: [Heaper BLAST: #InvalidRequest].
	^myTransitions integerVarAt: Int32Zero!

{IntegerVar CLIENT} stop
	"I have a stop only if I'm not empty and I am isBoundedAbove. I report as my stop the smallest position I *do not* contain, which is one greater than the largest position I do contain.  The ustop of the interval from 3 inclusive to 7 exclusive is 7.
	See 'start', you may be surprised."

	(self isBoundedAbove not or: [myTransitionCount == Int32Zero])
		ifTrue: [Heaper BLAST: #InvalidRequest]. 
	^myTransitions integerVarAt: myTransitionCount - 1! !

!IntegerRegion methodsFor: 'unprotected creation'!

create: startsInside {BooleanVar} with: count {UInt32} with: transitions {IntegerVarArray}
	super create.
	myStartsInside _ startsInside.
	myTransitionCount _ count.
	myTransitions _ transitions.! !

!IntegerRegion methodsFor: 'destroy'!

{void} destroy! !

!IntegerRegion methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	self isEmpty ifTrue:
		[oo << '{}']
	ifFalse:
		[ | edges {IntegerEdgeStepper} between {char star} |
		edges _ self edgeStepper.
		self isSimple ifFalse: [oo << '{'].
		edges isEntering ifFalse: [oo << '(-inf'].
		between _ '['.
		[edges hasValue] whileTrue:
			[edges isEntering ifTrue: [oo << between] ifFalse: [oo << ', '].
			oo << edges edge.
			between _ '), ['.
			edges step].
		edges isEntering ifTrue: [oo << ')'] ifFalse: [oo << ', +inf)'].
		self isSimple ifFalse: [oo << '}'].
		edges destroy]! !

!IntegerRegion methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^(myTransitions elementsHash: myTransitionCount)
		bitXor: ((myStartsInside ifTrue: [9617] ifFalse: [518293])
		bitXor: myTransitionCount * 17)!

{BooleanVar} hasIntMember: key {IntegerVar}
	"Unboxed version.  See class comment for XuInteger"
	
	| edges {IntegerEdgeStepper} result {BooleanVar} |
	edges _ self edgeStepper.
	[edges hasValue] whileTrue:
		[key < edges edge ifTrue:
			[result := edges isEntering not.
			edges destroy.
			^ result].
		edges step].
	result := edges isEntering not.
	edges destroy.
	^ result!

{BooleanVar} hasMember: pos {Position}
	^self hasIntMember: (pos cast: IntegerPos) asIntegerVar!

{BooleanVar} intersects: region {XnRegion}
	| other {IntegerRegion wimpy} |
	other _ region cast: IntegerRegion.
	Int32Zero == myTransitionCount
		ifTrue: [myStartsInside ifTrue: [^other isEmpty not] ifFalse: [^self isEmpty not]]
		ifFalse:
			[Int32Zero == other transitionCount
				ifTrue: [other isBoundedBelow ifTrue: [^other isEmpty not] ifFalse: [^self isEmpty not]]
				ifFalse:
					[| mine {IntegerEdgeStepper} others {IntegerEdgeStepper} pending {IntegerVar} havePending {BooleanVar} index {Int32}
					    startsInside {BooleanVar} |
					mine _ self edgeStepper.
					others _ other edgeStepper.
					havePending _ false.
					index _ Int32Zero.
					[mine hasValue and: [others hasValue]] whileTrue:
						[ | me {IntegerVar} it {IntegerVar} |
						me _ mine edge.
						it _ others edge.
						me < it
							ifTrue:
								[others isEntering not ifTrue:
									[havePending ifTrue:
										[pending = me ifTrue: [havePending _ false]
													    ifFalse: [
													    		mine destroy.
													    		others destroy.
													    		^ true]]
									ifFalse:
										[havePending _ true.
										pending _ me.
										index _ 1]].
								mine step]
							ifFalse:
								[mine isEntering not ifTrue:
									[havePending ifTrue:
										[pending = it ifTrue: [havePending _ false]
													  ifFalse: [
													  	mine destroy.
													  	others destroy.
													  	^ true]]
									ifFalse:
										[havePending _ true.
										pending _ it.
										index _ 1]].
								others step]].

					startsInside _ myStartsInside and: [other isBoundedBelow not].

					(mine hasValue and: [others isEntering not]) ifTrue:
						[havePending ifTrue:
							[pending = mine edge ifTrue: [havePending _ false]
												   ifFalse: [
												   	mine destroy.
												   	others destroy.
												   	^ true]]
						ifFalse:
							[havePending _ true.
							index _ 1].
						havePending ifTrue: [
							mine destroy.
							others destroy.
							^ true].
						mine step.
						mine hasValue ifTrue:
							[mine destroy.
							others destroy.
							^ (index = Int32Zero and: [startsInside]) or: [index ~= Int32Zero]]].

					(others hasValue and: [mine isEntering not]) ifTrue:
						[havePending ifTrue:
							[pending = others edge ifTrue: [havePending _ false]
												     ifFalse: [
												     	mine destroy.
												     	others destroy.
												      ^ true]]
						ifFalse:
							[havePending _ true.
							index _ 1].
						havePending ifTrue: [
							mine destroy.
							others destroy.
							^ true].
						others step.
						others hasValue ifTrue:
							[mine destroy.
							others destroy.
							^ (index = Int32Zero and: [startsInside]) or: [index ~= Int32Zero]]].
					mine destroy.
					others destroy.
					^havePending]]!

{BooleanVar CLIENT} isBoundedAbove
	"Either I extend indefinitely to plus infinity, or I am bounded above, not both. 
	The empty region is bounded above despite the fact that it has no upper edge."

	^((myTransitionCount bitAnd: 1) == Int32Zero) ~~ myStartsInside!

{BooleanVar CLIENT INLINE} isBoundedBelow
	"Either I extend indefinitely to minus infinity, or I am bounded below, not both. 
	The empty region is bounded below despite the fact that it has no lower bound."

	^myStartsInside not!

{BooleanVar} isEmpty

	^myStartsInside not and: [myTransitionCount == Int32Zero]!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: IntegerRegion into: [:ir |
			^ir isBoundedBelow ~~ myStartsInside
			 and: [ir transitionCount = myTransitionCount
			 and: [ir secretTransitions elementsEqual: Int32Zero
			 	with: myTransitions
			 	with: Int32Zero
			 	with: myTransitionCount]]]
		others: [^false].
	^ false "compiler fodder"!

{BooleanVar} isFinite

	^self isBoundedBelow and: [self isBoundedAbove]!

{BooleanVar} isFull	

	^myStartsInside and: [myTransitionCount == Int32Zero]!

{BooleanVar} isSimple
	"Inequalities and intervals are both simple.  See class comment"
	
	myStartsInside ifTrue:
		[^myTransitionCount <= 1]
	ifFalse:
		[^myTransitionCount <= 2]!

{BooleanVar} isSubsetOf: other {XnRegion} 
	other isEmpty
		ifTrue: [ ^ self isEmpty ]
		ifFalse:
			[| mine {IntegerEdgeStepper} others {IntegerEdgeStepper} result {BooleanVar} |
			mine _ self edgeStepper.
			others _ (other cast: IntegerRegion) edgeStepper.
			(mine hasValue or: [others hasValue])
				ifFalse: [
					result := mine isEntering or: [others isEntering not].
					mine destroy.
					others destroy.
					^ result].
			(mine isEntering not and: [others isEntering]) ifTrue: [mine destroy. others destroy. ^false].
			[mine hasValue and: [others hasValue]]
				whileTrue: 
					[others edge < mine edge
						ifTrue: 
							[(others isEntering not and: [mine isEntering not]) ifTrue: [mine destroy. others destroy. ^false].
							others step]
						ifFalse: 
							[others edge > mine edge
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
			^ result]! !

!IntegerRegion methodsFor: 'operations'!

{XnRegion} complement

	^IntegerRegion create: myStartsInside not with: myTransitionCount with: myTransitions!

{XnRegion} intersect: region {XnRegion}
	| other {IntegerRegion wimpy} |
	other _ region cast: IntegerRegion.
	Int32Zero == myTransitionCount
		ifTrue: [myStartsInside ifTrue: [^other] ifFalse: [^self]]
		ifFalse:
			[Int32Zero == other transitionCount
				ifTrue: [other isBoundedBelow ifTrue: [^other] ifFalse: [^self]]
				ifFalse:
					[ | mine {IntegerEdgeStepper} others {IntegerEdgeStepper} result {IntegerEdgeAccumulator} resultReg {XnRegion} |
					mine _ self edgeStepper.
					others _ other edgeStepper.
					result _ IntegerEdgeAccumulator
						make: (myStartsInside and: [other isBoundedBelow not])
						with: (myTransitionCount + other transitionCount).
					[mine hasValue and: [others hasValue]] whileTrue:
						[ | me {IntegerVar} it {IntegerVar} |
						me _ mine edge.
						it _ others edge.
						me < it
							ifTrue:
								[others isEntering not ifTrue: [result edge: me].
								mine step]
							ifFalse:
								[mine isEntering not ifTrue: [result edge: it].
								others step]].
					(mine hasValue and: [others isEntering not]) ifTrue: [result edges: mine].
					(others hasValue and: [mine isEntering not]) ifTrue: [result edges: others].
					mine destroy.
					others destroy.
					resultReg _ result region.
					result destroy.
					^resultReg]]!

{XnRegion} simpleUnion: otherRegion {XnRegion}
	"The result is the smallest simple region which satisfies the spec in XuRegion::simpleUnion"
	
	| other {IntegerRegion wimpy} |
	other _ otherRegion cast: IntegerRegion.
	self isEmpty ifTrue: [^other asSimpleRegion].
	other isEmpty ifTrue: [^self asSimpleRegion].
	(self isBoundedBelow and: [other isBoundedBelow])
		ifTrue: [(self isBoundedAbove and: [other isBoundedAbove])
			ifTrue: [^IntegerRegion make: (self start min: other start)
				with: (self stop max: other stop)]
			ifFalse: [^IntegerRegion after: (self start min: other start)]]
		ifFalse: [(self isBoundedAbove and: [other isBoundedAbove])
			ifTrue: [^IntegerRegion before: (self stop max: other stop)]
			ifFalse: [^IntegerRegion make complement]]!

{XnRegion} unionWith: region {XnRegion}

	region isEmpty
		ifTrue: [ ^ self ]
		ifFalse:
			[| other {IntegerRegion} 
			   mine {IntegerEdgeStepper} 
			   others {IntegerEdgeStepper} 
			   result {IntegerEdgeAccumulator}
			   resultReg {XnRegion} |
			   
			other _ region cast: IntegerRegion.
			mine _ self edgeStepper.
			others _ other edgeStepper.
			result _ IntegerEdgeAccumulator
				make: (myStartsInside or: [other isBoundedBelow not])
				with: myTransitionCount + other transitionCount.
			[mine hasValue and: [others hasValue]] whileTrue:
				[ | me {IntegerVar} him {IntegerVar} |
				me _ mine edge.
				him _ others edge.
				me < him
					ifTrue:
						[others isEntering ifTrue: [result edge: me].
						mine step]
					ifFalse:
						[mine isEntering ifTrue: [result edge: him].
						others step]].
			(mine hasValue and: [others isEntering]) ifTrue: [result edges: mine].
			(others hasValue and: [mine isEntering]) ifTrue: [result edges: others].
			mine destroy.
			others destroy.
			resultReg _ result region.
			result destroy.
			^ resultReg]!

{XnRegion} with: position {Position}

	^ self withInt: (position cast: IntegerPos) asIntegerVar!

{XnRegion} withInt: pos {IntegerVar}

	| mine {IntegerEdgeStepper} me {IntegerVar} result {IntegerEdgeAccumulator} resultReg {XnRegion} |
	self isEmpty ifTrue: [^IntegerRegion make: pos].
	(self isBoundedAbove and: [pos == self stop])
		ifTrue: [
			| newTransitions {IntegerVarArray} |
			newTransitions := myTransitions copy cast: IntegerVarArray.
			newTransitions at: myTransitionCount -1 storeIntegerVar: pos + 1.
			^ IntegerRegion create: myStartsInside with: myTransitionCount with: newTransitions].
	mine _ self edgeStepper.
	result _ IntegerEdgeAccumulator
		make: myStartsInside
		with: myTransitionCount + 2.
	[mine hasValue and: [(me _ mine edge) < pos]] whileTrue:
		[result edge: me.
		mine step].
	mine isEntering 
		ifTrue: 
			[result edge: pos.
			me == pos 
				ifTrue: [mine step]
				ifFalse: [result edge: pos+1]]
		ifFalse:
			[me == pos ifTrue: 
				[mine step.
				result edge: pos+1]].
	mine hasValue ifTrue: [result edges: mine].
	mine destroy.
	resultReg _ result region.
	result destroy.
	^ resultReg! !

!IntegerRegion methodsFor: 'smalltalk: defaults'!

{Stepper CLIENT of: IntegerRegion} intervals
	^self intervals: NULL! !

!IntegerRegion methodsFor: 'enumerating'!

{IntegerVar} count

	| result {IntegerVar} |
	self isFinite ifFalse:
		[Heaper BLAST: #InvalidRequest].
	result _ IntegerVarZero.
	Int32Zero almostTo: myTransitionCount by: 2 do: [ :i {UInt32} |
		result _ result + (myTransitions integerVarAt: i + 1) - (myTransitions integerVarAt: i)].
	^result!

{Stepper INLINE CLIENT of: IntegerRegion} intervals: order {OrderSpec unused default: NULL}
	"Essential. Break this into an ascending sequence of disjoint intervals (which may be unbounded)."
	
	^self simpleRegions!

{BooleanVar} isEnumerable: order {OrderSpec default: NULL}
	"Actually uses the 'order' argument correctly to enumerate the 
	positions. Treats NULL the same as ascending. Iff I am bounded left 
	am I enumerable in ascending order. Similarly, only if I am bounded 
	right am I enumerable in descending order."

	(order == NULL or: [order followsInt: 1 with: IntegerVar0])
		ifTrue: [^self isBoundedBelow]
		ifFalse: [^self isBoundedAbove]!

{BooleanVar CLIENT INLINE} isInterval
	"Whether this Region is a non-empty interval, i.e. if A, B in the Region and A <= C <= B then C is in the Region. This includes inequalities (e.g. {x | x > 5}) and the fullRegion in addition to ordinary two-ended intervals."
	
	^self isSimple! !

!IntegerRegion methodsFor: 'breaking up'!

{ScruSet of: XnRegion} distinctions

	| intReg {IntegerRegion} |
	self isSimple ifFalse:
		[Heaper BLAST: #InvalidRequest].
	self isFull ifTrue:
		[^ImmuSet make].
	(self isEmpty or: [myTransitionCount = 1]) ifTrue:
		[^ImmuSet make with: self].
	intReg _ IntegerRegion create: myStartsInside with: 1 with: myTransitions.
	^(ImmuSet make with: intReg)
		with: (IntegerRegion before: self stop)!

{Stepper} simpleRegions: order {OrderSpec default: NULL} 
	"Treats NULL the same as ascending. For the moment, will only work 
	with an ascending OrderSpec. If a descending OrderSpec is provided, 
	it will currently BLAST, but later will work correctly.
	
	Returns a stepper on a disjoint set of simple regions in ascending 
	order.  No difference with disjointSimpleRegions"

	(order == NULL or: [order followsInt: 1 with: Int32Zero])
		ifFalse: [self unimplemented].
	myTransitionCount == Int32Zero ifTrue: [myStartsInside
			ifTrue: [^Stepper itemStepper: self]
			ifFalse: [^Stepper emptyStepper]].
	^IntegerSimpleRegionStepper
		create: myTransitions
		with: myTransitionCount
		with: myStartsInside not! !

!IntegerRegion methodsFor: 'private:'!

{IntegerVarArray INLINE} secretTransitions
	"The actuall array. DO NOT MODIFY"
	
	^myTransitions!

{IntegerRegion} simpleRegionAtIndex: i {UInt32}
	"the simple region at the given index in the transition array"
	(i < myTransitionCount) assert.
	((i bitAnd: 1) = Int32Zero) == myStartsInside ifTrue:
		[^IntegerRegion before: (myTransitions integerVarAt: i)]
	ifFalse: [i + 1 < myTransitionCount ifTrue:
		[^IntegerRegion make: (myTransitions integerVarAt: i) with: (myTransitions integerVarAt: i + 1)]
	ifFalse:
		[^IntegerRegion after: (myTransitions integerVarAt: i)]]! !

!IntegerRegion methodsFor: 'private: has friends'!

{IntegerEdgeStepper} edgeStepper
	"Do not send from outside the module. This should not be exported 
	outside the module, but to not export it in this case is some trouble."

	^IntegerEdgeStepper
		make: myStartsInside not
		with: myTransitionCount
		with: myTransitions!

{UInt32 INLINE} transitionCount
	"Do not send from outside the module. This should not be exported 
	outside the module, but to not export it in this case is some trouble. 
	It is used for an efficiency hack in PointRegion."

	^myTransitionCount! !

!IntegerRegion methodsFor: 'smalltalk: passe'!

{Position} chooseOne: order {OrderSpec | NULL}

	^((order == NULL or: [order followsInt: 1 with: 0]) ifTrue: [self start]
		ifFalse: [self stop-1]) integer!

{BooleanVar} startsInside
	self passe! !

!IntegerRegion methodsFor: 'protected: enumerating'!

{Stepper} actualStepper: order {OrderSpec default: NULL} 
	"Iff I am bounded left am I enumerable in ascending order. Similarly, only if I am bounded right am I enumerable in descending order."

	(order followsInt: 1 with: IntegerVar0) ifTrue: 
		[^AscendingIntegerStepper make: myTransitions with: myTransitionCount]
	ifFalse: 
		[^DescendingIntegerStepper make: myTransitions with: myTransitionCount]! !

!IntegerRegion methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myStartsInside _ receiver receiveBooleanVar.
	myTransitionCount _ receiver receiveUInt32.
	myTransitions _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendBooleanVar: myStartsInside.
	xmtr sendUInt32: myTransitionCount.
	xmtr sendHeaper: myTransitions.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerRegion class
	instanceVariableNames: ''!

(IntegerRegion getOrMakeCxxClassDescription)
	friends:
'friend class ID;
friend class IntegerMapping;
friend class IntegerSpace;
friend class PointRegion;
friend class SlicePointRegion;
';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!IntegerRegion class methodsFor: 'pseudo constructors'!

{IntegerRegion} above: start {IntegerVar} with: inclusive {BooleanVar}
	"Essential. Make a region that contains all integers greater than (or equal if inclusive is true) to start."
	| after {IntegerVar} |
	after _ start.
	inclusive ifFalse: [after _ after + 1].
	^IntegerRegion after: after!

{IntegerRegion} after: start {IntegerVar}
	"The region containing all position greater than or equal to start"

	| table {IntegerVarArray} tir {IntegerRegion} |
	LastAfterStart = start ifTrue:
		[^LastAfterRegion].
	LastAfterStart _ start.
	table _ IntegerVarArray zeros: 1.
	table at: Int32Zero storeIntegerVar: start.
	"temp used to get around static member problem in INIT macro - heh 10 January 1992"
	tir _ IntegerRegion create: false with: 1 with: table.
	LastAfterRegion _ tir.
	^LastAfterRegion.!

{IntegerRegion INLINE} allIntegers
	"The full region of this space"
	
	^AllIntegers!

{IntegerRegion} before: end {IntegerVar}
	"The region of all integers less than end.  Does not include end."
	
	| table {IntegerVarArray} tir {IntegerRegion} |
	LastBeforeEnd = end ifTrue:
		[^LastBeforeRegion].
	LastBeforeEnd _ end.
	table _ IntegerVarArray zeros: 1.
	table at: Int32Zero storeIntegerVar: end.
	"temp used to get around problem with static members & INIT macro - heh 10 January 1992"
	tir _ IntegerRegion create: true with: 1 with: table.
	LastBeforeRegion _ tir.
	^LastBeforeRegion!

{IntegerRegion} below: stop {IntegerVar} with: inclusive {BooleanVar}
	"Make a region that contains all integers less than (or equal if inclusive is true) to stop."
	| after {IntegerVar} |
	after _ stop.
	inclusive ifTrue: [after _ after + 1].
	^IntegerRegion after: after!

{IntegerRegion} integerExtent: start {IntegerVar} with: n {IntegerVar}
	"The region of all integers which are >= start and < start + n"
	
	^self make: start with: start + n!

{IntegerRegion} interval: left {IntegerVar} with: right {IntegerVar}
	"The region of all integers which are >= left and < right"
	
	| ivArray {IntegerVarArray} |
	left >= right ifTrue: [^EmptyIntegerRegion].
	ivArray _ IntegerVarArray zeros: 2.
	ivArray at: Int32Zero storeIntegerVar: left.
	ivArray at: 1 storeIntegerVar: right.
	^IntegerRegion create: false with: 2 with: ivArray!

{IntegerRegion INLINE} make
	"No integers, the empty region"
	
	^EmptyIntegerRegion!

make: singleton {IntegerVar}
	"The region with just this one position.  Equivalent to using a converter 
	to convert this position to a region."
	
	| table {IntegerVarArray} tir {IntegerRegion} |
	singleton = LastSingleton ifTrue:
		[^LastSingletonRegion].
	LastSingleton _ singleton.
	table _ IntegerVarArray zeros: 2.
	table at: Int32Zero storeIntegerVar: singleton.
	table at: 1 storeIntegerVar: singleton + 1.
	"temp used to get around problem with static members and INIT macro - heh 10 January 1992"
	tir _ IntegerRegion create: false with: 2 with: table.
	LastSingletonRegion _ tir.
	^LastSingletonRegion!

make: left {IntegerVar} with: right {IntegerVar}
	"The region of all integers which are >= left and < right"
	
	| ivArray {IntegerVarArray} |
	left >= right ifTrue: [^EmptyIntegerRegion].
	ivArray _ IntegerVarArray zeros: 2.
	ivArray at: Int32Zero storeIntegerVar: left.
	ivArray at: 1 storeIntegerVar: right.
	^IntegerRegion create: false with: 2 with: ivArray! !

!IntegerRegion class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	| empty {IntegerVarArray} tir {IntegerRegion} |
	self REQUIRES: IntegerVarArray.
	empty _ IntegerVarArray zeros: 1.
	
	"temp used to get around problem with static members and INIT macro - heh 10 January 1992"
	tir _ IntegerRegion create: true with: Int32Zero with: empty.
	AllIntegers _ tir.
	tir _ IntegerRegion create: false with: Int32Zero with: empty.
	EmptyIntegerRegion _ tir.
	"call the pseudo constructors with arguments that are known to flush the caches"
	IntegerRegion after: IntegerVar0.
	IntegerRegion before: IntegerVar0.
	IntegerRegion make: IntegerVar0.
	IntegerRegion make: IntegerVar0 with: 2!

linkTimeNonInherited
	AllIntegers _ NULL.
	EmptyIntegerRegion _ NULL.
	LastAfterRegion _ NULL.
	LastAfterStart _ 13.
	LastBeforeEnd _ 13.
	LastBeforeRegion _ NULL.
	LastInterval _ NULL.
	LastLeft _ 13.
	LastRight _ 13.
	LastSingleton _ 13.
	LastSingletonRegion _ NULL.! !

!IntegerRegion class methodsFor: 'privacy violator'!

{IntegerVarArray INLINE} badlyViolatePrivacyOfIntegerRegionTransitions: reg {IntegerRegion} 
	"used for an efficiency hack in PointRegion.  Don't use."
	^reg secretTransitions! !

!IntegerRegion class methodsFor: 'private: pseudo constructors'!

{IntegerRegion} using: startsInside {BooleanVar}
	with: transitionCount {Int32}
	with: transitions {IntegerVarArray}

	^self create: startsInside with: transitionCount with: transitions! !

!IntegerRegion class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Stepper CLIENT of: RealRegion} intervals: order {OrderSpec default: NULL}
{BooleanVar CLIENT} isBoundedAbove
{BooleanVar CLIENT} isBoundedBelow
{BooleanVar CLIENT} isInterval
{IntegerVar CLIENT} start
{IntegerVar CLIENT} stop
"! !