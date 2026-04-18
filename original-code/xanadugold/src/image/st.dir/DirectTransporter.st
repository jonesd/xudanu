'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:09 pm'!

StreamTransporter subclass: #DirectTransporter
	instanceVariableNames: '
		myBuddy {DirectTransporter}
		myReceivedPackets {IntegerTable}
		mySemaphore {Semaphore}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(DirectTransporter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DirectTransporter methodsFor: 'private: accessing'!

{void} receivePacket: packet {UInt1Array} with: count {UInt4}

	myReceivedPackets atInt: myReceivedPackets highestIndex + 1 store: packet.
	mySemaphore v!

{void} writePacketTo: packet {UInt1Array} with: count {UInt4} with: buddy {DirectTransporter}
	
	myBuddy receivePacket: packet with: count! !

!DirectTransporter methodsFor: 'accessing'!

{DirectTransporter} buddy
	myBuddy == NULL ifTrue: [myBuddy _ DirectTransporter make: self].
	^myBuddy!

{UInt1Array} readPacket
	| packet {UInt1Array} |
	mySemaphore p.
	packet _ myReceivedPackets intFetch: myReceivedPackets lowestIndex.
	myReceivedPackets remove: myReceivedPackets lowestIndex.
	^packet!

{void} writePacket: packet {UInt1Array} with: count {UInt4}
	
	self writePacketTo: packet with: count with: myBuddy! !

!DirectTransporter methodsFor: 'creation'!

create
	| theSharedArray {UInt1Array} |
	theSharedArray _ UInt8Array make: 5000.
	super create: (DirectReadStream make: theSharedArray with: Int40 with: 5000) 
		with: (DirectWriteStream make: theSharedArray with: Int40 with: 5000).
	myBuddy _ NULL.
	myReceivedPackets _ IntegerTable make.
	mySemaphore _ Sema4 make: IntegerVar0.!

create: buddy {DirectTransporter}
	| theSharedArray {UInt1Array} |
	theSharedArray _ UInt8Array make: 5000.
	super create: (XnReadStream make: theSharedArray with: Int40 with: 5000) 
		with: (XnWriteStream make: theSharedArray with: Int40 with: 5000).
	myBuddy _ buddy.
	myReceivedPackets _ IntegerTable make.
	mySemaphore _ Sema4 make: IntegerVar0.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DirectTransporter class
	instanceVariableNames: ''!

(DirectTransporter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DirectTransporter class methodsFor: 'pseudo-constructor'!

make 
	^self create!

make: buddy {DirectTransporter}
	^self create: buddy! !