'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:42 pm'!

Heaper subclass: #XnWriteStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(XnWriteStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!XnWriteStream methodsFor: 'accessing'!

{void} flush

	self subclassResponsibility!

{void} putByte: byte {UInt32}
	"These are UInt32 to avoid an unneeded mask op that the compiler generates"
	self subclassResponsibility!

{void} putData: array {UInt8Array}
	self subclassResponsibility!

{void} putStr: string {char star}
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XnWriteStream class
	instanceVariableNames: ''!

(XnWriteStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!XnWriteStream class methodsFor: 'creation'!

make: array {UInt8Array}
	"Make a stream which writes into the given array"
	^WriteArrayStream create: array!

make: dataP {UInt8 star} with: start {Int32} with: count {Int32}
	^WriteMemStream make: dataP with: start with: count! !