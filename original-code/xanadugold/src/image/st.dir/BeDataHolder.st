'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:37 pm'!

BeRangeElement subclass: #BeDataHolder
	instanceVariableNames: 'myValue {PrimValue}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(BeDataHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeDataHolder methodsFor: 'accessing'!

{FeRangeElement} makeFe: label {BeLabel | NULL}
	"Return me wrapped with a session level DataHolder."
	
	^FeDataHolder on: self!

{PrimValue} value
	^myValue! !

!BeDataHolder methodsFor: 'create'!

create: value {PrimValue}

	super create.
	myValue := value.
	self newShepherd! !

!BeDataHolder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myValue _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myValue.! !