'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:57 pm'!

Connection subclass: #ClientConnection
	instanceVariableNames: '
		myTransporter {Transporter}
		myCategory {Category}
		myHeaper {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
ClientConnection comment:
'This represents a connection across a wire. When the connection is destroyed, it destroys the Transporter and closes the wire level connection.

This class also plays middleman for Cobblers.  Clients supply the transporter and the name of the cobbler they want to use.  Servers just supply the transporter, and the middleman will read a ;cobbler name from the wire, and use that cobbler to decide on the stream protocol and cookbook for the connection.  Finally, it will build the connection and return it.'!

(ClientConnection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #SMALLTALK.ONLY; yourself)!

!ClientConnection methodsFor: 'accessing'!

{Category} bootCategory

	^myCategory!

{Heaper} bootHeaper

	^myHeaper! !

!ClientConnection methodsFor: 'creation'!

create: tport {Transporter} with: cat {Category} with: bootHeaper {Heaper}
	
	super create.
	myTransporter _ tport.
	myCategory _ cat.
	myHeaper _ bootHeaper!

{void} destruct

	(Heaper isDestructed: myTransporter) ifFalse:
		[myTransporter destroy].
	super destruct.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClientConnection class
	instanceVariableNames: ''!

(ClientConnection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #SMALLTALK.ONLY; yourself)!

!ClientConnection class methodsFor: 'creation'!

{Connection} make: tport {Transporter} with: cat {Category} with: specialist {RPCSpecialist}
	"Actually create the connection now that we have enough information."
	^self create: tport with: cat with: specialist receiveBootHeaper! !