'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:35 pm'!

IntegerArray variableByteSubclass: #ByteArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Arrayed'!
ByteArray comment:
'Elements of a ByteArray can only be integers between 0 and 255.  

The access messages at: and at:put: are handled primitively in class Object.

Instance Variables: *byte indexed*'!


!ByteArray methodsFor: 'accessing'!

byteAt: index 
	"Answer the byte at the given index."

	^self basicAt: index!

byteAt: index put: aByte 
	"Store a byte at the given index."

	^self basicAt: index put: aByte!

doubleWordAt: i 
	"Answer the value of the double word (4 bytes) starting at byte index i."

	| b0 b1 b2 w |
	"Primarily for reading socket #s in Pup headers"
	b0 _ self at: i.  
	b1 _ self at: i+1.  
	b2 _ self at: i+2.  
	w _ self at: i+3.
	"Following sequence minimizes LargeInteger arithmetic for small results."
	b2=0 ifFalse: [w _ (b2 bitShift: 8) + w].
	b1=0 ifFalse: [w _ (b1 bitShift: 16) + w].
	b0=0 ifFalse: [w _ (b0 bitShift: 24) + w].
	^w!

doubleWordAt: i put: value 
	"Set the value of the double word (4 bytes) starting at byte index i."

	| w |
	"Primarily for setting socket #s in Pup headers"
	w _ value truncated.
	self at: i put: (w digitAt: 4).
	self at: i + 1 put: (w digitAt: 3).
	self at: i + 2 put: (w digitAt: 2).
	self at: i + 3 put: (w digitAt: 1)!

replaceBytesFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the collection, replacement.  Answer the
	receiver."

	<primitive: 559>
	| repOff |
	repOff _ repStart - start.
	(self == replacement and: [repStart < start])
		ifTrue:	["Replacement would be overwritten; use reverse order"
				stop to: start by: -1 do:
					[ :i |	self byteAt: i put: (replacement byteAt: repOff + i)]]
		ifFalse:	[start to: stop do:
					[ :i |	self byteAt: i put: (replacement byteAt: repOff + i)]]!

sizeInBytes
	"Answer how many bytes the receiver contains."

	^self size!

wordAt: i 
	"Answer the value of the word (2 bytes) starting at index i."

	| j |
	j _ i + i.
	^((self at: j - 1) bitShift: 8) + (self at: j)!

wordAt: i put: v 
	"Set the value of the word (2 bytes) starting at index i."

	| j |
	j _ i + i.
	self at: j - 1 put: ((v bitShift: -8) bitAnd: 8r377).
	self at: j put: (v bitAnd: 8r377)! !

!ByteArray methodsFor: 'converting'!

asByteArray
	"Answer the receiver itself."

	^self!

asByteString
	"Answer an instance of ByteString which is = to self."

	^(ByteString new: self size)
		replaceFrom: 1
		to: self size
		withByteArray: self
		startingAt: 1! !

!ByteArray methodsFor: 'fileIn/Out'!

storeBinaryOn: stream

	stream storeRecordOfClass: self class.
	stream nextPut: self size.
	stream storeBytes: self! !

!ByteArray methodsFor: 'private: private'!

replaceFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the collection, replacement.  Answer the
	receiver."

	<primitive: 105>
	^super replaceFrom: start to: stop with: replacement startingAt: repStart! !

!ByteArray methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance 
	variable. Object>>deepCopy would do much unneeded work; since
	the instance contains only bits, just do a copy."

	^self copy! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ByteArray class
	instanceVariableNames: ''!


!ByteArray class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag
	"Answer object appearing next in stream."

	| size bytes |
	size _ stream next.  "integer"
	bytes _ stream readBytes: self size: size.
	stream register: bytes id: tag.
	^bytes! !