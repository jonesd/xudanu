'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:41 pm'!

BeRangeElement subclass: #BeLabel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Basic'!

(BeLabel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!BeLabel methodsFor: 'accessing'!

{FeRangeElement} makeFe: label {BeLabel | NULL}
	^FeLabel on: self! !

!BeLabel methodsFor: 'creation'!

create
	super create.
	self newShepherd.
	self hack.  "Labels don't know when they're pointed to as labels instead of range elements, so just remember them."
	self remember! !

!BeLabel methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !