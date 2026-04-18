'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:40 pm'!

BeRangeElement subclass: #BeIDHolder
	instanceVariableNames: 'myID {ID}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(BeIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeIDHolder methodsFor: 'accessing'!

{ID} iD
	^myID!

{FeRangeElement} makeFe: label {BeLabel | NULL}
	^FeIDHolder on: self! !

!BeIDHolder methodsFor: 'protected: dismantle'!

{void} dismantle
	"Does this need to clear the GrandMap table?"
	
	self unimplemented! !

!BeIDHolder methodsFor: 'protected: creation'!

create: iD {ID}
	super create.
	myID _ iD.
	self newShepherd! !

!BeIDHolder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myID _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myID.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BeIDHolder class
	instanceVariableNames: ''!

(BeIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeIDHolder class methodsFor: 'creation'!

make: iD {ID}
	^ self create: iD! !