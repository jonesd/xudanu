'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:17 pm'!

Portal subclass: #PacketPortal
	instanceVariableNames: '
		myReadStream {XnReadStream}
		myWriteStream {XnWriteStream}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(PacketPortal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PacketPortal methodsFor: 'protected: creation'!

create
	super create.
	myReadStream _ XnBufferedReadStream create: self.
	myWriteStream _ XnBufferedWriteStream create: self.!

create: readStr {XnReadStream} with: writeStr {XnWriteStream}
	super create.
	myReadStream _ readStr.
	myWriteStream _ writeStr! !

!PacketPortal methodsFor: 'accessing'!

{XnReadStream} readStream
	
	^myReadStream!

{XnWriteStream} writeStream
	
	^myWriteStream! !

!PacketPortal methodsFor: 'internal'!

{void} flush
	"Make sure the bits go out."
	
	self subclassResponsibility!

{UInt8Array} readBuffer
	"Return a buffer of a size that the unerlying transport layer likes."
	
	self subclassResponsibility!

{Int32} readPacket: buffer {UInt8Array} with: count {Int32}
	
	self subclassResponsibility!

{UInt8Array} writeBuffer
	"Return a buffer of a size that the unerlying transport layer likes."
	
	self subclassResponsibility!

{void} writePacket: packet {UInt8Array} with: count {Int32}
	
	self subclassResponsibility! !