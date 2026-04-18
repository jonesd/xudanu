'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:41 pm'!

XnReadStream subclass: #XnReadFile
	instanceVariableNames: 'myStream {FileStream}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(XnReadFile getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnReadFile methodsFor: 'accessing'!

{UInt8} getByte
	^myStream next uint8!

{void} putBack: c {UInt8}
	myStream skip: -1!

{void} refill! !

!XnReadFile methodsFor: 'creation'!

create: stream
	super create.
	myStream _ stream!

{void} destruct
	myStream close.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XnReadFile class
	instanceVariableNames: ''!

(XnReadFile getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnReadFile class methodsFor: 'creation'!

make: filename {char star}
	^self create: (Filename named: filename) readStream! !