'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:11 pm'!

Filter subclass: #NotSubsetFilter
	instanceVariableNames: 'myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!

(NotSubsetFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!NotSubsetFilter methodsFor: 'filtering'!

{BooleanVar} match: region {XnRegion}
	"tell whether a region passes this filter"
	^(region isSubsetOf: myRegion) not!

{Filter} pass: parent {Joint}
	"return the simplest filter for looking at the children"
	(parent intersected isSubsetOf: myRegion)
		ifFalse: [^Filter openFilter: self coordinateSpace].
	(parent unioned isSubsetOf: myRegion)
		ifTrue: [^Filter closedFilter: self coordinateSpace].
	^self!

{XnRegion} region
	^myRegion! !

!NotSubsetFilter methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^(self coordinateSpace hashForEqual bitXor: myRegion hashForEqual)
		bitXor: #cat.U.NotSubsetFilter hashForEqual!

{BooleanVar} isAllFilter

	^false!

{BooleanVar} isAnyFilter
	
	^true!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: NotSubsetFilter into: [:nsf |
			^nsf region isEqual: myRegion]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFull	

	^false! !

!NotSubsetFilter methodsFor: 'operations'!

{XnRegion} complement

	^Filter subsetFilter: self coordinateSpace with: myRegion! !

!NotSubsetFilter methodsFor: 'creation'!

create: cs {FilterSpace} with: region {XnRegion}
	super create: cs.
	myRegion _ region! !

!NotSubsetFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << 'IntersectionFilter(' << myRegion complement << ')'! !

!NotSubsetFilter methodsFor: 'protected operations'!

{XnRegion} fetchSpecialIntersect: other {XnRegion}

	other
		cast: SubsetFilter into: [:sf |
			(sf region isSubsetOf: myRegion)
				ifTrue: [^Filter closedFilter: self coordinateSpace]
				ifFalse: [^NULL]]
		others: [^NULL].
	^NULL "fodder"!

{XnRegion} fetchSpecialSubset: other {XnRegion}

	other
		cast: NotSubsetFilter into: [:nsf |
			| others {XnRegion} |
			others _ nsf region.
			(others isSubsetOf: myRegion) ifTrue: [^self].
			(myRegion isSubsetOf: others) ifTrue: [^other]]
		others: [].
	^NULL!

{XnRegion} fetchSpecialUnion: other {XnRegion}

	other
		cast: SubsetFilter into: [:sf |
			(myRegion isSubsetOf: sf region)
				ifTrue: [^Filter openFilter: self coordinateSpace]
				ifFalse: [^NULL]]
		cast: NotSubsetFilter into: [:nsf |
			^Filter notSubsetFilter: self coordinateSpace
				with: (myRegion intersect: nsf region)]
		others: [^NULL].
	^NULL "fodder"! !

!NotSubsetFilter methodsFor: 'enumerating'!

{Stepper of: Filter} intersectedFilters

	^Stepper itemStepper: self!

{Stepper of: Filter} unionedFilters

	^Stepper itemStepper: self! !

!NotSubsetFilter methodsFor: 'accessing'!

{XnRegion} baseRegion

	^myRegion complement!

{XnRegion} relevantRegion

	^myRegion complement! !

!NotSubsetFilter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRegion _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRegion.! !