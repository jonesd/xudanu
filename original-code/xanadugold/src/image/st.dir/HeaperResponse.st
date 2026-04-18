'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:43 pm'!

Response subclass: #HeaperResponse
	instanceVariableNames: 'myResult {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr-response'!

(HeaperResponse getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!HeaperResponse methodsFor: 'accessing'!

{Heaper} value
	^myResult! !

!HeaperResponse methodsFor: 'creation'!

create: heaper {Heaper}
	super create.
	myResult _ heaper! !

!HeaperResponse methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myResult << ')'! !

!HeaperResponse methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myResult _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myResult.! !