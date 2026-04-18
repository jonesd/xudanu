'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:43 pm'!

Response subclass: #Int4Response
	instanceVariableNames: 'myResult {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr-response'!

(Int4Response getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!Int4Response methodsFor: 'accessing'!

{Int32} value
	^myResult! !

!Int4Response methodsFor: 'creation'!

create: int4 {Int32}
	super create.
	myResult _ int4! !

!Int4Response methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myResult << ')'! !

!Int4Response methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myResult _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myResult.! !