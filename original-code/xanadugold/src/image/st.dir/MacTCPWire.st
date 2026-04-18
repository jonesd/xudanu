'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:45 pm'!

Electrician subclass: #MacTCPWire
	instanceVariableNames: '
		myHostName {char star}
		myHostPort {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-mactwire'!
MacTCPWire comment:
'a wire for creating a connection with MacTCP to a tcp/ip host'!

(MacTCPWire getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!MacTCPWire methodsFor: 'creation'!

create: hostName {char star} with: port {Int32}
	super create.
	myHostPort _ port.
	myHostName _ hostName! !

!MacTCPWire methodsFor: 'accessing'!

{Transporter} makeTransporter
	^MacTCPTransporter make: myHostName with: myHostPort! !

!MacTCPWire methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myHostName _ receiver receiveString.
	myHostPort _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendString: myHostName.
	xmtr sendHeaper: myHostPort.! !