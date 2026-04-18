'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:38 pm'!

IntegerArray variableByteSubclass: #WordArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Arrayed'!
WordArray comment:
'Elements of a WordArray can only be integers between 0 and 65535.

Instance Variables: *byte indexed*'!



!WordArray methodsFor: 'initialize-release'!

fromByteStream: aStream 
	"Initialize the array of bits by reading integers from the Stream, aStream."

	| high low |
	1 to: self size do: 
		[:i | 
		high _ aStream next asInteger. 
					"be cautious, it may be a char"
		low _ aStream next asInteger.
		self at: i put: (high bitShift: 8) + low]! !

!WordArray methodsFor: 'filing'!

toStream: aStream 
	"Store the array of bits onto the Stream, aStream."

	1 to: self size do:  
		[:i | 
		aStream nextPut: ((self at: i) bitShift: -8).
		aStream nextPut: ((self at: i) bitAnd: 255)]! !

!WordArray methodsFor: 'accessing'!

at: index
	"Override this message to access 16-bit words."
	| byteIndex |
	byteIndex _ index * 2.
	^((super at: byteIndex - self byteOrder) bitShift: 8) + (super at: byteIndex -1 + self byteOrder)!

at: index put: word
	"Override this message to access 16-bit words."
	| byteIndex |
	byteIndex _ index * 2.
	super at: byteIndex - self byteOrder put: (word bitShift: -8).
	super at: byteIndex - 1 + self byteOrder put: (word bitAnd: 255).
	^word!

replaceFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces elements from start to stop in the 
	receiver starting at index, repStart, in the collection, replacement.  
	Answer the 
	receiver."

	(replacement isKindOf: WordArray)
		ifTrue: [self primReplaceFrom: start 
					to: stop 
					with: replacement 
					startingAt: repStart]
		ifFalse: [super replaceFrom: start 
					to: stop 
					with: replacement 
					startingAt: repStart]!

reverseByteOrder
	"Swap byte order when booting up on a different-endian
	machine than the image was saved on"

	| t |
	1 to: self size * 2 by: 2 do:
		[ :i |	t _ self basicAt: i.
				self basicAt: i put: (self basicAt: i+1).
				self basicAt: i+1 put: t	]!

size
	"Override this message to access 16-bit words."
	^super size // 2! !

!WordArray methodsFor: 'converting'!

asWordArray
	"Answer the receiver."

	^self! !

!WordArray methodsFor: 'private: private'!

byteOrder
	UninterpretedBytes isBigEndian ifTrue: [^1].
	^0!

primReplaceFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the collection, replacement.  Answer the
	receiver.  No range checks are performed - this may be primitively implemented."

	<primitive: 414>
	super
		replaceFrom: start 
		to: stop 
		with: replacement 
		startingAt: repStart! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WordArray class
	instanceVariableNames: ''!



!WordArray class methodsFor: 'instance creation'!

new: size
	^super basicNew: size * 2! !