'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:41 pm'!

BootPlan subclass: #FeWorksBootMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fbtest'!

(FeWorksBootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!FeWorksBootMaker methodsFor: 'accessing'!

{Category} bootCategory
	^ FeServer!

{Connection} connection
	| conn {Connection} |
	conn _ Connection make: FeServer.
	^ conn
	"^NestedConnection make: self bootCategory with: (PrGateKeeper make: (conn bootHeaper cast: FeGateKeeper)) with: conn"! !

!FeWorksBootMaker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !