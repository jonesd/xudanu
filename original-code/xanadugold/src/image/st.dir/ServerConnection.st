'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:01 pm'!

Connection subclass: #ServerConnection
	instanceVariableNames: '
		myTransporter {Transporter}
		mySubConnection {Connection}
		myRPCSpecialist {RPCSpecialist}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
ServerConnection comment:
'Instances represent the server side of a connection across the wire.  The server will get the bootObject through its bootPlan table, so this connection needs to hold onto the connection used to get the bootHeaper inside the server.  When the comm connection is destroyed, so will the local connection'!

(ServerConnection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #SMALLTALK.ONLY; yourself)!

!ServerConnection methodsFor: 'creation'!

create: tport {Transporter} with: sub {Connection} with: specialist {RPCSpecialist}
	
	super create.
	myTransporter _ tport.
	mySubConnection _ sub.
	myRPCSpecialist _ specialist.!

{void} destruct

	myTransporter destroy.
	mySubConnection destroy.
	super destruct.! !

!ServerConnection methodsFor: 'accessing'!

{Category} bootCategory

	^mySubConnection bootCategory!

{Heaper} bootHeaper

	^mySubConnection bootCategory!

{RPCSpecialist} specialist

	^myRPCSpecialist.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ServerConnection class
	instanceVariableNames: ''!

(ServerConnection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; add: #SMALLTALK.ONLY; yourself)!

!ServerConnection class methodsFor: 'creation'!

{Connection} make: tport {Transporter} 
	| cobbler {Cobbler} |
	cobbler _ Cobbler make: tport.
	^cobbler acceptConnection: tport!

{Connection} make: tport {Transporter} with: cat {Category} with: specialist {RPCSpecialist}
	| sub {Connection} |
	sub _ Connection make: cat.
	specialist sendBootHeaper: sub bootHeaper.
	^self create: tport with: sub with: specialist.! !