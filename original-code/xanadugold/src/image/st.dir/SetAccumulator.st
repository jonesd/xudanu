'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:36 pm'!

Accumulator subclass: #SetAccumulator
	instanceVariableNames: 'muSet {MuSet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Sets'!
SetAccumulator comment:
'A SetAccumulator accumulates a bunch of objects and then makes an ImmuSet containing all the accumulated objects.  Several people have observed that a SetAccumulator doesn''t buy you much because instead you could just store into a MuSet.  While this is true (and is in fact how SetAccumulator is trivially implemented), my feeling is that if what a loop is doing is enumerating a bunch of elements from which a Set is to be formed, using a SetAccumulator in the loops says this more clearly to readers of the code.'!

(SetAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SetAccumulator methodsFor: 'accessing'!

{void} step: someObj {Heaper}
	muSet store: someObj!

{Heaper} value
	^ muSet asImmuSet! !

!SetAccumulator methodsFor: 'protected: creation'!

create
	super create.
	muSet _ MuSet make!

create: initialSet {ScruSet}
	super create.
	muSet _ initialSet asMuSet! !

!SetAccumulator methodsFor: 'creation'!

{Accumulator} copy
	^ SetAccumulator create: muSet asMuSet! !

!SetAccumulator methodsFor: 'smalltalk: passe'!

{ImmuSet} get
	self passe! !

!SetAccumulator methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	muSet _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: muSet.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SetAccumulator class
	instanceVariableNames: ''!

(SetAccumulator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SetAccumulator class methodsFor: 'instance creation'!

{SetAccumulator} make
	"Make a SetAccumulator which starts out with no elements accumulated"
	^SetAccumulator create!

{SetAccumulator} make: initialSet {ScruSet}
	"Make a new SetAccumulator in which all the current elements of initialSet are already accumulated.
	Future changes to initialSet have no effect on the accumulator."
	^SetAccumulator create: initialSet! !