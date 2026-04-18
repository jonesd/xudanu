'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:11 pm'!

Filter subclass: #NotSupersetFilter
	instanceVariableNames: 'myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!

(NotSupersetFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!NotSupersetFilter methodsFor: 'filtering'!

{BooleanVar} match: region {XnRegion}
	"tell whether a region passes this filter"
	^(myRegion isSubsetOf: region) not!

{Filter} pass: parent {Joint}
	"return the simplest filter for looking at the children"
	(myRegion isSubsetOf: parent unioned) ifFalse:
		[^Filter openFilter: self coordinateSpace].
	(myRegion isSubsetOf: parent intersected) ifTrue:
		[^Filter closedFilter: self coordinateSpace].
	^self!

{XnRegion} region
	^myRegion! !

!NotSupersetFilter methodsFor: 'operations'!

{XnRegion} complement

	^Filter supersetFilter: self coordinateSpace with: myRegion! !

!NotSupersetFilter methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^(self coordinateSpace hashForEqual bitXor: myRegion hashForEqual)
		bitXor: #cat.U.NotSupersetFilter hashForEqual!

{BooleanVar} isAllFilter

	^false!

{BooleanVar} isAnyFilter
	
	^false!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: NotSupersetFilter into: [:nsf |
			^nsf region isEqual: myRegion]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFull	

	^false! !

!NotSupersetFilter methodsFor: 'creation'!

create: cs {FilterSpace} with: region {XnRegion}
	super create: cs.
	myRegion _ region! !

!NotSupersetFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myRegion << ')'! !

!NotSupersetFilter methodsFor: 'protected operations'!

{Pair of: Filter} fetchCanonicalIntersect: other {Filter}
	"return NULL, or the pair of canonical filters (left == new1 | self, right == new2 | other)"
	
	other
		cast: SubsetFilter into: [:subF |
			| others {XnRegion} |
			others _ subF region.
			(myRegion isSubsetOf: others)
				ifTrue: [^NULL]
				ifFalse: [^Pair make: (Filter notSupersetFilter: self coordinateSpace
						with: (myRegion intersect: others))
					with: other]]
		cast: SupersetFilter into: [:superF |
			| others {XnRegion} |
			others _ superF region.
			(myRegion intersects: others)
				ifTrue: [^Pair make: (Filter notSupersetFilter: self coordinateSpace
						with: (myRegion minus: superF region))
					with: other]
				ifFalse: [^NULL]]
		others: [^NULL].
	^NULL "fodder"!

{Pair of: Filter} fetchCanonicalUnion: other {Filter}
	"return NULL, or the pair of canonical filters (left == new1 | self, right == new2 | other)"
	
	other
		cast: SupersetFilter into: [:sf |
			| others {XnRegion} |
			others _ sf region.
			(myRegion intersects: others)
				ifTrue: [^Pair make: self
					with: (Filter supersetFilter: self coordinateSpace
						with: (sf region minus: myRegion))]
				ifFalse: [^NULL]]
		others: [^NULL].
	^NULL "fodder"!

{XnRegion} fetchSpecialIntersect: other {XnRegion}

	other
		cast: SupersetFilter into: [:sf |
			(myRegion isSubsetOf: sf region)
				ifTrue: [^Filter closedFilter: self coordinateSpace]
				ifFalse: [^NULL]]
		others: [^NULL].
	^NULL "fodder"!

{XnRegion} fetchSpecialSubset: other {XnRegion}

	other
		cast: SubsetFilter into: [:subF |
			(myRegion isSubsetOf: subF region)
				ifFalse: [^other]]
		cast: NotSupersetFilter into: [:nSuperF |
			| others {XnRegion} |
			others _ nSuperF region.
			(myRegion isSubsetOf: others) ifTrue: [^self].
			(others isSubsetOf: myRegion) ifTrue: [^other]]
		others: [].
	^NULL!

{XnRegion} fetchSpecialUnion: other {XnRegion}

	other
		cast: NotSubsetFilter into: [:nSubF |
			(myRegion isSubsetOf: nSubF region)
				ifFalse: [^Filter openFilter: self coordinateSpace]]
		cast: SupersetFilter into: [:superF |
			(superF region isSubsetOf: myRegion)
				ifTrue: [^Filter openFilter: self coordinateSpace]]
		cast: NotSupersetFilter into: [:nSuperF |
			^Filter notSupersetFilter: self coordinateSpace
				with: (myRegion unionWith: nSuperF region)]
		others: [].
	^NULL! !

!NotSupersetFilter methodsFor: 'enumerating'!

{Stepper of: Filter} intersectedFilters

	^Stepper itemStepper: self!

{Stepper of: Filter} unionedFilters

	^Stepper itemStepper: self! !

!NotSupersetFilter methodsFor: 'accessing'!

{XnRegion} baseRegion

	Heaper BLAST: #NotSimpleEnough.
	^NULL!

{XnRegion} relevantRegion

	^myRegion! !

!NotSupersetFilter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRegion _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRegion.! !