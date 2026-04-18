'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:15 pm'!

ArithmeticValue subclass: #Number
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
Number comment:
'The abstract class Number represents scalar quantities, and corresponds approximately to the mathematical definition of the Real numbers. Some of its subclasses are: LimitedPrecisionReal, Fraction, and Integer.

Subclasses must implement methods for 
	arithmetic messages
		*
		+
		-
		/
	comparison
		<
	coercing messages
		coerce:
		generality'!


!Number methodsFor: 'arithmetic'!

// aNumber 
	"Integer quotient defined by division with truncation toward negative 
	infinity.  9//4 = 2,  -9//4 = -3.  -0.9//0.4 = -3.
	\\ answers the remainder from this division."

	^(self / aNumber) floor!

quo: aNumber 
	"Integer quotient defined by division with truncation toward zero.   
	 -9 quo: 4 = -2,  -0.9 quo: 0.4 = -2. 
	rem: answers the remainder from this division."

	^(self / aNumber) truncated!

rem: aNumber 
	"Remainder defined in terms of quo:. Answer a Number with the same 
	sign as self.  e.g. 9 rem: 4 = 1,  -9 rem: 4 = -1.  0.9 rem: 0.4 = 0.1"

	^self - ((self quo: aNumber) * aNumber)!

\\ aNumber 
	"modulo.  Remainder defined in terms of //.  Answer a Number with the 
	same sign as aNumber.  e.g.  9\\4 = 1,  -9\\4 = 3, 9\\-4 =  -3,  0.9\\0.4 = 0.1"

	^self - (self // aNumber * aNumber)! !

!Number methodsFor: 'mathematical functions'!

** aNumber 
	"Answer the receiver raised to the power of the argument, aNumber."
	"Just some infix sugar for Number>>raisedTo:"

	^self raisedTo: aNumber!

arcCos
	"Answer the angle in radians."

	^self asFloat arcCos!

arcSin
	"Answer the angle in radians."

	^self asFloat arcSin!

arcTan
	"Answer the angle in radians."

	^self asFloat arcTan!

ceilingLog: radix 
	"Answer the ceiling of the log base radix of the receiver."

	| x  |
	self <= 0 ifTrue: [^self class
			raise: #domainErrorSignal
			receiver: self
			selector: #ceilingLog:
			arg: radix
			errorString: 'Can''t take log of number <= 0'].
	x := self floorLog: radix.
	(radix raisedTo: x) = self ifTrue: [^x] ifFalse: [^x + 1]!

cos
	"Answer the angle in radians."

	^self asFloat cos!

exp
	"Answer the exponential of the receiver as a floating point number."

	^self asFloat exp!

floorLog: radix 
	"Answer the floor of the log base radix of the receiver."

	| x  |
	self <= 0 ifTrue: [^self class
			raise: #domainErrorSignal
			receiver: self
			selector: #floorLog:
			arg: radix
			errorString: 'Can''t take log of number <= 0'].
	self < radix ifTrue: [^0].
	self/radix < radix ifTrue: [^1].
	x := 2 * (self floorLog: radix*radix)."binary recursion like ipow"
	^x + (self / (radix raisedTo: x) floorLog: radix)!

ln
	"Answer the natural log of the receiver."

	^self asFloat ln!

log
	"Answer with base 10 logarithm."

	^self ln / 10.0 ln!

log: aNumber 
	"Answer the log base aNumber of the receiver."

	^self ln / aNumber ln!

raisedTo: aNumber 
	"Answer the receiver raised to the power of the argument, aNumber."

	aNumber truncated = aNumber
		ifTrue: ["Do the special case of integer power"
				^self raisedToInteger: aNumber truncated].
	aNumber = 0 ifTrue: [^1].		"Special case of exponent=0"
	aNumber = 1 ifTrue: [^self].	"Special case of exponent=1"
	(self = 0 or: [self = 1]) ifTrue: [^self].
	aNumber < 0 ifTrue: [^(self raisedTo: aNumber negated) reciprocal].
	self < 0 ifTrue: [^self negRaisedToNonInteger: aNumber].
	^(aNumber * self ln) exp		"Otherwise raise it to the power using logarithms"!

raisedTo: aNumber mod: aModulus
	"Answer the receiver raised to the power of the argument, aNumber."

	aNumber truncated = aNumber
		ifTrue: ["Do the special case of integer power"
				^self raisedToInteger: (aNumber truncated) mod: aModulus].
	aNumber = 0 ifTrue: [^1].		"Special case of exponent=0"
	aNumber = 1 ifTrue: [^self \\ aModulus].	"Special case of exponent=1"
	(self = 0 or: [self = 1]) ifTrue: [^self].
	aNumber < 0 ifTrue: [^(self raisedTo: aNumber negated mod: aModulus) reciprocal].
	self < 0 ifTrue: [^self negRaisedToNonInteger: aNumber].
	^((aNumber * self ln) exp) \\ aModulus		"Otherwise raise it to the power using logarithms"!

sin
	"Answer the angle in radians."

	^self asFloat sin!

sqrt
	"Answer the square root of the receiver."

	self < 0
		ifTrue: [^self class
			raise: #imaginaryResultSignal
			receiver: self
			selector: #sqrt
			errorString: 'Can''t take square root of negative number'].
	^self asFloat sqrt!

tan
	"Answer the ratio of the sine to cosine of the receiver in radians."

	^self asFloat tan! !

!Number methodsFor: 'testing'!

even
	"Answer whether the receiver is an even number."

	^self \\ 2 = 0!

odd
	"Answer whether the receiver is an odd number."

	^self \\ 2 = 1! !

!Number methodsFor: 'truncation and round off'!

ceiling
	"Answer the integer nearest the receiver toward positive infinity."

	self <= 0
		ifTrue: [^self truncated]
		ifFalse: [^self negated floor negated]!

floor
	"Answer the integer nearest the receiver toward negative infinity."

	| truncation |
	truncation := self truncated.
	self >= 0 ifTrue: [^truncation].
	self = truncation
		ifTrue: [^truncation]
		ifFalse: [^truncation - 1]!

rounded
	"Answer the integer nearest the receiver."

	^(self + (self sign / 2)) truncated!

roundTo: aNumber 
	"Answer the integer that is a multiple of the argument, aNumber,
	that is nearest the receiver."

	^(self / aNumber) rounded * aNumber!

truncated
	"Answer an integer nearest the receiver toward zero."

	^self quo: 1!

truncateTo: aNumber 
	"Answer the next multiple of the argument, aNumber, that is 
	nearest the receiver toward zero."

	^(self quo: aNumber) * aNumber! !

!Number methodsFor: 'double dispatching'!

quoFromInteger: anInteger 
	"Answer the result of dividing the receiver by the argument. 
	The result is rounded down towards zero to make it a whole integer."

	^(anInteger / self) truncated! !

!Number methodsFor: 'converting'!

% aNumber 
	"Answer a complex number with the receiver as the real part and 
	aNumber as the imaginary part"

	^Complex real: self imaginary: aNumber!

@ y 
	"Answer a new Point whose x value is the receiver and whose y value is the 
	argument.  Optional. See Object documentation whatIsAPrimitive."

	<primitive: 18>
	^Point x: self y: y!

asComplex
	"Answer a complex number with the receiver as the real part and 
	zero as the imaginary part"

	^Complex fromReal: self!

asInteger
	"Answer an Integer nearest the receiver toward zero."

	^self truncated!

asMetaNumber
	"Represent the number as a MetaNumeric"

	^SomeNumber from: self!

asPoint
	"Answer a new Point with the receiver as both coordinates; 
	often used to supply the same value in two dimensions, as with
	symmetrical gridding or scaling."

	^self @ self!

asRational
	"Answer a Rational number--Integer or Fraction--that approximately 
	or exactly represents the receiver"

	^self subclassResponsibility!

degreesToRadians
	"Answer the conversion to radians.  The receiver is assumed to 
	represent degrees."

	^self asFloat degreesToRadians!

radiansToDegrees
	"Answer the conversion to degrees.  The receiver is assumed to 
	represent radians."

	^self asFloat radiansToDegrees! !

!Number methodsFor: 'intervals'!

almostTo: stop
	"Answer an Interval from the receiver up to (not including) the argument, stop, with
	each next element computed by incrementing the previous one by 1."

	^Interval from: self to: (stop - 1) by: 1!

almostTo: stop by: step
	"Answer an Interval from the receiver up to (not including) the argument, stop, with each
	next element computed by incrementing the previous one by step."

	^Interval from: self to: (stop - 1) by: step!

almostTo: stop by: step do: aBlock 
	"For each number in the interval from the receiver up to (not including) the 
	argument, stop, incrementing by step, evaluate the block, aBlock. 
	This method is normally not invoked, since the compiler expands 
	to:do:by: in-line."

	self to: (stop - 1) by: step do: aBlock!

almostTo: stop do: aBlock 
	"For each number in the interval from the receiver up to (not including) the 
	argument, stop, incrementing by 1, evaluate the block, aBlock. This 
	method is normally not invoked, since the compiler expands to:do:
	in-line."

	self to: (stop - 1) do: aBlock!

asInterval
	"An interval containing a single number"
	^self to: self!

downTo: stop do: aBlock 
	self to: stop by: -1 do: aBlock!

to: stop
	"Answer an Interval from the receiver up to the argument, stop, with
	each next element computed by incrementing the previous one by 1."

	^Interval from: self to: stop by: 1!

to: stop by: step
	"Answer an Interval from the receiver up to the argument, stop, with each
	next element computed by incrementing the previous one by step."

	^Interval from: self to: stop by: step!

to: stop by: step do: aBlock 
	"For each number in the interval from the receiver up to the 
	argument, stop, incrementing by step, evaluate the block, aBlock. 
	This method is normally not invoked, since the compiler expands 
	to:do:by: in-line."

	(Interval from: self to: stop by: step) do: aBlock!

to: stop do: aBlock 
	"For each number in the interval from the receiver up to the 
	argument, stop, incrementing by 1, evaluate the block, aBlock. This 
	method is normally not invoked, since the compiler expands to:do:
	in-line."

	(Interval from: self to: stop by: 1) do: aBlock! !

!Number methodsFor: 'printing'!

storeOn: aStream 
	"Print the receiver on the stream, aStream.
	Numbers print in a form recognized by the compiler."

	self printOn: aStream! !

!Number methodsFor: 'private: private'!

negRaisedToNonInteger: aNumber
	"Answer the receiver (which is negative) to the power of aNumber.
	aNumber is known to be a positive non-integer."

	| fract |
	fract _ aNumber asFraction.
	fract denominator even
		ifTrue: [^self class
			raise: #imaginaryResultSignal
			receiver: self
			selector: #raisedTo:
			arg: aNumber
			errorString: 'Can''t take even root of a negative number'].
	^(self abs raisedTo: aNumber) * self sign
		* (fract numerator even ifTrue: [self sign] ifFalse: [1])! !

!Number methodsFor: 'backward compatability'!

asFraction
	"Answer the receiver represented as a Fraction, if possible.
	This message is retained for backward compatability ONLY"

	^self asRational! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Number class
	instanceVariableNames: ''!


!Number class methodsFor: 'instance creation'!

coerceDouble: aNumber
	"Answer a double-precision floating point number that represents aNumber"

	^aNumber asDouble!

coerceFloat: aNumber
	"Answer a floating point number that represents aNumber"

	^aNumber asFloat!

readFrom: aStream 
	"Answer an instance of me as described on the stream, aStream."

	| value radix neg |
	(aStream atEnd or: [aStream peek isLetter])
		ifTrue: [^0].
	radix := 10.
	neg := aStream peekFor: $-.
	value := Integer readFrom: aStream.
	(aStream peekFor: $r)
		ifTrue: 
			["<radix>r<integer>"
			(neg or: [(radix := value) < 2])
				ifTrue: [^self error: 'INVALID RADIX'].
			neg := aStream peekFor: $-.
			value := Integer readFrom: aStream radix: radix].
	(aStream peekFor: $.)
		ifTrue: ["<integer>.<fraction>"
			(aStream atEnd not and: [aStream peek digitValue between: 0 and: radix - 1])
				ifTrue: 
					[| num den digit atEnd |
					den := 1.
					num := 0.
					[(atEnd := aStream atEnd) or: 
							[digit := aStream next digitValue.
							digit < 0 or: [digit >= radix]]]
						whileFalse: 
							[num := num * radix + digit.
							den := den * radix].
					atEnd ifFalse: [aStream skip: -1].
					den * value + num > Float largestMantissa
						ifTrue: [value := (self coerceDouble: value) + (num / den)]
						ifFalse: [value := (self coerceFloat: value) + (num / den)]]
				ifFalse: ["oops - just <integer>."
					aStream skip: -1
					"un-gobble the period"]].
	((aStream peekFor: $e)
			or: [(aStream peekFor: $d)
				ifTrue: [value := self coerceDouble: value. true] ifFalse: [false]])
		ifTrue: ["<integer>e<exponent>"
			value := value * (radix raisedTo: (Integer readFrom: aStream))].
	neg
		ifTrue: [^value negated]
		ifFalse: [^value]! !

!Number class methodsFor: 'constants access'!

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