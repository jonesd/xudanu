'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:03 pm'!

Tester subclass: #FebeTester
	instanceVariableNames: '
		myKeyMaster {KeyMaster NOCOPY}
		myConnection {Connection NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Docs + Links'!

(FebeTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY boot ); add: #DEFERRED; yourself)!

!FebeTester methodsFor: 'protected: destruct'!

{void} destruct
	super destruct.! !

!FebeTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartFebeTester: rcvr {Rcvr unused default: NULL}
	myKeyMaster _ NULL.
	myConnection _ NULL! !

!FebeTester methodsFor: 'creation'!

create
	super create.
	self restartFebeTester: NULL! !

!FebeTester methodsFor: 'accessing'!

{KeyMaster} keyMaster

	(myKeyMaster == NULL) ifTrue:
		[myConnection _ Connection make: XuServer.
		myKeyMaster := (myConnection bootHeaper cast: XuServer) publicKeyMaster].
	^myKeyMaster!

{void} killKeyMaster

	myConnection ~~ NULL ifTrue: [myConnection destroy]! !

!FebeTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference}
	self subclassResponsibility! !

!FebeTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartFebeTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FebeTester class
	instanceVariableNames: ''!

(FebeTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY boot ); add: #DEFERRED; yourself)!

!FebeTester class methodsFor: 'smalltalk: initialization'!

suppressInitTimeInherited!

suppressLinkTimeInherited! !