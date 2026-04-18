'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:10 pm'!

IdentityDsp subclass: #FilterDsp
	instanceVariableNames: 'myCS {FilterSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Filter'!
FilterDsp comment:
'There are no non-trivial Dsps currently defined on a FilterSpace.

It would be possible to define them with reference to a Dsp in the baseSpace, as
	filterDsp->of(filter)->match(R) iff filter->match(filterDsp->baseDsp()->inverseOf(R))
		for all R in the base space.
However, we have not yet found a use for them.'!

(FilterDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!FilterDsp methodsFor: 'creation'!

create: cs {CoordinateSpace}
	super create.
	myCS _ cs cast: FilterSpace.! !

!FilterDsp methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^myCS hashForEqual + #cat.U.FilterDsp hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other
		cast: FilterDsp into: [:fd |
			^fd coordinateSpace isEqual: myCS]
		others: [^false].
	^false "fodder"! !

!FilterDsp methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^myCS! !

!FilterDsp methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCS _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCS.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FilterDsp class
	instanceVariableNames: ''!

(FilterDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!FilterDsp class methodsFor: 'pseudo constructors'!

make: cs {FilterSpace}
	"An identity Dsp on the given FilterSpace."
	
	^FilterDsp create: cs! !

!FilterDsp class methodsFor: 'smalltalk: initialization'!

suppressInitTimeInherited!

suppressLinkTimeInherited! !