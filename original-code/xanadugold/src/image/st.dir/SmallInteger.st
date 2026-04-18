'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:16 pm'!

Integer subclass: #SmallInteger
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
SmallInteger comment:
'Representation for instances of class SmallInteger are optimized for the interpreter, stored in two-s complement form.  The allowable range is from minVal to maxVal, determined dynamically.  Assume that minVal is -2^N and maxVal is (2^N)-1 where N is the SmallInteger.'!


!SmallInteger methodsFor: 'arithmetic'!

* aNumber 
	"Answer the result of multiplying the receiver by the argument, 
	aNumber.  Fail if the argument or the result is not a SmallInteger.  
	Essential.  No Lookup.  See Object documentation whatIsAPrimitive."

	<primitive: 9>
	^aNumber productFromInteger: self!

+ aNumber 
	"Answer the result of adding the receiver to the argument.  
	Fail if the argument or the result is not a SmallInteger.  
	Essential.  No Lookup.  See Object documentation whatIsAPrimitive."

	<primitive: 1>
	^aNumber sumFromInteger: self!

- aNumber 
	"Answer the result of subtracting the argument from the receiver.
	Fail if the argument or the result is not a SmallInteger.  
	Essential.  No Lookup.  See Object documentation whatIsAPrimitive."

	<primitive: 2>
	^aNumber differenceFromInteger: self!

/ aNumber 
	"Answer the result of dividing the receiver by the argument aNumber.
	Fail if the result is not a whole integer, or if the argument is 0 or is not
	a SmallInteger.  Optional.  No Lookup.  See Object documentation whatIsAPrimitive."

	<primitive: 10>
	^aNumber quotientFromInteger: self!

// aNumber 
	"Answer with the result of dividing the receiver by the argument.
	Round the result down towards negative infinity to make it a whole 
	integer.  Fail if the argument is 0 or is not a SmallInteger.  Essential.  
	No Lookup.  See Object documentation whatIsAPrimitive. "

	<primitive: 12>
	^super // aNumber		"Do with // if primitive fails"!

quo: aNumber 
	"Answer the result of dividing the receiver by the argument.
	Round the result down towards zero to make it a whole integer.  
	Fail if the argument is 0 or is not a SmallInteger.  Optional.  See 
	Object documentation whatIsAPrimitive."

	<primitive: 13>
	^aNumber quoFromInteger: self!

\\ aNumber 
	"Take the receiver modulo the argument.  Answer the remainder, rounded 
	towards negative infinity, of the receiver divided by the argument.  Fail if the 
	argument is 0 or is not a SmallInteger.  Optional.  No Lookup.  See Object 
	documentation whatIsAPrimitive. "

	<primitive: 11>
	^super \\ aNumber		"Do with // if primitive fails"! !

!SmallInteger methodsFor: 'accessing'!

digitAt: n 
	"Answer the value of an apparent indexable field.
	This is provided for compatibility with LargeInteger."

	 n = 1
		ifTrue: 
			["Negate carefully in case I am SmallInteger minVal"
			self < 0
				ifTrue: [^-256 - self bitAnd: 255].
			^self bitAnd: 255]
		ifFalse:
			[self < 0
				ifTrue: [^(-256 - self bitShift: -8) + 1 digitAt: n - 1].
			^(self bitShift: 8 - (n bitShift: 3)) bitAnd: 255]!

digitAt: n put: value 
	"Provides an error notification. The digits of a 
	SmallInteger can not be modified."

	self shouldNotImplement!

digitLength
	"Answer the number of bytes needed to represent the absolute value
	of the receiver."

	| maxSize minValue size |
	(self < 16r100 and: [self > -16r100]) ifTrue: [^1].
	maxSize := SmallInteger maxBytes.
	minValue := -16r100.
	size := 2.
	[size < maxSize]
		whileTrue:
			[minValue := minValue bitShift: 8.
			(self <= (-1 - minValue) and: [self > minValue]) ifTrue: [^size].
			size := size + 1].
	^maxSize! !

!SmallInteger methodsFor: 'testing'!

even
	"Answer whether the receiver is an even number."

	^(self bitAnd: 1) = 0!

isZero
	"Answer whether 'self = self class zero'"

	^self = 0!

odd
	"Answer whether the receiver is an odd number."

	^(self bitAnd: 1) = 1! !

!SmallInteger methodsFor: 'comparing'!

< aNumber 
	"Answer whether the receiver is less than the argument. 
	Fail if the argument is not a SmallInteger.  Essential.  No Lookup.  
	See Object documentation whatIsAPrimitive."

	<primitive: 3>
	^super < aNumber!

<= aNumber 
	"Answer whether the receiver is less than or equal to the argument.  
	Fail if the argument is not a SmallInteger.  Optional.  No Lookup.  
	See Object documentation whatIsAPrimitive. "

	<primitive: 5>
	^super <= aNumber!

= aNumber 
	"Answer whether the receiver is equal to the argument.  Fail if the  
	argument is not a SmallInteger.  Essential.  No Lookup.  See Object 
	documentation whatIsAPrimitive."

	<primitive: 7>
	^super = aNumber!

> aNumber 
	"Answer whether the receiver is greater than the argument. 
	 Fail if the argument is not a SmallInteger.  Essential.  No Lookup.  
	See Object documentation whatIsAPrimitive."

	<primitive: 4>
	^super > aNumber!

>= aNumber 
	"Answer whether the receiver is greater than or equal to the  
	argument.  Fail if the argument is not a SmallInteger.  Optional.  No 
	Lookup.  See Object documentation whatIsAPrimitive."

	<primitive: 6>
	^super >= aNumber!

hash
	"Answer a SmallInteger unique to the receiver."

	^self!

identityHash
	"Answer a SmallInteger (in this case the receiver itself) whose value 
	reflects the identity, not the contents, of the receiver."

	^self!

~= aNumber 
	"Answer whether the receiver is not equal to the argument.   
	Fail if the argument is not a SmallInteger.  Essential.  No Lookup.  
	See Object documentation whatIsAPrimitive."

	<primitive: 8>
	^super ~= aNumber! !

!SmallInteger methodsFor: 'bit manipulation'!

bitAnd: arg 
	"Answer the logical AND of the two's-complement representation of  
	the receiver with the argument.  Fail if the argument is not a  
	SmallInteger.  Essential.  No Lookup.  See Object documentation 
	whatIsAPrimitive. "

	<primitive: 14>
	^arg bitAnd: self!

bitOr: arg 
	"Answer the logical OR the two's-complement representation of the  
	receiver with the argument.  Fail if the argument is not a  
	SmallInteger.  Essential.  No Lookup.  See Object documentation 
	whatIsAPrimitive. "

	<primitive: 15>
	^arg bitOr: self!

bitShift: arg 
	"Answer a SmallInteger whose value (in two's-complement     
	representation) is the receiver's value (in two's-complement    
	representation) shifted left by the number of bits indicated by the   
	argument.  Negative arguments shift right.  Zeros are shifted in from 
	the right in left shifts.  The sign bit is extended in right shifts.  Fail 
	if the result cannot be represented as a SmallInteger.  Essential.  No 
	Lookup.  See Object documentation whatIsAPrimitive."

	<primitive: 17>
	^super bitShift: arg!

bitXor: arg 
	"Answer the exclusive OR of the two's-complement representation of   
	the receiver with the argument.  Fail if the argument is not a  
	SmallInteger.  Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 16>
	^arg bitXor: self!

highBit
	"Answer the index of the high order bit of the binary
	representation of the receiver."

	| i bit |
	self < 0 ifTrue: [^self shouldNotImplement].
	self = 0 ifTrue: [^0].
	i := 1.
	bit := 1.
	[self > bit]
		whileTrue:
			[i := i + 1.
			bit := bit + bit + 1].
	^i! !

!SmallInteger methodsFor: 'copying'!

deepCopy
	"Answer the receiver itself."

	^self!

shallowCopy
	"Answer the receiver itself."

	^self! !

!SmallInteger methodsFor: 'coercing'!

generality
	"Answer the number representing the ordering of the receiver in the
	generality hierarchy."

	^20! !

!SmallInteger methodsFor: 'converting'!

asDouble
	"Answer an instance of Double whose value is the value of the receiver"

	^Double fromNumber: self!

asFloat
	"Answer an instance of Float whose value is the value of the receiver.  
	Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 40>
	self primitiveFailed! !

!SmallInteger methodsFor: 'printing'!

printOn: aStream base: b 
	"Print a representation of the receiver on the stream, aStream, in
	base b where 2<=b<=256."

	| i x digitBuffer |
	digitBuffer := Array new: 32.	"Enough for 32-bit systems"
	(x := self) < 0
		ifTrue: 
			[aStream nextPut: $-.
			x := self negated].
	i := 0.
	[x >= b]
		whileTrue: 
			[digitBuffer at: (i := i + 1) put: x \\ b.
			x := x // b].
	digitBuffer at: (i := i + 1) put: x.
	[i > 0]
		whileTrue: 
			[aStream nextPut: (Character digitValue: (digitBuffer at: i)).
			i := i - 1]! !

!SmallInteger methodsFor: 'private: private'!

compressed
	"Used to trim LargeIntegers--ignored"

	^self!

fromString: str radix: radix 
	| maxdigit c val |
	maxdigit := 
		radix + (radix > 10
					ifTrue: [55 - 1]
					ifFalse: [48 - 1]).
	val := 0.
	1 to: str size do: 
		[:i | 
		c := str at: i.
		(c < 48 ifFalse: [c > maxdigit])
			ifTrue: [^false].
		val := val * radix + (c <= 57
							ifTrue: [c - 48]
							ifFalse: 
								[c < 65 ifTrue: [^false].
								c - 55])].
	^val!

subtractOrFail: aNumber 
	"This is a private copy of the subtraction primitive,
	used by SmallInteger class initialize to discover the
	correct value of SmallInteger minVal."

	<primitive: 2>
	^nil! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SmallInteger class
	instanceVariableNames: 'minVal maxVal maxBits maxBytes '!


!SmallInteger class methodsFor: 'class initialization'!

initialize
	"Initialize the digit buffer, and discover the range of
	SmallIntegers on this system."

	"SmallInteger initialize."

	| val bits |
	"Discover minVal and maxVal dynamically.  Assume that
	minVal is -2^N and maxVal is (2^N)-1."
	val := -1.
	bits := 0.
	[(val subtractOrFail: 1) notNil]
		whileTrue:
			[val := val + val.
			bits := bits + 1].
	minVal := val.
	maxVal := (val + 1) negated.
	maxBits := bits.
	maxBytes := bits + 7 // 8.! !

!SmallInteger class methodsFor: 'instance creation'!

basicNew
	"Fail.  SmallIntegers can only be created by
	performing arithmetic."

	^self shouldNotImplement! !

!SmallInteger class methodsFor: 'constants'!

maxBits
	"Answer N such that maxVal is (2^N)-1."

	^maxBits!

maxBytes
	"Answer N such that maxVal < 256^N."

	^maxBytes!

maxVal
	"Answer the maximum value for a SmallInteger."

	^maxVal!

minVal
	"Answer the minimum value for a SmallInteger."

	^minVal! !

!SmallInteger class methodsFor: 'documentation'!

guideToDivision
	"Handy guide to the kinds of Integer division: 
	/  exact division, answer a fraction if result is not a whole integer. 
	//  answer an Integer, rounded towards negative infinity. 
	\\ is modulo rounded towards negative infinity. 
	quo:  truncated division, rounded towards zero."! !

!SmallInteger class methodsFor: 'constants access'!

unity
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber * aNumber class unity = aNumber

	This must be true regardless of how a given subclass chooses to define #*"

	^1!

zero
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber + aNumber class zero = aNumber

	This must be true regardless of how a given subclass chooses to define #+"

	^0! !

SmallInteger initialize!
