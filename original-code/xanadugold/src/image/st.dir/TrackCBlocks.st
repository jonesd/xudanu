'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:52 pm'!

BootPlan subclass: #TrackCBlocks
	instanceVariableNames: 'myBootPlan {BootPlan}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(TrackCBlocks getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!TrackCBlocks methodsFor: 'accessing'!

{Category} bootCategory

	^myBootPlan bootCategory!

{Connection} connection
	"Return the object representing the connection. This gives the client a handle by 
	which to terminate the connection."
	
	| result {Connection} |
	result _ myBootPlan connection.
	CurrentPacker fluidSet: (CBlockTrackingPacker make: CurrentPacker fluidGet).
	^result! !

!TrackCBlocks methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myBootPlan _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myBootPlan.! !