'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:35 pm'!

Transporter subclass: #StreamTransporter
	instanceVariableNames: '
		myReadStream {XnReadStream}
		myWriteStream {XnWriteStream}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(StreamTransporter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!StreamTransporter methodsFor: 'protected: creation'!

create
	super create.
	myReadStream _ TPortReadStream create: self.
	myWriteStream _ TPortWriteStream create: self.!

create: readStr {XnReadStream} with: writeStr {XnWriteStream}
	super create.
	myReadStream _ readStr.
	myWriteStream _ writeStr! !

!StreamTransporter methodsFor: 'accessing'!

{UInt8Array} readPacket
	
	self subclassResponsibility!

{XnReadStream} readStream
	
	^myReadStream!

{void} writePacket: packet {UInt8Array} with: count {UInt32}
	
	self subclassResponsibility!

{XnWriteStream} writeStream
	
	^myWriteStream! !