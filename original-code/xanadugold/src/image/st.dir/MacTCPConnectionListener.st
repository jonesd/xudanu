'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:46 pm'!

MacListener subclass: #MacTCPConnectionListener
	instanceVariableNames: '
		myTransporter {Transporter}
		myConnection {Connection}
		myRPCSpecialist {RPCSpecialist}
		mySession {Session}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-macsrv'!
MacTCPConnectionListener comment:
'This listener is created by a MacTCPRendezvousListener when a connection request comes in.  This listener is then used to communicate with the other end.'!

(MacTCPConnectionListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!MacTCPConnectionListener methodsFor: 'accessing'!

{BooleanVar} hasTraffic

	^ ((myTransporter basicCast: Transporter) basicCast: MacTCPTransporter) isActive!

{void} processInput

	CurrentListener _ self.
	Listener problems.MacTCPERRS
		handle: [:ex |
			["cxx: cerr << ""Connection Terminated\n"";"] translateOnly.
			CurrentListener _ NULL.
			self destroy.
			^ VOID]
		do: [myRPCSpecialist waitForAndProcessMessage].
	CurrentListener _ NULL.! !

!MacTCPConnectionListener methodsFor: 'creation'!

create: onTransporter {Transporter}

	super create.
	self hack. "Recreate Sessions - c.f. IPConnectionListener create"
	mySession _ Session create: NULL.
	CurrentListener _ self.
	myTransporter _ onTransporter.
	myConnection _ ServerConnection make: myTransporter.
	myRPCSpecialist _ (myConnection cast: ServerConnection) specialist.
	self registerFor.
	CurrentListener _ NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacTCPConnectionListener class
	instanceVariableNames: ''!

(MacTCPConnectionListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!MacTCPConnectionListener class methodsFor: 'make'!

{MacListener} make: onTransporter {Transporter}

	^ self create: onTransporter! !