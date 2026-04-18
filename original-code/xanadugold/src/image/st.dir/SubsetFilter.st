'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:16 pm'!

Filter subclass: #SubsetFilter
	instanceVariableNames: 'myRegion {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!

(SubsetFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!SubsetFilter methodsFor: 'creation'!

create: cs {FilterSpace} with: region {XnRegion}
	super create: cs.
	myRegion _ region! !

!SubsetFilter methodsFor: 'operations'!

{XnRegion} complement

	^Filter notSubsetFilter: self coordinateSpace with: myRegion! !

!SubsetFilter methodsFor: 'filtering'!

{BooleanVar} match: region {XnRegion}
	"tell whether a region passes this filter"
	^region isSubsetOf: myRegion!

{Filter} pass: parent {Joint}
	"return the simplest filter for looking at the children"
	(parent unioned isSubsetOf: myRegion) ifTrue:
		[^Filter openFilter: self coordinateSpace].
	(parent intersected isSubsetOf: myRegion) ifFalse:
		[^Filter closedFilter: self coordinateSpace].
	^self!

{XnRegion} region
	^myRegion! !

!SubsetFilter methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^(self coordinateSpace hashForEqual bitXor: myRegion hashForEqual)
		bitXor: #cat.U.SubsetFilter hashForEqual!

{BooleanVar} isAllFilter

	^false!

{BooleanVar} isAnyFilter
	
	^false!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: SubsetFilter into: [:ssf |
			^ssf region isEqual: myRegion]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFull	

	^false! !

!SubsetFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myRegion << ')'! !

!SubsetFilter methodsFor: 'protected: protected operations'!

{XnRegion} fetchSpecialUnion: other {XnRegion unused}
	^NULL! !

!SubsetFilter methodsFor: 'protected operations'!

{XnRegion} fetchSpecialIntersect: other {XnRegion}

	other
		cast: SubsetFilter into: [:sf |
			^Filter subsetFilter: self coordinateSpace
				with: (sf region intersect: myRegion)]
		others: [^NULL].
	^NULL "fodder"!

{XnRegion} fetchSpecialSubset: other {XnRegion}

	other
		cast: SubsetFilter into: [:sf |
			| others {XnRegion} |
			others _ sf region.
			(others isSubsetOf: myRegion) ifTrue: [^other].
			(myRegion isSubsetOf: others) ifTrue: [^self]]
		others: [].
	^NULL! !

!SubsetFilter methodsFor: 'enumerating'!

{Stepper of: Filter} intersectedFilters

	^Stepper itemStepper: self!

{Stepper of: Filter} unionedFilters

	^Stepper itemStepper: self! !

!SubsetFilter methodsFor: 'accessing'!

{XnRegion} baseRegion

	Heaper BLAST: #NotSimpleEnough.
	^NULL!

{XnRegion} relevantRegion

	^myRegion complement! !

!SubsetFilter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRegion _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRegion.! !