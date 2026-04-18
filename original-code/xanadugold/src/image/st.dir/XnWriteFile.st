'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:42 pm'!

XnWriteStream subclass: #XnWriteFile
	instanceVariableNames: 'myStream {FileStream}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(XnWriteFile getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnWriteFile methodsFor: 'accessing'!

{void} flush

	myStream flush!

{void} putByte: byte {UInt32}
	
	myStream nextPut: (Character make: byte)!

{void} putData: array {UInt8Array}
	| class |
	class _ array class.
	array changeClassToThatOf: String new.
	myStream nextPutAll: array.
	array changeClassToThatOf: class basicNew!

{void} putStr: string {char star}
	myStream nextPutAll: string.! !

!XnWriteFile methodsFor: 'creation'!

create: stream
	super create.
	myStream _ stream.
	myStream lineEndTransparent!

{void} destruct
	myStream close.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XnWriteFile class
	instanceVariableNames: ''!

(XnWriteFile getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnWriteFile class methodsFor: 'creation'!

make: filename {char star}
	^self create: (Filename named: filename) writeStream! !