'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:16 pm'!

Filter subclass: #SupersetFilter
	instanceVariableNames: 'myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!

(SupersetFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!SupersetFilter methodsFor: 'filtering'!

{BooleanVar} match: region {XnRegion}
	"tell whether a region passes this filter"
	^myRegion isSubsetOf: region!

{Filter} pass: parent {Joint}
	"return the simplest filter for looking at the children"
	(myRegion isSubsetOf: parent intersected) ifTrue:
		[^Filter openFilter: self coordinateSpace].
	(myRegion isSubsetOf: parent unioned) ifFalse:
		[^Filter closedFilter: self coordinateSpace].
	^self!

{XnRegion} region
	^myRegion! !

!SupersetFilter methodsFor: 'operations'!

{XnRegion} complement

	^Filter notSupersetFilter: self coordinateSpace with: myRegion! !

!SupersetFilter methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^(self coordinateSpace hashForEqual bitXor: myRegion hashForEqual)
		bitXor: #cat.U.SupersetFilter hashForEqual!

{BooleanVar} isAllFilter

	^true!

{BooleanVar} isAnyFilter
	
	^false!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: SupersetFilter into: [:ssf |
			^ssf region isEqual: myRegion]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFull	

	^false! !

!SupersetFilter methodsFor: 'protected: protected operations'!

{XnRegion} fetchSpecialUnion: other {XnRegion unused}
	^NULL! !

!SupersetFilter methodsFor: 'creation'!

create: cs {FilterSpace} with: region {XnRegion}
	super create: cs.
	myRegion _ region! !

!SupersetFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myRegion << ')'! !

!SupersetFilter methodsFor: 'protected operations'!

{Pair of: Filter} fetchCanonicalUnion: other {Filter}
	"return NULL, or the pair of canonical filters (left == new1 | self, right == new2 | other)"
	
	other
		cast: NotSubsetFilter into: [:nsf |
			| others {XnRegion} |
			others _ nsf region.
			(myRegion isSubsetOf: others)
				ifFalse: [^Pair make: (Filter supersetFilter: self coordinateSpace
						with: (myRegion intersect: nsf region))
					with: other]]
		others: [].
	^NULL!

{XnRegion} fetchSpecialIntersect: other {XnRegion}

	other
		cast: SubsetFilter into: [:subF |
			(myRegion isSubsetOf: subF region)
				ifFalse: [^Filter closedFilter: self coordinateSpace]]
		cast: SupersetFilter into: [:superF |
			^Filter supersetFilter: self coordinateSpace
				with: (myRegion unionWith: superF region)]
		others: [].
	^NULL!

{XnRegion} fetchSpecialSubset: other {XnRegion}

	other
		cast: NotSubsetFilter  into: [:nSubF |
			(myRegion isSubsetOf: nSubF region)
				ifFalse: [^self]]
		cast: SupersetFilter into: [:superF |
			| others {XnRegion} |
			others _ superF region.
			(myRegion isSubsetOf: others) ifTrue: [^other].
			(others isSubsetOf: myRegion) ifTrue: [^self]]
		others: [].
	^NULL! !

!SupersetFilter methodsFor: 'enumerating'!

{Stepper of: Filter} intersectedFilters

	^Stepper itemStepper: self!

{Stepper of: Filter} unionedFilters

	^Stepper itemStepper: self! !

!SupersetFilter methodsFor: 'accessing'!

{XnRegion} baseRegion

	^myRegion!

{XnRegion} relevantRegion

	^myRegion! !

!SupersetFilter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRegion _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRegion.! !