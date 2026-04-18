'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:12 pm'!

Filter subclass: #OpenFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!

(OpenFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!OpenFilter methodsFor: 'operations'!

{XnRegion} complement

	^Filter closedFilter: self coordinateSpace!

{XnRegion} intersect: other {XnRegion}
	^other!

{XnRegion} minus: other {XnRegion}
	^other complement!

{XnRegion} unionWith: other {XnRegion unused}
	^self! !

!OpenFilter methodsFor: 'filtering'!

{BooleanVar} match: region {XnRegion unused}
	"tell whether a region passes this filter"
	^true!

{Filter} pass: parent {Joint unused}
	"return the simplest filter for looking at the children"
	^self! !

!OpenFilter methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^self coordinateSpace hashForEqual bitXor: #cat.U.OpenFilter hashForEqual!

{BooleanVar} isAllFilter

	^true!

{BooleanVar} isAnyFilter
	
	^false!

{BooleanVar} isEmpty
	^false!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: OpenFilter into: [:of |
			^of coordinateSpace isEqual: self coordinateSpace]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFull	

	^true! !

!OpenFilter methodsFor: 'creation'!

create: cs {FilterSpace}
	super create: cs! !

!OpenFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self coordinateSpace << ')'! !

!OpenFilter methodsFor: 'protected: protected operations'!

{XnRegion} fetchSpecialSubset: other {XnRegion}
	^other! !

!OpenFilter methodsFor: 'enumerating'!

{Stepper of: Filter} intersectedFilters

	^Stepper emptyStepper!

{Stepper of: Filter} unionedFilters

	^Stepper itemStepper: self! !

!OpenFilter methodsFor: 'accessing'!

{XnRegion} baseRegion

	^(self coordinateSpace cast: FilterSpace) emptyRegion!

{XnRegion} relevantRegion

	^self filterSpace baseSpace emptyRegion! !

!OpenFilter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OpenFilter class
	instanceVariableNames: ''!

(OpenFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!OpenFilter class methodsFor: 'pseudo constructors'!

{Filter} make: space {CoordinateSpace}

	^self create: (space cast: FilterSpace)! !