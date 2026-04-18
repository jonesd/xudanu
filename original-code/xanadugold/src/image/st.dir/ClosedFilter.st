'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:09 pm'!

Filter subclass: #ClosedFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!

(ClosedFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!ClosedFilter methodsFor: 'creation'!

create: cs {FilterSpace}
	super create: cs! !

!ClosedFilter methodsFor: 'operations'!

{XnRegion} complement

	^Filter openFilter: self coordinateSpace!

{XnRegion} intersect: other {XnRegion unused}
	^self!

{XnRegion} minus: other {XnRegion unused}
	^self!

{XnRegion} unionWith: other {XnRegion}
	^other! !

!ClosedFilter methodsFor: 'filtering'!

{BooleanVar} match: region {XnRegion unused}
	"tell whether a region passes this filter"
	^false!

{Filter} pass: parent {Joint unused}
	"return the simplest filter for looking at the children"
	^self! !

!ClosedFilter methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^self coordinateSpace hashForEqual bitXor: #cat.U.ClosedFilter hashForEqual!

{BooleanVar} isAllFilter

	^false!

{BooleanVar} isAnyFilter
	
	^true!

{BooleanVar} isEmpty
	^true!

{BooleanVar} isEnumerable: order {OrderSpec default: NULL}
	
	^true!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: ClosedFilter into: [:cf |
			^cf coordinateSpace isEqual: self coordinateSpace]
		others: [^false].
	^false "fodder"!

{BooleanVar} isFull	

	^false! !

!ClosedFilter methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << self coordinateSpace << ')'! !

!ClosedFilter methodsFor: 'protected: protected operations'!

{XnRegion} fetchSpecialSubset: other {XnRegion unused}
	^self! !

!ClosedFilter methodsFor: 'protected: enumerating'!

{Stepper of: Position} actualStepper: order {OrderSpec} 
	
	^Stepper emptyStepper! !

!ClosedFilter methodsFor: 'enumerating'!

{Stepper of: Filter} intersectedFilters

	^Stepper itemStepper: self!

{Stepper of: Filter} unionedFilters

	^Stepper emptyStepper! !

!ClosedFilter methodsFor: 'accessing'!

{XnRegion} baseRegion

	^(self coordinateSpace cast: FilterSpace) emptyRegion!

{XnRegion} relevantRegion

	^self filterSpace baseSpace emptyRegion! !

!ClosedFilter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClosedFilter class
	instanceVariableNames: ''!

(ClosedFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #COPY; yourself)!

!ClosedFilter class methodsFor: 'pseudo constructors'!

{Filter} make: space {CoordinateSpace}

	^self create: (space cast: FilterSpace)! !