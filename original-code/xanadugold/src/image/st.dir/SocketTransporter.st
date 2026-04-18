'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:33 pm'!

StreamTransporter subclass: #SocketTransporter
	instanceVariableNames: 'mySocketFD {int}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(SocketTransporter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SocketTransporter methodsFor: 'protected: creation'!

create: socketFD {int}

	super create.
	mySocketFD _ socketFD!

{void} destruct

	mySocketFD close.
	super destruct! !

!SocketTransporter methodsFor: 'accessing'!

{UInt8Array} readPacket
	"receive a buffer of data"
	
	| recvdSize {int} recvBuf {char star} |
	
	recvdSize _ Integer readFrom: (ReadStream on: (mySocketFD next: 8)).
	recvBuf _ mySocketFD next: recvdSize.
	
	^(PrimSpec uInt8 arrayFromBuffer: recvdSize with: recvBuf) cast: UInt8Array!

{void} writePacket: packet {UInt8Array} with: count {UInt32}
	"send a buffer of data"
	
	| contents {char star} |
	contents _ packet asString copyFrom: 1 to: count.
	
	count printString size + 1 to: 8 do: [ :i {UInt8} |
		mySocketFD nextPut: $0].
	count printOn: mySocketFD.
	
	mySocketFD nextPutAll: contents! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SocketTransporter class
	instanceVariableNames: ''!

(SocketTransporter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SocketTransporter class methodsFor: 'pseudo constructors'!

make: socketFD {int as: Stream}
	^self create: socketFD.!

make: hostName {char star} with: port {UInt32}
	"SocketTransporter make: 'vlad' with: 16rcafe"
	"I suspect this doesn't do a close under some situations where it should (and 
	where the old code did)."
	
	^self create: (UnixSocketAccessor 
		newTCPclientToHost: hostName port: port) readAppendStream! !