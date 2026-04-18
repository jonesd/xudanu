'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:08 pm'!

Filter subclass: #AndFilter
	instanceVariableNames: 'mySubFilters {ImmuSet of: Filter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!

(AndFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!AndFilter methodsFor: 'creation'!

create: cs {FilterSpace} with: subs {ImmuSet of: Filter}
	super create: cs.
	mySubFilters _ subs! !

!AndFilter methodsFor: 'filtering'!

{BooleanVar} match: region {XnRegion}
	"tell whether a region passes this filter"
	self subFilters stepper forEach: [ :sub {Filter} |
		(sub match: region)
			ifFalse: [^false]].
	^true!

{Filter} pass: parent {Joint}
	"return the simplest filter for looking at the children"
	| result {XnRegion} |
	result _ Filter openFilter: self coordinateSpace.
	self subFilters stepper forEach: [ :sub {Filter} |
		result _ result intersect: (sub pass: parent)].
	^result cast: Filter!

{ImmuSet of: Filter} subFilters
	^mySubFilters! !

!AndFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name.
	self subFilters printOnWithSimpleSyntax: oo with: '(' with: ' && ' with: ')'! !

!AndFilter methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^(self coordinateSpace hashForEqual bitXor: mySubFilters hashForEqual)
		bitXor: #cat.U.AndFilter hashForEqual!

{BooleanVar} isAllFilter

	^false!

{BooleanVar} isAnyFilter
	
	^false!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: AndFilter into: [:af |
			^af subFilters isEqual: self subFilters]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFull	

	^false! !

!AndFilter methodsFor: 'operations'!

{XnRegion} complement

	| result {XnRegion} |
	result _ Filter closedFilter: self coordinateSpace.
	self subFilters stepper forEach: [ :sub {XnRegion} |
		result _ result unionWith: sub complement].
	^result! !

!AndFilter methodsFor: 'protected operations'!

{XnRegion} fetchSpecialSubset: other {XnRegion}
	"return self or other if one is clearly a subset of the other, else NULL"
	| filter {Filter} defaultRegion {XnRegion} |
	filter _ other cast: Filter.
	defaultRegion _ other.
	self subFilters stepper forEach: [ :subfilter {Filter} | | a {XnRegion} b {XnRegion} |
		(a _ subfilter fetchSpecialSubset: filter) == subfilter ifTrue: [^self].
		(b _ filter fetchSpecialSubset: subfilter) == subfilter ifTrue: [^self].
		((a basicCast: Heaper star) == other or: [(b basicCast: Heaper star) == other]) ifFalse: [defaultRegion _ NULL]].
	^defaultRegion! !

!AndFilter methodsFor: 'enumerating'!

{Stepper of: Filter} intersectedFilters

	^mySubFilters stepper!

{Stepper of: Filter} unionedFilters

	^Stepper itemStepper: self! !

!AndFilter methodsFor: 'accessing'!

{XnRegion} baseRegion

	Heaper BLAST: #NotSimpleEnough.
	^NULL!

{XnRegion} relevantRegion

	| result {XnRegion} |
	result := self filterSpace baseSpace emptyRegion.
	mySubFilters stepper forEach: [ :sub {Filter} |
		result := result unionWith: sub relevantRegion].
	^result! !

!AndFilter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySubFilters _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySubFilters.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AndFilter class
	instanceVariableNames: ''!

(AndFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!AndFilter class methodsFor: 'pseudo constructors'!

{Filter} make: cs {FilterSpace} with: subs {ImmuSet of: Filter}
	"assumes that the interactions between elements have already been removed"
	
	subs isEmpty ifTrue: [^cs fullRegion cast: Filter].
	subs count = 1 ifTrue: [^subs theOne cast: Filter].
	^self create: cs with: subs! !