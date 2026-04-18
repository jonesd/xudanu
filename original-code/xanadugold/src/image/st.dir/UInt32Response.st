'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:45 pm'!

Response subclass: #UInt32Response
	instanceVariableNames: 'myResult {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr-response'!

(UInt32Response getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!UInt32Response methodsFor: 'accessing'!

{UInt32} value
	^myResult! !

!UInt32Response methodsFor: 'creation'!

create: uint4 {UInt32}
	super create.
	myResult _ uint4! !

!UInt32Response methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myResult << ')'! !

!UInt32Response methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myResult _ receiver receiveUInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendUInt32: myResult.! !