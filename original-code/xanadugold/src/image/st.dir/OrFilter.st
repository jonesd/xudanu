'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:15 pm'!

Filter subclass: #OrFilter
	instanceVariableNames: 'mySubFilters {ImmuSet of: Filter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!

(OrFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!OrFilter methodsFor: 'creation'!

create: cs {FilterSpace} with: subs {ImmuSet of: Filter}
	super create: cs.
	mySubFilters _ subs! !

!OrFilter methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^(self coordinateSpace hashForEqual bitXor: mySubFilters hashForEqual)
		bitXor: #cat.U.OrFilter hashForEqual!

{BooleanVar} isAllFilter

	^false!

{BooleanVar} isAnyFilter
	
	^false!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: OrFilter into: [:of |
			^of subFilters isEqual: self subFilters]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFull	

	^false! !

!OrFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name.
	self subFilters printOnWithSimpleSyntax: oo with: '(' with: ' || ' with: ')'! !

!OrFilter methodsFor: 'operations'!

{XnRegion} complement

	| result {XnRegion} |
	result _ Filter openFilter: self coordinateSpace.
	self subFilters stepper forEach: [ :sub {XnRegion} |
		result _ result intersect: sub complement].
	^result! !

!OrFilter methodsFor: 'filtering'!

{BooleanVar} match: region {XnRegion}
	"tell whether a region passes this filter"
	self subFilters stepper forEach: [ :sub {Filter} |
		(sub match: region)
			ifTrue: [^true]].
	^false!

{Filter} pass: parent {Joint}
	"return the simplest filter for looking at the children"
	| result {XnRegion} |
	result _ Filter closedFilter: self coordinateSpace.
	self subFilters stepper forEach: [ :sub {Filter} |
		result _ result unionWith: (sub pass: parent)].
	^result cast: Filter!

{ImmuSet of: Filter} subFilters
	^mySubFilters! !

!OrFilter methodsFor: 'protected: protected operations'!

{XnRegion} fetchSpecialSubset: other {XnRegion}
	"return self or other if one is clearly a subset of the other, else NULL"
	| filter {Filter} defaultRegion {XnRegion} |
	filter _ other cast: Filter.
	defaultRegion _ self.
	self subFilters stepper forEach: [ :subfilter {Filter} | 
		| a {XnRegion} b {XnRegion} |
		((a _ subfilter fetchSpecialSubset: filter) basicCast: Heaper star) == other ifTrue: [^other].
		((b _ filter fetchSpecialSubset: subfilter) basicCast: Heaper star) == other ifTrue: [^other].
		((a basicCast: Heaper star) == other or: [(b basicCast: Heaper star) == other]) ifFalse: [defaultRegion _ NULL]].
	^defaultRegion! !

!OrFilter methodsFor: 'enumerating'!

{Stepper of: Filter} intersectedFilters

	^Stepper itemStepper: self!

{Stepper of: Filter} unionedFilters

	^mySubFilters stepper! !

!OrFilter methodsFor: 'accessing'!

{XnRegion} baseRegion

	Heaper BLAST: #NotSimpleEnough.
	^NULL!

{XnRegion} relevantRegion

	| result {XnRegion} |
	result := self filterSpace baseSpace emptyRegion.
	mySubFilters stepper forEach: [ :sub {Filter} |
		result := result unionWith: sub relevantRegion].
	^result! !

!OrFilter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySubFilters _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySubFilters.! !