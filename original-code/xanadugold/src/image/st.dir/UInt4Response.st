'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:46 pm'!

Response subclass: #UInt4Response
	instanceVariableNames: 'myResult {UInt4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr-response'!

(UInt4Response getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #OBSOLETE; add: #COPY; add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!UInt4Response methodsFor: 'accessing'!

{UInt32} value
	^myResult! !

!UInt4Response methodsFor: 'creation'!

create: uint4 {UInt32}
	super create.
	myResult _ uint4! !

!UInt4Response methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myResult << ')'! !

!UInt4Response methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myResult _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myResult.! !