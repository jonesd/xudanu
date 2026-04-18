'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:48 pm'!

Thunk subclass: #GCMaxInterval
	instanceVariableNames: 'interval {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-garbage'!

(GCMaxInterval getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!GCMaxInterval methodsFor: 'operate'!

{void} execute
	"Ignored in Smalltalk"! !

!GCMaxInterval methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	interval _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: interval.! !