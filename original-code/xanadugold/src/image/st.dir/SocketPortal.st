'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:24 pm'!

PacketPortal subclass: #SocketPortal
	instanceVariableNames: '
		mySocketFD {int}
		myReview {WriteStream}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(SocketPortal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SocketPortal methodsFor: 'accessing'!

{void} flush
	"Make sure the bits go out."
	
	mySocketFD commit!

{UInt8Array} readBuffer
	"Return a buffer of a size that the unerlying transport layer likes."
	
	 [^UInt8Array make: 512] smalltalkOnly.
	 
	  ^UInt8Array make: 512 with: ['(void *)falloc(512)' translateOnly]   translateOnly.!

{Int32} readPacket: buffer {UInt8Array} with: count {Int32}
	"receive data into a buffer"
	
	| result {Int32} |
	[(myWriteStream instVarAt: 3) ~~ 0 ifTrue: [Heaper BLAST: #NeedToFlush]] smalltalkOnly.
	result _ mySocketFD readInto: buffer
		startingAt: 1
		for: count
		untilFalse: [:n {IntegerVar} | false].
	myReview nextPutAll: ((buffer copy: result) changeClassToThatOf: ByteArray new).
	^result!

{UInt8Array} writeBuffer
	"Return a buffer of a size that the unerlying transport layer likes."
	
	 ^UInt8Array make: 512!

{void} writePacket: packet {UInt8Array} with: count {Int32}
	"send a buffer of data"
	
	count > 0 ifTrue:
		[self thingToDo. "make asynchronous write"
		mySocketFD writeFrom: packet startingAt: 1 for: count.
		mySocketFD commit]! !

!SocketPortal methodsFor: 'protected: creation'!

create: socketFD {int}

	super create.
	mySocketFD _ socketFD.
	myReview _ (Filename named: 'review.txt') writeStream binary!

{void} destruct

	mySocketFD close.
	myReview close.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SocketPortal class
	instanceVariableNames: ''!

(SocketPortal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SocketPortal class methodsFor: 'creation'!

{PacketPortal} make: socketFD {int}
	^self create: socketFD.!

{PacketPortal} make: hostName {char star} with: port {UInt32}
	"SocketTransporter make: 'vlad' with: 16rcafe"
	"I suspect this doesn't do a close under some situations where it should (and 
	where the old code did)."
	
	^self create: (UnixSocketAccessor
		newTCPclientToHost: hostName port: port)! !