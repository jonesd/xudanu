'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:46 pm'!

MacListener subclass: #MacTCPRendezvousListener
	instanceVariableNames: '
		myPortNum {Int4}
		myListenTransporter {Transporter nocopy}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-macsrv'!
MacTCPRendezvousListener comment:
'This listener opens a TCP port to await a connection from someone else.  It will (currently) allow busy-waiting to determine if a connection has been made.'!

(MacTCPRendezvousListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!MacTCPRendezvousListener methodsFor: 'accessing'!

{BooleanVar} hasTraffic

	^ ((myListenTransporter basicCast: Transporter) basicCast: MacTCPTransporter) isActive!

{void} processInput

	"This method is called when the hasTraffic method returns TRUE.  It takes the transporter that has just connected to something and creates a new connection listener from it."
	
	((myListenTransporter basicCast: Transporter) basicCast: MacTCPTransporter) completeListen.
	MacTCPConnectionListener make: myListenTransporter.
	myListenTransporter _ MacTCPTransporter make: (myPortNum basicCast: #tcp.U.port var).! !

!MacTCPRendezvousListener methodsFor: 'creation'!

create: onPortNum {Int32}
	
	super create.
	myPortNum _ onPortNum.
	self restartMacTCPRendezvousListener: NULL!

{void} destruct
	myListenTransporter destroy.
	super destruct! !

!MacTCPRendezvousListener methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartMacTCPRendezvousListener: rcvr {Rcvr unused default: NULL}

	myListenTransporter _ MacTCPTransporter make: (myPortNum basicCast: #tcp.U.port var).
	self registerFor! !

!MacTCPRendezvousListener methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPortNum _ receiver receiveHeaper.
	self restartMacTCPRendezvousListener: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPortNum.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacTCPRendezvousListener class
	instanceVariableNames: ''!

(MacTCPRendezvousListener getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!MacTCPRendezvousListener class methodsFor: 'make'!

{MacListener} make: onPort {Int32}

	^ self create: onPort! !