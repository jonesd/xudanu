'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:13 pm'!

Integer variableByteSubclass: #LargeNegativeInteger
	instanceVariableNames: ''
	classVariableNames: 'MinHi '
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
LargeNegativeInteger comment:
'Instances of class LargeNegativeInteger represent negative large integers.  Nearly all behavior is handled in Integer.

Instance Variables:  *byte indexed*

Class Variables: 
	MinHi	<SmallInteger>'!


!LargeNegativeInteger methodsFor: 'arithmetic'!

abs
	"Answer the receiver negated."

	^self negated!

negated
	"Answer a LargePositiveInteger that is the negation of the receiver."

	^self shallowCopy changeClassToThatOf: (LargePositiveInteger basicNew: 0)! !

!LargeNegativeInteger methodsFor: 'accessing'!

digitAt: index 
	"Answer the value of an indexable field in the receiver.  Fail if  
	the argument index is not an Integer or is out of bounds.  Essential.  
	See Object documentation whatIsAPrimitive."

	<primitive: 60>
	self digitLength < index
		ifTrue: [^0]
		ifFalse: [^self basicAt: index]!

digitAt: index put: value 
	"Store the argument value in the indexable field of the receiver  
	indicated by index.  Answer with the value that was stored.  
	Fail if the value is negative or is larger than 255. 
	Fail if the index is not an Integer or is out of bounds. Essential.  
	See Object documentation whatIsAPrimitive."

	<primitive: 61>
	^self basicAt: index put: value!

digitLength
	"Answer the number of bytes needed to represent the absolute value
	of the receiver."
	"Class is byte-indexed, so just answer the size."

	^self basicSize! !

!LargeNegativeInteger methodsFor: 'testing'!

negative
	"Answer true that the receiver is less than 0."

	^true!

positive
	"Answer false that the receiver is not less than 0."

	^false! !

!LargeNegativeInteger methodsFor: 'truncation and round off'!

compressed
	"Answer a representation of the receiver as a SmallInteger, if 
	possible, otherwise answer the receiver itself. This message is only 
	used internally after arithmetic and bit operations."

	| size partial maxSize |
	size := self digitLength.
	size = 0 ifTrue: [^0].
	partial := self digitAt: size.
	partial = 0 ifTrue: 
			[[(size := size - 1) > 0 and: [(self digitAt: size) = 0]]
				whileTrue.
			^(self growTo: size) compressed].
	maxSize := SmallInteger maxBytes.
	(size < maxSize or: [size = maxSize and: [partial < MinHi or: [partial = MinHi and: [(self anyBitTo: maxSize - 1 * 8) not]]]])
		ifTrue: 
			["Convert back to a SmallInteger."
			partial := 0 - partial.
			[(size := size - 1) > 0]
				whileTrue: [partial := (partial bitShift: 8)
								- (self digitAt: size)].
			^partial"Can't overflow"]!

lo3bytes

	^ ((self digitAt: 3) bitShift: 16) + ((self digitAt: 2) bitShift: 8) + (self digitAt: 1)! !

!LargeNegativeInteger methodsFor: 'bit manipulation'!

highBit
	"Fail since this message is not defined for negative numbers. "

	self shouldNotImplement! !

!LargeNegativeInteger methodsFor: 'printing'!

printOn: aStream base: b 
	"Print a representation of the receiver on the stream, aStream, in
	base b where 2<=b<=256."

	aStream nextPut: $-.
	super printOn: aStream base: b! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LargeNegativeInteger class
	instanceVariableNames: ''!


!LargeNegativeInteger class methodsFor: 'class initialization'!

initialize
	"Compute the constant MinHi.
	If a LargeNegativeInteger is exactly SmallInteger maxBytes in size, 
	and its high-order byte is not less than MinHi, then the result 
	should be a SmallInteger."

	"LargeNegativeInteger initialize."

	MinHi _ (SmallInteger minVal bitShift: SmallInteger maxBytes - 1 * -8) negated! !

LargeNegativeInteger initialize!
