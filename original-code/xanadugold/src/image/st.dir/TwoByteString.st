'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:34 pm'!

String variableByteSubclass: #TwoByteString
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Text'!
TwoByteString comment:
'Instances of class TwoByteString are indexed collections of Characters.  TwoByteStrings store characters as pairs of bytes: the access protocol translates between these and real Character objects.

Instance Variables: *byte indexed*'!


!TwoByteString methodsFor: 'accessing'!

at: index
	<primitive: 412>

	| byteIndex code |
	byteIndex _ index * 2.
	code _ ((super at: byteIndex - self byteOrder)
				bitShift: 8)
				+ (super at: byteIndex - 1 + self byteOrder).
	^Character value: code!

at: index put: aCharacter
	<primitive: 413>

	(aCharacter isKindOf: Character)
		ifTrue: 
			[| byteIndex code |
			byteIndex _ index * 2.
			code _ aCharacter asciiValue.
			super at: byteIndex - self byteOrder put: (code bitShift: -8).
			super at: byteIndex - 1 + self byteOrder put: (code bitAnd: 255).
			^aCharacter]
		ifFalse: [self error: 'Strings only store Characters']!

size
	"Override this message to access 16-bit units."
	^super size // 2! !

!TwoByteString methodsFor: 'comparing'!

= aString 
	"Answer whether the argument is a kind of String,
	and the receiver's size is the same as the receiver's size,
	and each of the receiver's elements equals the corresponding
	element of aString."

	<primitive: 415>
	aString isString ifFalse: [^false].
	self size = aString size ifFalse: [^false].
	^super = aString! !

!TwoByteString methodsFor: 'converting'!

asIntegerArray
	"Answer an instance of WordArray whose elements
	are the character codes of the receiver."
 
	^self asWordArray: -1!

asTwoByteString
	"Answer the receiver."

	^self! !

!TwoByteString methodsFor: 'private: private'!

byteOrder
	UninterpretedBytes isBigEndian ifTrue: [^1].
	^0!

primReplaceFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the collection, replacement.  Answer the
	receiver.  No range checks are performed - this may be primitively implemented."
	<primitive: 414>
	self collectionReplaceFrom: start to: stop with: replacement startingAt: repStart! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TwoByteString class
	instanceVariableNames: ''!


!TwoByteString class methodsFor: 'instance creation'!

new: size
	^self basicNew: size * 2! !