'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:30 pm'!

String variableByteSubclass: #ByteString
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Text'!
ByteString comment:
'Instances of class ByteString are indexed collections of Characters. ByteStrings store characters as bytes.  The access protocol translates between these and real Character objects.

Instance Variables: *byte indexed*'!


!ByteString methodsFor: 'accessing'!

at: index 
	"Answer the Character stored in the field of the receiver indexed by the 
	argument.  Fail if the index argument is not an Integer or is out of bounds.  
	Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 63>
	^Character value: (super at: index)!

at: index put: aCharacter 
	"Store the Character in the field of the receiver indicated by the index.  Fail if the 
	index is not an Integer or is out of bounds, or if the argument is not a Character,
	or if the code of aCharacter does not fit in one byte.  
	Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 64>
	(aCharacter isKindOf: Character)
		ifTrue:
			[aCharacter asciiValue < 256
				ifTrue: [super at: index put: aCharacter asciiValue]
				ifFalse:
					[| two |
					two _ self asTwoByteString.
					two at: index put: aCharacter.
					self become: two].
			^aCharacter]
		ifFalse: [self error: 'Strings only store Characters']!

byteAt: index 
	"Answer the byte at the given index."

	^self basicAt: index!

byteAt: index put: aByte
	"Store a byte at the given index."

	^self basicAt: index put: aByte!

nextIndexOf: anElement from: startIndex to: stopIndex
	"Answer the next index of anElement within the receiver between startIndex and stopIndex.
	 If the receiver does not contain anElement, answer nil"

	<primitive: 418>
	^super nextIndexOf: anElement from: startIndex to: stopIndex!

prevIndexOf: anElement from: startIndex to: stopIndex
	"Answer the previous index of anElement within the receiver between startIndex and stopIndex
	 working backwards through the receiver.  If the receiver does not contain anElement, answer nil"

	<primitive: 419>
	^super prevIndexOf: anElement from: startIndex to: stopIndex!

replaceFrom: start to: stop withByteArray: aByteArray startingAt: repStart
	"This destructively replaces elements from start to stop in the receiver
	starting at index, repStart, in the byte array, aByteArray.  Answer the
	receiver."

	^super replaceFrom: start to: stop withIntegerArray: aByteArray startingAt: repStart!

size
	"Answer the number of indexable fields in the receiver.  This value is the 
	same as the largest legal subscript.  Essential.  See Object documentation
	whatIsAPrimitive."

	<primitive: 62>
	^super size!

sizeInBytes
	"Answer how many bytes the receiver contains."

	^self size! !

!ByteString methodsFor: 'comparing'!

= aString 
	"Answer whether aString isKindOf: String,
	and the receiver's size is the same as aString's size,
	and each of the receiver's elements equals
	the corresponding element of aString"

	<primitive: 223>
	aString isString ifFalse: [^false].
	self size = aString size ifFalse: [^false].
	^super = aString! !

!ByteString methodsFor: 'converting'!

asByteString
	"Answer the receiver."

	^self!

asIntegerArray
	"Answer an instance of a kind of IntegerArray whose elements
	are the elements of the receiver transformed to integers."

	^self asByteArray! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ByteString class
	instanceVariableNames: ''!


!ByteString class methodsFor: 'instance creation'!

new: size
	^self basicNew: size! !