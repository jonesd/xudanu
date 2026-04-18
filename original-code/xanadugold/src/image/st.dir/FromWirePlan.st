'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:59 pm'!

BootPlan subclass: #FromWirePlan
	instanceVariableNames: '
		myCategory {Category}
		myWirer {Electrician}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
FromWirePlan comment:
'Instances know how to create a connection over a transporter, and get the bootHeaper remotely.'!

(FromWirePlan getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!FromWirePlan methodsFor: 'accessing'!

{Category} bootCategory
	^myCategory!

{Connection} connection
	"Return the object representing the connection.  This gives the client
	 a handle by which to terminate the connection."
	
	| tport {Transporter} cobbler {Cobbler} |
	tport _ myWirer makeTransporter.
	cobbler _ Cobbler make: tport with: 'insistent'.
	^cobbler initiateConnection: tport with: myCategory! !

!FromWirePlan methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCategory _ receiver receiveHeaper.
	myWirer _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCategory.
	xmtr sendHeaper: myWirer.! !