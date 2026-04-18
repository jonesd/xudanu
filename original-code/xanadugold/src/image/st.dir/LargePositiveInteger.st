'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:14 pm'!

Integer variableByteSubclass: #LargePositiveInteger
	instanceVariableNames: ''
	classVariableNames: 'MaxHi '
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
LargePositiveInteger comment:
'Instances of class LargePositiveInteger represent positive large integers.  Nearly all behavior is handled in Integer.

Instance Variables:  *byte indexed*

Class Variables: 
	MaxHi	<SmallInteger>'!


!LargePositiveInteger methodsFor: 'arithmetic'!

* anInteger 
	"Answer the result of multiplying the receiver by the argument,  
	aNumber, where the result is an Integer."

	"Primitive is not implemented."

	<primitive: 29>
	^anInteger productFromInteger: self!

+ anInteger 
	"Answer the Integer result of adding the receiver to the argument."

	"Primitive is not implemented."

	<primitive: 21>
	^anInteger sumFromInteger: self!

- anInteger 
	"Answer an Integer that is the difference between the receiver and 
	anInteger."

	"Primitive is not implemented."

	<primitive: 22>
	^anInteger differenceFromInteger: self!

/ anInteger 
	"Answer the result of dividing receiver by the argument, anInteger, if  
	the division is exact.  Fail if the result is not a whole integer.  Fail if 
	the argument is 0."

	"Primitive is not implemented."

	<primitive: 30>
	^anInteger quotientFromInteger: self!

// anInteger 
	"Answer the result of dividing the receiver by the argument.  Round 
	the result down towards negative infinity to make it a whole integer."

	"Primitive is not implemented."

	<primitive: 32>
	^super // anInteger!

abs
	"Answer the receiver itself."

	^self!

negated
	"Answer a LargeNegativeInteger that is the negation of the receiver."

	^(self shallowCopy changeClassToThatOf: (LargeNegativeInteger basicNew: 0)) compressed!

quo: anInteger 
	"Answer the result of dividing the receiver by the argument.  
	Round the result down towards zero to make it a whole integer."

	"Primitive is not implemented."

	<primitive: 33>
	^anInteger quoFromInteger: self!

\\ anInteger 
	"Answer the remainder, rounded towards negative infinity, 
	of the receiver modulo the argument."

	"Primitive is not implemented."

	<primitive: 31>
	^super \\ anInteger! !

!LargePositiveInteger methodsFor: 'accessing'!

digitAt: index 
	"Answer the value of an indexable field in the receiver.  Fail if the 
	argument index is not an Integer or is out of bounds.  Essential. 
	See Object documentation whatIsAPrimitive."

	<primitive: 60>
	self digitLength < index
		ifTrue: [^0]
		ifFalse: [^self basicAt: index]!

digitAt: index put: value 
	"Store the argument value in the indexable field of the receiver  
	indicated by index.  Answer with the value that was stored.   
	Fail if the value is negative or is larger than 255. 
	Fail if the index is not an Integer or is out of bounds.  
	Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 61>
	^self basicAt: index put: value!

digitLength
	"Answer the number of bytes needed to represent the absolute value
	of the receiver."
	"Class is byte-indexed, so just answer the size."

	^self basicSize! !

!LargePositiveInteger methodsFor: 'testing'!

negative
	"Answer false that the receiver is not less than 0."

	^false!

positive
	"Answer true that the receiver is less than 0."

	^true! !

!LargePositiveInteger methodsFor: 'comparing'!

< anInteger 
	"Answer whether the receiver is less than the argument."

	"Primitive is not implemented."

	<primitive: 23>
	^anInteger lessFromInteger: self!

<= anInteger 
	"Answer whether the receiver is less than or equal to the argument."

	"Primitive is not implemented."

	<primitive: 25>
	^super <= anInteger!

= anInteger 
	"Answer whether the receiver is equal to the argument."

	"Primitive is not implemented."

	<primitive: 27>
	^super = anInteger!

> anInteger 
	"Answer whether the receiver is greater than the argument."

	"Primitive is not implemented."

	<primitive: 24>
	^super > anInteger!

>= anInteger 
	"Answer whether the receiver is greater than or equal to the   
	argument."

	"Primitive is not implemented."

	<primitive: 26>
	^super >= anInteger!

~= anInteger 
	"Answer whether the receiver is not equal to the argument."

	"Primitive is not implemented."

	<primitive: 28>
	^super ~= anInteger! !

!LargePositiveInteger methodsFor: 'truncation and round off'!

compressed
	"Answer the converted result of representing the receiver as a SmallInteger, 
	otherwise answer the receiver itself.

	This message is only used internally after arithmetic and bit operations, 
	and in a few external places that construct LargePositiveIntegers in 
	nonstandard ways."

	| size partial maxSize |
	size := self digitLength.
	size = 0 ifTrue: [^0].
	partial := self digitAt: size.
	partial = 0 ifTrue: 
			[[(size := size - 1) > 0 and: [(self digitAt: size) = 0]]
				whileTrue.
			^(self growTo: size) compressed].
	maxSize := SmallInteger maxBytes.
	(size < maxSize or: [size = maxSize and: [partial <= MaxHi]])
		ifTrue:
			["Convert back to a SmallInteger."
			[(size := size - 1) > 0]
				whileTrue:
					[partial := (partial bitShift: 8) + (self digitAt: size)].  "Can't overflow"
			^partial]!

lo3bytes

	^ ((self digitAt: 3) bitShift: 16) + ((self digitAt: 2) bitShift: 8) + (self digitAt: 1)! !

!LargePositiveInteger methodsFor: 'bit manipulation'!

bitAnd: anInteger 
	"Answer the logical AND of the twos-complement representation of   
	the receiver with the argument."

	"Primitive is not implemented."

	<primitive: 34>
	^super bitAnd: anInteger!

bitOr: anInteger 
	"Answer the logical OR of the twos-complement representation of the 
	receiver with the argument."

	"Primitive is not implemented."

	<primitive: 35>
	^super bitOr: anInteger!

bitShift: anInteger 
	"Answer an Integer whose value (in twos-complement representation)  
	is the receiver's value (in twos-complement representation) shifted 
	left by the number of bits indicated by the argument.  Negative    
	arguments shift right.  Zeros are shifted in from the right in left   
	shifts.  The sign bit is extended in right shifts."

	"Primitive is not implemented."

	<primitive: 37>
	^super bitShift: anInteger!

bitXor: anInteger 
	"Answer the logical XOR of the twos-complement representation of   
	the receiver with the argument."

	"Primitive is not implemented."

	<primitive: 36>
	^super bitXor: anInteger!

highBit
	"Answer the index of the high order bit of the binary representation of this 
	number."

	^self lastDigit highBit + (8 * (self digitLength - 1))! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LargePositiveInteger class
	instanceVariableNames: ''!


!LargePositiveInteger class methodsFor: 'class initialization'!

initialize
	"Compute the constant MaxHi.
	If a LargePositiveInteger is exactly SmallInteger maxBytes in size, 
	and its high-order byte does not exceed MaxHi, the number 
	should be a SmallInteger."

	"LargePositiveInteger initialize."

	MaxHi _ SmallInteger maxVal bitShift: SmallInteger maxBytes - 1 * -8! !

LargePositiveInteger initialize!
