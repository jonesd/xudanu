'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:10 pm'!

CoordinateSpace subclass: #FilterSpace
	instanceVariableNames: 'myBaseSpace {CoordinateSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!
FilterSpace comment:
'A FilterSpace can be described mathematically as a power space of its baseSpace, i.e. the set of all subsets of the baseSpace. Each position in a FilterSpace is a Region in the baseSpace, and each Filter is a set of Regions taken from the baseSpace. See Filter for more detail.'!

(FilterSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!FilterSpace methodsFor: 'creation'!

create: base {CoordinateSpace}
	super create.
	self finishCreate: (ClosedFilter make: self)
		with: (OpenFilter make: self)
		with: (FilterDsp make: self)
		with: NULL
		with: NULL.
	myBaseSpace := base! !

!FilterSpace methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^myBaseSpace hashForEqual + 1!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: FilterSpace into: [:fs |
			^fs baseSpace isEqual: myBaseSpace]
		others: [^false].
	^false "fodder"! !

!FilterSpace methodsFor: 'accessing'!

{CoordinateSpace CLIENT INLINE} baseSpace
	"Essential.  The CoordinateSpace of the Regions that are the input to Filters in this FilterSpace."
	
	^myBaseSpace! !

!FilterSpace methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myBaseSpace << ')'! !

!FilterSpace methodsFor: 'making'!

{Filter CLIENT INLINE} allFilter: region {XnRegion}
	"Essential. A region that matches any region that contains all the Positions in, i.e. is a superset of, the given region."
	
	^Filter supersetFilter: self with: region!

{Filter CLIENT INLINE} anyFilter: baseRegion {XnRegion}
	"Essential. A filter that matches any region that intersects the given region."
	
	^Filter intersectionFilter: self with: baseRegion!

{Filter INLINE} intersectionFilter: region {XnRegion}
	"Essential. A filter that matches any region that intersects the given region."
	
	^Filter intersectionFilter: self with: region!

{Filter INLINE} notSubsetFilter: region {XnRegion}
	"A filter matching any regions that is not a subset of the given region."
	
	^Filter notSubsetFilter: self with: region!

{Filter INLINE} notSupersetFilter: region {XnRegion}
	"A filter that matches any region that is not a superset of the given region."
	
	^Filter notSupersetFilter: self with: region!

{Filter INLINE} orFilter: subs {ScruSet of: Filter}
	"A filter that matches any region that any of the filters in the set would have matched."
	
	^Filter orFilter: self with: subs!

{FilterPosition CLIENT INLINE} position: baseRegion {XnRegion}
	"Essential. Given a Region in the baseSpace, make a Position which corresponds to it, so that
		filter->hasMember (this->position (baseRegion)) iff filter->match (baseRegion)"
	
	^FilterPosition make: baseRegion!

{Filter INLINE} subsetFilter: region {XnRegion}
	"A filter that matches any region that is a subset of the given region."
	
	^Filter subsetFilter: self with: region!

{Filter INLINE} supersetFilter: region {XnRegion}
	"Essential. A region that matches any region that is a superset of the given region."
	
	^Filter supersetFilter: self with: region! !

!FilterSpace methodsFor: 'hooks:'!

{void SEND.HOOK} sendFilterSpaceTo: xmtr {Xmtr}
	xmtr sendHeaper: myBaseSpace.! !

!FilterSpace methodsFor: 'generated:'!

{void} sendSelfTo: xmtr {Xmtr}
	
	self sendFilterSpaceTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FilterSpace class
	instanceVariableNames: ''!

(FilterSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #PSEUDO.COPY; add: #CONCRETE; add: #ON.CLIENT; yourself)!

!FilterSpace class methodsFor: 'creation'!

{FilterSpace CLIENT} make: base {CoordinateSpace}
	"A FilterSpace on the given base space."
	
	^FilterSpace create: base! !

!FilterSpace class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Filter CLIENT} andFilter: baseRegion {XnRegion}
{Filter CLIENT} anyFilter: baseRegion {XnRegion}
{CoordinateSpace CLIENT} baseSpace
{FilterPosition CLIENT} position: baseRegion {XnRegion}
"! !

!FilterSpace class methodsFor: 'rcvr pseudo constructors'!

{Heaper} make.Rcvr: rcvr {Rcvr}
	^(FilterSpace new.Become: ((rcvr cast: SpecialistRcvr) makeIbid: FilterSpace))
		 create: (rcvr receiveHeaper cast: CoordinateSpace)! !