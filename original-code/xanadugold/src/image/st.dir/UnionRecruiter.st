'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:37 pm'!

Accumulator subclass: #UnionRecruiter
	instanceVariableNames: 'muSet {MuSet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Sets'!
UnionRecruiter comment:
'Like a SetAccumulator, a UnionRecruiter makes an ImmuSet out of the things that it Accumulates.  However, the things that a UnionRecruiter accumulates must themselves be ScruSets, and the resulting ImmuSet consists of the union of the elements of each of the accumulated sets as of the time they were accumulated.'!

(UnionRecruiter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!UnionRecruiter methodsFor: 'accessing'!

{void} step: someObj {Heaper}
	muSet storeAll: (someObj cast: ScruSet)!

{Heaper} value
	^ muSet asImmuSet! !

!UnionRecruiter methodsFor: 'protected: creation'!

create
	super create.
	muSet _ MuSet make! !

!UnionRecruiter methodsFor: 'creation'!

{Accumulator} copy
	| result {Accumulator} |
	result _ UnionRecruiter make.
	result step: muSet.
	^result! !

!UnionRecruiter methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	muSet _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: muSet.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UnionRecruiter class
	instanceVariableNames: ''!

(UnionRecruiter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!UnionRecruiter class methodsFor: 'pseudo constructors'!

{UnionRecruiter} make
	"Make a new UnionRecruiter which hasn't yet accumulated anything"
	^UnionRecruiter create! !