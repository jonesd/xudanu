'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:47 pm'!

StreamTransporter subclass: #MacTCPTransporter
	instanceVariableNames: 'myStreamPtr {int}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-mactcpt'!
MacTCPTransporter comment:
'This is a non-functional class present to reflect the actual implementation in platform mac'!

(MacTCPTransporter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!MacTCPTransporter methodsFor: 'accessing'!

{void} completeListen!

{BooleanVar} isActive!

{void} startListen! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MacTCPTransporter class
	instanceVariableNames: ''!

(MacTCPTransporter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!MacTCPTransporter class methodsFor: 'creation'!

make: portNum {short}
	^ self create: portNum!

make: hostName {Character vector} with: portNum {short}
	^ self create: hostName with: portNum! !