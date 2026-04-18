'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:18 pm'!

Heaper subclass: #Portal
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(Portal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Portal methodsFor: 'accessing'!

{XnReadStream} readStream
	
	self subclassResponsibility!

{XnWriteStream} writeStream
	
	self subclassResponsibility! !

!Portal methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Portal class
	instanceVariableNames: ''!

(Portal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Portal class methodsFor: 'pseudo constructors'!

make: host {char star} with: port {UInt32}

	^SocketPortal make: host with: port! !