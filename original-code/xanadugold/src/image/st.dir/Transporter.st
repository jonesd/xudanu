'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:39 pm'!

Heaper subclass: #Transporter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(Transporter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Transporter methodsFor: 'accessing'!

{XnReadStream} readStream
	
	self subclassResponsibility!

{XnWriteStream} writeStream
	
	self subclassResponsibility! !

!Transporter methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Transporter class
	instanceVariableNames: ''!

(Transporter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Transporter class methodsFor: 'pseudo constructors'!

make: host {char star} with: port {UInt32}
'
#ifdef HIGHC
	BLAST(NOT_YET_IMPLEMENTED);
	return NULL; // fodder
#else
	return SocketTransporter::make (host, port);
#endif' translateOnly.
	[^SocketTransporter make: host with: port] smalltalkOnly! !