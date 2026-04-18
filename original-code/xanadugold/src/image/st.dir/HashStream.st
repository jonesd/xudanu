'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:45 pm'!

XnWriteStream subclass: #HashStream
	instanceVariableNames: 'myHash {UInt32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(HashStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!HashStream methodsFor: 'create'!

create
	super create.
	myHash := UInt32Zero! !

!HashStream methodsFor: 'accessing'!

{void} flush!

{UInt32} hash
	"The accumulated hash"
	^myHash!

{void} putByte: byte {UInt32}
	myHash _ FHash fastHash.UInt32: (myHash bitXor: byte)!

{void} putData: array {UInt8Array}

	myHash := myHash bitXor: array contentsHash!

{void} putStr: string {char star}
	myHash _ myHash bitXor: (FHash fastHash.String: string)! !

!HashStream methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HashStream class
	instanceVariableNames: ''!

(HashStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!HashStream class methodsFor: 'creation'!

{XnWriteStream} make
	^self create! !