'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:06 pm'!

TableEntry subclass: #PositionEntry
	instanceVariableNames: 'myKey {Position}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-SetTable'!

(PositionEntry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!PositionEntry methodsFor: 'accessing'!

{BooleanVar} match: key {Position}
	"Return true if my key matches key."
	
	^key isEqual: myKey!

{Position} position
	^myKey! !

!PositionEntry methodsFor: 'creation'!

{TableEntry} copy
	^ PositionEntry create: myKey with: self value!

create: key {Position} with: value {Heaper}
	super create: value.
	myKey _ key!

create: next {TableEntry} with: value {Heaper} with: key {Position}
	super create: next with: value.
	myKey _ key! !

!PositionEntry methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myKey _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myKey.! !