'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:09 pm'!

XnRegion subclass: #Filter
	instanceVariableNames: 'myCS {FilterSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!
Filter comment:
'A position in a FilterSpace is a region in the baseSpace, and a filter is a set of regions in the baseSpace. It is often more useful to think of a Filter as a Boolean function whose input is a region in the baseSpace, and of unions, intersections, and complements of filters as ORs, ANDs, and NOTs of functions. Not all possible such functions can be represented as Filters, since there is an uncountable infinity of them for any non-finite CoordinateSpace. There are representations for some basic filters, and any filters resulting from a finite sequence of unions, intersections, and complements among them. The basic filters are:
	subsetFilter(cs,R) -- all subsets of R (i.e. all R1 such that R1->isSubsetOf(R))
	supersetFilter(cs,R) -- all supersets of R (i.e. all R1 such that R->isSubsetOf(R1))
Mathematically, this is all that is necessary, since other useful filters like intersection filters can be generated from these. (e.g. intersectionFilter(R) is subsetFilter(R->complement())->complement()). However, there are several more pseudo constructors provided as shortcuts, including intersectionFilters, closedFilters, emptyFilters, and intersections and unions of sets of filters.'!

(Filter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #COPY; yourself)!

!Filter methodsFor: 'operations'!

{XnRegion} complement
	
	self subclassResponsibility!

{XnRegion} intersect: other {XnRegion}

	| result {XnRegion} |
	result := self fetchIntersect: other.
	result ~~ NULL ifTrue: [^result].
	^self complexIntersect: other!

{XnRegion INLINE} simpleUnion: other {XnRegion}

	^self unionWith: other!

{XnRegion} unionWith: other {XnRegion}

	| result {XnRegion} |
	result := self fetchUnion: other.
	result ~~ NULL ifTrue: [^result].
	^self complexUnion: other! !

!Filter methodsFor: 'testing'!

{UInt32} actualHashForEqual

	self subclassResponsibility!

{BooleanVar} hasMember: pos {Position}

	^self match: (pos cast: FilterPosition) baseRegion!

{BooleanVar CLIENT} isAllFilter
	"Essential. Whether this is an 'all' Filter, i.e. it only matches Regions which contain everything in the baseRegion"
	
	self subclassResponsibility!

{BooleanVar CLIENT} isAnyFilter
	"Essential. Whether this is an 'any' Filter, i.e. it matches Regions which contain anything in the baseRegion"
	
	self subclassResponsibility!

{BooleanVar} isEmpty

	self subclassResponsibility!

{BooleanVar} isEnumerable: order {OrderSpec default: NULL}
	
	self knownBug. "The singleton region should act enumerably"
	^false!

{BooleanVar} isEqual: other {Heaper}

	self subclassResponsibility!

{BooleanVar INLINE} isFinite

	^false!

{BooleanVar} isFull	

	self subclassResponsibility!

{BooleanVar INLINE} isSimple
	^true!

{BooleanVar} isSubsetOf: other {XnRegion}
	| o {Filter} |
	o _ other cast: Filter.
	(self fetchSpecialSubset: o) == self ifTrue: [^true].
	(o fetchSpecialSubset: self) == self ifTrue: [^true].
	^(self intersects: (o complement)) not! !

!Filter methodsFor: 'enumerating'!

{IntegerVar} count
	self unimplemented.
	^IntegerVar0!

{Stepper CLIENT of: Filter} intersectedFilters
	"Essential. Break this up into a bunch of Filters which when intersected (anded) together give this one. If there is only one sub Filter it will be the receiver; otherwise, the sub Filters will be simple enough that either they or their complements will return true from at least one of isAndFilter or isOrFilter. If this is full (i.e. an open filter) then the stepper will have no elements."
	
	self subclassResponsibility!

{Stepper CLIENT of: Filter} unionedFilters
	"Essential. Break this up into a bunch of Filters which when unioned (ored) together give this one. If there is only one sub Filter it will be the receiver; otherwise, the sub Filters will be simple enough that either they or their complements will return true from at least one of isAndFilter or isOrFilter. The sub Filters might not be disjoint Regions. If this is empty (i.e. a closed filter) then the stepper will have no elements."
	
	self subclassResponsibility! !

!Filter methodsFor: 'accessing'!

{XnRegion INLINE} asSimpleRegion

	^self!

{XnRegion CLIENT} baseRegion
	"Essential. A region in the base space identifying what kind of filter this is. Succeeds only if this isAnyFilter or isAllFilter."
	
	self subclassResponsibility!

{CoordinateSpace INLINE} coordinateSpace

	^myCS!

{XnRegion} relevantRegion
	"The region which is relevant to this filter, i.e. whose presence or absence in a region can change whether it passes the filter"
	
	self subclassResponsibility! !

!Filter methodsFor: 'filtering'!

{BooleanVar} doesPass: joint {Joint}
	"Whether there might be anything in the tree beneath the Joint that would pass the filter."

	^(self pass: joint) isEmpty not!

{BooleanVar} isSwitchedBy: delta {RegionDelta}
	"Whether the change causes a change in the state of the filter. (I.E. Whether the old region was in and the new out, or vice versa.)"
	
	^(self match: delta before) ~~ (self match: delta after)!

{BooleanVar} isSwitchedOffBy: delta {RegionDelta}
	"Whether the change switches the state of the filter from on to off. (I.E. Whether the old region was inside the filter and the new region outside.)"
	
	^(self match: delta before) and: [(self match: delta after) not]!

{BooleanVar} isSwitchedOnBy: delta {RegionDelta}
	"Whether the change switches the state of the filter from off to on. (I.E. Whether the old region was outside the filter and the new region inside.)"
	
	^(self match: delta before) not and: [self match: delta after]!

{BooleanVar CLIENT} match: region {XnRegion}
	"Whether a region is inside this filter."
	
	self subclassResponsibility!

{Filter} pass: parent {Joint}
	"The simplest filter for looking at the tree beneath the node.
	The Joint keeps the intersection and union of all the nodes beneath it, so the result of this message can be used to prune a search. If the result is full, then everything beneath the node is in the filter (e.g. if this filter contained all subsets of S and the union was a superset of S). If the result is empty, then nothing beneath the node is in the filter (e.g. if this filter contained all subsets of S and the intersection was not a subset of S). In less extreme cases, this operation may at least simplify the filter by throwing out irrelevant search criteria."
	
	self subclassResponsibility! !

!Filter methodsFor: 'creation'!

create: cs {FilterSpace}
	super create.
	myCS _ cs! !

!Filter methodsFor: 'components'!

{ScruSet of: XnRegion} distinctions

	self isFull
		ifTrue: [^ImmuSet make]
		ifFalse: [^ImmuSet make with: self]!

{Stepper} simpleRegions: order {OrderSpec unused default: NULL}

	self isEmpty
		ifTrue: [^ImmuSet make stepper]
		ifFalse: [^(ImmuSet make with: self) stepper]! !

!Filter methodsFor: 'vulnerable: internal'!

{XnRegion} complexIntersect: other {XnRegion}
	| a {Filter} b {Filter} canon {Pair of: Filter} |
	(self isKindOf: OrFilter)
		ifTrue: [a _ self. b _ other cast: Filter]
		ifFalse: [b _ self. a _ other cast: Filter].
	(a isKindOf: OrFilter) ifTrue:
		[(b isKindOf: OrFilter)
			ifTrue: [^Filter orFilterPrivate: myCS
				with: (Filter distributeIntersect: self coordinateSpace
					with: (a cast: OrFilter) subFilters
					with.ImmuSet: (b cast: OrFilter) subFilters)]
			ifFalse: [^Filter orFilterPrivate: myCS
				with: (Filter distributeIntersect: self coordinateSpace
					with: (a cast: OrFilter) subFilters
					with.Filter: b)]].
	(a isKindOf: AndFilter)
		ifFalse: [ | t {Filter} | t _ a. a _ b. b _ t].
	(a isKindOf: AndFilter) ifTrue:
		[(b isKindOf: AndFilter)
			ifTrue: [^Filter andFilterPrivate: myCS
				with: (Filter combineIntersect: (a cast: AndFilter) subFilters
					with.ImmuSet:  (b cast: AndFilter) subFilters)].
		^Filter andFilterPrivate: myCS
				with: (Filter combineIntersect: (a cast: AndFilter) subFilters
					with.Filter:  b)].
	canon _ self getPairIntersect: (other cast: Filter).
	^Filter andFilterPrivate: myCS
			with: ((ImmuSet make with: canon left) with: canon right)!

{XnRegion} complexUnion: other {XnRegion}
	| a {Filter} b {Filter} canon {Pair of: Filter} |
	(self isKindOf: OrFilter)
		ifTrue: [a _ self. b _ other cast: Filter]
		ifFalse: [b _ self. a _ other cast: Filter].
	(a isKindOf: OrFilter) ifTrue:
		[(b isKindOf: OrFilter)
			ifTrue: [^Filter orFilterPrivate: myCS
				with: (Filter combineUnion: (a cast: OrFilter) subFilters
					with.ImmuSet:  (b cast: OrFilter) subFilters)].
		(b isKindOf: AndFilter)
			ifTrue: [^Filter orFilterPrivate: myCS
				with: (Filter distributeUnion: self coordinateSpace
					with: (b cast: AndFilter) subFilters
					with.ImmuSet:  (a cast: OrFilter) subFilters)].
		^Filter orFilterPrivate: myCS
				with: (Filter combineUnion: (a cast: OrFilter) subFilters
					with.Filter:  b)].
	(a isKindOf: AndFilter) ifFalse:
		[ | t {Filter} | t _ a. a _ b. b _ t].
	(a isKindOf: AndFilter) ifTrue:
		[^Filter orFilterPrivate: myCS
			with: (Filter distributeUnion: self coordinateSpace
				with: (a cast: AndFilter) subFilters
				with.Filter: b)].
	canon _ self getPairUnion: (other cast: Filter).
	^Filter orFilterPrivate: myCS
		with: ((ImmuSet make with: canon left) with: canon right)!

{Pair of: Filter} fetchCanonicalIntersect: other {Filter unused}
	"return NULL, or the pair of canonical filters (left == new1 | self, right == new2 | other)"
	^NULL!

{Pair of: Filter} fetchCanonicalUnion: other {Filter unused}
	"return NULL, or the pair of canonical filters (left == new1 | self, right == new2 | other)"
	^NULL!

{XnRegion} fetchIntersect: other {XnRegion}
	| temp {XnRegion} |
	temp _ self fetchSpecialSubset: other.
	temp == NULL ifTrue:
		[temp _ (other cast: Filter) fetchSpecialSubset: self].
	temp == self ifTrue: [^self].
	(temp basicCast: Heaper star) == other ifTrue: [^other].
	temp _ self fetchSpecialIntersect: other.
	temp ~~ NULL ifTrue: [^temp].
	^(other cast: Filter) fetchSpecialIntersect: self!

{Pair of: Filter} fetchPairIntersect: other {Filter}
	"return the pair of canonical filters (left == new1 | self, right == new2 | other)"
	| result {Pair of: Filter} |
	result _ self fetchCanonicalIntersect: other.
	result ~~ NULL ifTrue: [^result].
	result _ other fetchCanonicalIntersect: self.
	result ~~ NULL ifTrue: [^result reversed].
	^NULL!

{Pair of: Filter} fetchPairUnion: other {Filter}
	"return the pair of canonical filters (left == new1 | self, right == new2 | other)"
	| result {Pair of: Filter} |
	result _ self fetchCanonicalUnion: other.
	result ~~ NULL ifTrue: [^result].
	result _ other fetchCanonicalUnion: self.
	result ~~ NULL ifTrue: [^result reversed].
	^NULL!

{XnRegion} fetchSpecialIntersect: other {XnRegion unused}
	^NULL!

{XnRegion} fetchSpecialSubset: other {XnRegion}
	"return self or other if one is clearly a subset of the other, else NULL"
	self subclassResponsibility!

{XnRegion} fetchSpecialUnion: other {XnRegion unused}
	^NULL!

{XnRegion} fetchUnion: other {XnRegion}
	| temp {XnRegion} |
	temp _ self fetchSpecialSubset: other.
	temp == NULL ifTrue:
		[temp _ (other cast: Filter) fetchSpecialSubset: self].
	temp == self ifTrue: [^other].
	(temp basicCast: Heaper star) == other ifTrue: [^self].
	temp _ self fetchSpecialUnion: other.
	temp ~~ NULL ifTrue: [^temp].
	^(other cast: Filter) fetchSpecialUnion: self!

{Pair of: Filter} getPairIntersect: other {Filter}
	"return the pair of canonical filters (left == new1 | self, right == new2 | other)"
	| result {Pair of: Filter} |
	result _ self fetchCanonicalIntersect: other.
	result ~~ NULL ifTrue: [^result].
	result _ other fetchCanonicalIntersect: self.
	result ~~ NULL ifTrue: [^result reversed].
	^Pair make: self with: other!

{Pair of: Filter} getPairUnion: other {Filter}
	"return the pair of canonical filters (left == new1 | self, right == new2 | other)"
	| result {Pair of: Filter} |
	result _ self fetchCanonicalUnion: other.
	result ~~ NULL ifTrue: [^result].
	result _ other fetchCanonicalUnion: self.
	result ~~ NULL ifTrue: [^result reversed].
	^Pair make: self with: other! !

!Filter methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 
	
	Ravi shouldImplement.
	^NULL "fodder"! !

!Filter methodsFor: 'protected:'!

{FilterSpace INLINE} filterSpace

	^myCS! !

!Filter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCS _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCS.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Filter class
	instanceVariableNames: ''!

(Filter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #COPY; yourself)!

!Filter class methodsFor: 'pseudo constructors'!

{Filter} andFilter: cs {CoordinateSpace} with: subs {ScruSet of: Filter}
	"A filter that matches only regions that all of the filters in the set would have matched."
	
	| result {ImmuSet} |
	result _ ImmuSet make.
	subs stepper forEach: [ :sub {Filter} |
		sub
			cast: ClosedFilter into: [:cSub |
				^Filter closedFilter: cs]
			cast: AndFilter into: [:aSub |
				result _ self combineIntersect: result
					with.ImmuSet: aSub subFilters]
			cast: OpenFilter into: [:oSub | ]
			others:
				[result _ self combineIntersect: result
					with.Filter: sub]].
	^Filter andFilterPrivate: (cs cast: FilterSpace) with: result!

{Filter} closedFilter: cs {CoordinateSpace}
	"An filter that does match any region."
	
	^ClosedFilter create: (cs cast: FilterSpace)!

{Filter} intersectionFilter: cs {CoordinateSpace} with: region {XnRegion}
	"A filter that matches any region that intersects the given region."
	
	^NotSubsetFilter create: (cs cast: FilterSpace) with: region complement!

{Filter} notSubsetFilter: cs {CoordinateSpace} with: region {XnRegion}
	"A filter matching any regions that is not a subset of the given region."
	
	region isFull ifTrue: [^Filter closedFilter: cs].
	^NotSubsetFilter create: (cs cast: FilterSpace) with: region!

{Filter} notSupersetFilter: cs {CoordinateSpace} with: region {XnRegion}
	"A filter that matches any region that is not a superset of the given region."
	
	region isEmpty ifTrue: [^Filter closedFilter: cs].
	^NotSupersetFilter create: (cs cast: FilterSpace) with: region!

{Filter} openFilter: cs {CoordinateSpace}
	"A filter that matches any region."
	
	^OpenFilter create: (cs cast: FilterSpace)!

{Filter} orFilter: cs {CoordinateSpace} with: subs {ScruSet of: Filter}
	"A filter that matches any region that any of the filters in the set would have matched."
	
	| result {ImmuSet of: Filter} |
	result _ ImmuSet make.
	subs stepper forEach: [ :sub {Filter} |
		sub
			cast: OpenFilter into: [:oSub |
				^Filter openFilter: cs]
			cast: OrFilter into: [:orSub |
				result _ self combineUnion: result
					with.ImmuSet: orSub subFilters]
			cast: ClosedFilter into: [:cSub | ]
			others:
				[result _ self combineUnion: result
					with.Filter: sub]].
	^Filter orFilterPrivate: (cs cast: FilterSpace) with: result!

{Filter} subsetFilter: cs {CoordinateSpace} with: region {XnRegion}
	"A filter that matches any region that is a subset of the given region."
	
	region isFull ifTrue: [^Filter openFilter: cs].
	^SubsetFilter create: (cs cast: FilterSpace) with: region!

{Filter} supersetFilter: cs {CoordinateSpace} with: region {XnRegion}
	"A region that matches any region that is a superset of the given region."
	
	region isEmpty ifTrue: [^Filter openFilter: cs].
	^SupersetFilter create: (cs cast: FilterSpace) with: region! !

!Filter class methodsFor: 'private: functions'!

{Filter} andFilterPrivate: cs {FilterSpace} with: subs {ImmuSet of: Filter}
	"assumes that the interactions between elements have already been removed"
	subs isEmpty ifTrue: [^Filter openFilter: cs].
	subs count = 1 ifTrue: [^subs theOne cast: Filter].
	^AndFilter create: cs with: subs!

{ImmuSet of: Filter} combineIntersect: set {ImmuSet of: Filter} with.Filter: filter {Filter}
	"keep going around doing intersections until there are no more special intersects"
	| subs {Stepper} nonspecial {MuSet of: Filter} result {SetAccumulator} test {Filter} |
	result _ SetAccumulator make.
	test _ filter.
	subs _ set stepper.
	nonspecial _ set asMuSet.
	[subs hasValue] whileTrue:
		[ | special {Filter} sub {Filter} |
		sub _ (subs fetch cast: Filter).
		subs step.
		special _ (sub fetchIntersect: test) cast: Filter.
		special ~~ NULL ifTrue:
			[test _ special.
			result _ SetAccumulator make.
			nonspecial remove: sub.
			subs _ nonspecial stepper]
		ifFalse:
			[ | canon {Pair of: Filter} |
			canon _ sub fetchPairIntersect: test.
			canon == NULL ifTrue:
				[result step: sub]
			ifFalse:
				[test _ canon right cast: Filter.
				nonspecial remove: sub.
				result _ SetAccumulator make.
				nonspecial _ (Filter combineIntersect: nonspecial asImmuSet
					with.Filter: (canon left cast: Filter)) asMuSet.
				subs _ nonspecial stepper]]].
	^(result value cast: ImmuSet) with: test!

{ImmuSet of: Filter} combineIntersect: a {ImmuSet of: Filter} with.ImmuSet: b {ImmuSet of: Filter}
	| result {ImmuSet of: Filter} |
	result _ a.
	b stepper forEach: [ :sub {Filter} |
		result _ self combineIntersect: result with.Filter: sub].
	^result!

{ImmuSet of: Filter} combineUnion: set {ImmuSet of: Filter} with.Filter: filter {Filter}
	"keep going around doing unions until there are no more special unions"
	| subs {Stepper} nonspecial {MuSet of: Filter} result {SetAccumulator} test {Filter} |
	result _ SetAccumulator make.
	test _ filter.
	subs _ set stepper.
	nonspecial _ set asMuSet.
	[subs hasValue] whileTrue:
		[ | special {Filter} sub {Filter} |
		sub _ (subs fetch cast: Filter).
		subs step.
		special _ (sub fetchUnion: test) cast: Filter.
		special ~~ NULL ifTrue:
			[test _ special.
			result _ SetAccumulator make.
			nonspecial remove: sub.
			subs _ nonspecial stepper]
		ifFalse:
			[ | canon {Pair of: Filter} |
			canon _ sub fetchPairUnion: test.
			canon == NULL ifTrue:
				[result step: sub]
			ifFalse:
				[test _ canon right cast: Filter.
				nonspecial remove: sub.
				result _ SetAccumulator make.
				nonspecial _ (Filter combineUnion: nonspecial asImmuSet
					with.Filter: (canon left cast: Filter)) asMuSet.
				subs _ nonspecial stepper]]].
	^(result value cast: ImmuSet) with: test!

{ImmuSet of: Filter} combineUnion: a {ImmuSet of: Filter} with.ImmuSet: b {ImmuSet of: Filter}
	| result {ImmuSet of: Filter} |
	result _ a.
	b stepper forEach: [ :sub {Filter} |
		result _ self combineUnion: result with.Filter: sub].
	^result!

{ImmuSet of: Filter} distributeIntersect: cs {CoordinateSpace} with: set {ImmuSet of: Filter} with.Filter: filter {Filter}
	"distribute the intersection of a filter with the union of a set of filters"
	| special {Filter} nonspecial {SetAccumulator of: Filter} |
	special _ Filter closedFilter: cs.
	nonspecial _ SetAccumulator make.
	set stepper forEach: [ :sub {Filter} | | quick {XnRegion} |
		quick _ sub fetchIntersect: filter.
		quick == NULL
			ifTrue: [nonspecial step: (sub complexIntersect: filter)]
			ifFalse: [special _ (special unionWith: quick) cast: Filter]].
	(nonspecial value cast: ImmuSet) isEmpty
		ifTrue: [^ImmuSet make with: special]
		ifFalse: [^(nonspecial value cast: ImmuSet) with: special]!

{ImmuSet of: Filter} distributeIntersect: cs {CoordinateSpace} 
	with: a {ImmuSet of: Filter} 
	with.ImmuSet: b {ImmuSet of: Filter}
	"distribute the intersection of two unions of sets of filters"
	| special {Filter} nonspecial {ImmuSet of: Filter} |
	special _ Filter closedFilter: cs.
	nonspecial _ ImmuSet make.
	a stepper forEach: [ :other {Filter} |
		b stepper forEach: [ :sub {Filter} | | intersection {XnRegion} |
			intersection _ sub fetchIntersect: other.
			intersection == NULL
				ifTrue: [nonspecial _ Filter combineUnion: nonspecial
					with.Filter: ((sub complexIntersect: other) cast: Filter)]
				ifFalse: [special _ (special unionWith: intersection) cast: Filter]]].
	^Filter combineUnion: nonspecial with.Filter: special!

{ImmuSet of: Filter} distributeUnion: cs {CoordinateSpace} with: set {ImmuSet of: Filter} with.Filter: filter {Filter}
	"distribute the union of a filter with the intersection of a set of filters"
	| special {Filter} nonspecial {ImmuSet of: Filter} |
	special _ Filter openFilter: cs.
	nonspecial _ ImmuSet make.
	set stepper forEach: [ :sub {Filter} | | quick {XnRegion} |
		quick _ sub fetchUnion: filter.
		quick == NULL
			ifTrue: [nonspecial _ Filter combineIntersect: nonspecial with.Filter: sub]
			ifFalse: [special _ (special intersect: quick) cast: Filter]].
	nonspecial isEmpty
		ifTrue: [^ImmuSet make with: special]
		ifFalse: [^(ImmuSet make
			with: (Filter andFilterPrivate: (cs cast: FilterSpace)
				with: (Filter combineIntersect: nonspecial with.Filter: special)))
			with: filter]!

{ImmuSet of: Filter} distributeUnion: cs {CoordinateSpace} with: anded {ImmuSet of: Filter} with.ImmuSet: ored {ImmuSet of: Filter}
	"distribute the union of an intersection and a union of sets of filters"
	| distributed {Filter} |
	distributed _ ored theOne cast: Filter.
	^self combineUnion: (self distributeUnion: cs with: anded with.Filter: distributed)
		with.ImmuSet: (ored without: distributed)!

{Filter} orFilterPrivate: cs {FilterSpace} with: subs {ImmuSet of: Filter}
	"assumes that the interactions between elements have already been removed"
	subs isEmpty ifTrue: [^Filter closedFilter: cs].
	subs count = 1 ifTrue: [^subs theOne cast: Filter].
	^OrFilter create: cs with: subs! !

!Filter class methodsFor: 'smalltalk: system'!

info.stProtocol
"{XnRegion CLIENT} baseRegion
{Stepper CLIENT of: Filter} intersectedFilters
{BooleanVar CLIENT} isAllFilter
{BooleanVar CLIENT} isAnyFilter
{BooleanVar CLIENT} match: region {XnRegion}
{Stepper CLIENT of: Filter} unionedFilters
"! !