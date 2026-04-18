'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:35 pm'!

Symbol variableByteSubclass: #TwoByteSymbol
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Text'!
TwoByteSymbol comment:
'Instances of class TwoByteSymbol are uniquely stored, immutable, indexed collections of Characters.  See Symbol for more information.  TwoByteSymbols store characters as pairs of bytes: the access protocol translates between these and real Character objects.

Instance Variables: *byte indexed*'!


!TwoByteSymbol methodsFor: 'accessing'!

at: index
	<primitive: 412>

	| byteIndex code |
	byteIndex _ index * 2.
	code _ ((super at: byteIndex - self byteOrder)
				bitShift: 8)
				+ (super at: byteIndex - 1 + self byteOrder).
	^Character value: code!

size
	"Override this message to access 16-bit units."
	^super size // 2! !

!TwoByteSymbol methodsFor: 'private: private'!

byteOrder
	UninterpretedBytes isBigEndian ifTrue: [^1].
	^0!

species
	^TwoByteString!

string: aString 
	self size = aString size ifFalse: [self error: 'aString size must be equal to receiver size'].
	1 to: aString size do: 
		[:index | 
		| byteIndex code |
		byteIndex _ index * 2.
		code _ (aString at: index) asciiValue.
		super basicAt: byteIndex - self byteOrder put: (code bitShift: -8).
		super basicAt: byteIndex - 1 + self byteOrder put: (code bitAnd: 255)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TwoByteSymbol class
	instanceVariableNames: ''!


!TwoByteSymbol class methodsFor: 'instance creation'!

new: size
	^self basicNew: size * 2! !