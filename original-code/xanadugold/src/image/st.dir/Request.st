'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:13 pm'!

Heaper subclass: #Request
	instanceVariableNames: '
		myRcvr {Heaper}
		myMsgName {char star}
		myAmServer {BooleanVar NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!
Request comment:
'If myAmServer is true, myMsgName is an allocated string that must be deleted, otherwise it is
from a constant string and must not be deleted.'!

(Request getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!Request methodsFor: 'accessing'!

{char star} messageName
	^myMsgName!

{Heaper} receiver
	^myRcvr! !

!Request methodsFor: 'creation'!

create: name {char star} with: receiver {Heaper}
	"This constructor is called by the proxy routine on the client side."
	super create.
	myMsgName _ name.
	myRcvr _ receiver.
	myAmServer _ false.! !

!Request methodsFor: 'evaluate'!

{Response} evaluate
	self subclassResponsibility! !

!Request methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myRcvr << ', ' << myMsgName << ')'! !

!Request methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartRequest: rcvr {Rcvr unused default: NULL}
	myAmServer _ true.
	DeleteExecutor registerHolder: self with: myMsgName.! !

!Request methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRcvr _ receiver receiveHeaper.
	myMsgName _ receiver receiveString.
	self restartRequest: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRcvr.
	xmtr sendString: myMsgName.! !