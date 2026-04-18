'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:33 pm'!

Electrician subclass: #SocketWire
	instanceVariableNames: '
		myHostName {char star}
		myPort {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(SocketWire getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SocketWire methodsFor: 'accessing'!

{Transporter} makeTransporter
	^SocketTransporter make: myHostName with: myPort! !

!SocketWire methodsFor: 'creation'!

create: hostName {char star} with: port {Int32}
	super create.
	myPort _ port.
	myHostName _ hostName.! !

!SocketWire methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myHostName _ receiver receiveString.
	myPort _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendString: myHostName.
	xmtr sendInt32: myPort.! !