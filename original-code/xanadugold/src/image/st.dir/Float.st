'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:11 pm'!

LimitedPrecisionReal variableByteSubclass: #Float
	instanceVariableNames: ''
	classVariableNames: 'Halfpi Pi RadiansPerDegree '
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
Float comment:
'Instances of the class Float represent floating-point numbers in platform-dependent short float format.

These floating-point numbers are good for about 8 or 9 digits of accuracy, and the range is between plus and minus 10^38.
Here are some valid floating-point examples:
	8.0   13.3   0.3   2.5e6   1.27e-30  1.27e-31 -12.987654e12
The format consists mainly of no imbedded blanks, little e for tens power, and a digit on both sides of the decimal point.

Instance Variables: *byte indexed*

Class Variables: 
	Pi					<Float> 3.14159
	RadiansPerDegree	<Float> 0.0174533
'!


!Float methodsFor: 'accessing'!

at: index 
	"Override implementation in Object since Float
	instances are not element indexable."

	^self shouldNotImplement!

at: index put: value 
	"Override implementation in Object since Float
	instances are not element indexable."

	^self shouldNotImplement!

size
	"Override implementation in Object since Float
	instances are not element indexable."

	^self shouldNotImplement! !

!Float methodsFor: 'arithmetic'!

* aNumber 
	"Answer a Float that is the result of multiplying the receiver by the 
	argument, aNumber.  The primitive fails if it cannot coerce the argument to a Float"

	<primitive: 49>
	^aNumber productFromFloat: self!

+ aNumber 
	"Answer a Float that is the result of adding the receiver to the argument.  
	The primitive fails if it cannot coerce the argument to a Float"

	<primitive: 41>
	^aNumber sumFromFloat: self!

- aNumber 
	"Answer a Float that is the difference between the receiver and aNumber.  
	The primitive fails if it cannot coerce the argument to a Float"

	<primitive: 42>
	^aNumber differenceFromFloat: self!

/ aNumber 
	"Answer a Float that is the exact result of dividing the receiver 
	by the argument, aNumber.  The primitive fails if it cannot coerce 
	the argument to a Float"

	<primitive: 50>
	^aNumber quotientFromFloat: self! !

!Float methodsFor: 'mathematical functions'!

arcCos
	"Answer the angle in radians.
	The receiver must be between -1.0 and 1.0
	The result will be between 0.0 and Pi"

	<primitive: 593>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #arcCos
		errorString: 'Receiver must be between 1.0 and -1.0'!

arcSin
	"Answer the angle in radians.
	The receiver must be between -1.0 and 1.0
	The result will be between -Pi/2 and Pi/2"

	<primitive: 592>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #arcSin
		errorString: 'Receiver must be between 1.0 and -1.0'!

arcTan
	"Answer the angle in radians.
	The receiver can be any valid Float
	The result will be between -Pi/2 and Pi/2"

	<primitive: 602>
	^self primitiveFailed!

cos
	"return the cosine of the receiver (an angle in radians)
	The receiver can be any valid Float
	The result will be between -1.0 and 1.0"

	<primitive: 591>
	^self primitiveFailed!

exp
	"return the exponential function of the receiver 
	The receiver may be between roughly -86.0 and 88.0 
	The result will be greater than 0.0"

	<primitive: 605>
	^self class
		raise: (self positive
				ifTrue: [#overflowSignal]
				ifFalse: [#underFlowSignal])
		receiver: self
		selector: #exp
		errorString: 'e raised to ' , self printString , ' cannot be expressed as a Float'!

floorLog10
	"Answer with a (quick) computation of (self log: 10) floor.
	The receiver must be greater than zero
	The result will be between -38 and 38"

	<primitive: 609>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #floorLog10
		errorString: 'Can''t take log of number <= 0'!

ln
	"answer the natural log of the reciever
	The receiver must be greater than 0.0
	The result will be between -88.0 and 88.0"

	<primitive: 604>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #ln
		errorString: 'Can''t take log of number <= 0'!

raisedTo: power 
	"return (receiver ** power)"

	<primitive: 606>
	^super raisedTo: power!

sin
	"return the sine of the receiver (an angle in radians)
	The receiver can be any valid Float
	The result will be between -1.0 and 1.0"

	<primitive: 600>
	^self primitiveFailed!

sqrt
	"Answer the square root of the receiver.
	The receiver must be positive
	The result will be positive"

	<primitive: 603>
	^self class
		raise: #imaginaryResultSignal
		receiver: self
		selector: #sqrt
		errorString: 'Can''t take square root of negative number'!

tan
	"Answer the ratio of the sine to cosine of the receiver in radians.
	The receiver can be any valid Float--in practice it is unlikely that
		a Float would have a value close enough to Pi/2, or -Pi/2, or
		3*Pi/2, or . . . to cause the primitive to fail
	The result will be between -Infinity and +Infinity--if failure occurs,
		the value was arbitrarily large, either positive or negative"

	<primitive: 601>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #tan
		errorString: 'Can''t evaluate tan for pi/2, -pi/2, 3*pi/2, . . .'! !

!Float methodsFor: 'testing'!

isLiteral
	"Answer whether the receiver has a literal text form
	recognized by the compiler."

	^true!

isZero
	"Answer whether 'self = self class zero'"

	^self = 0.0! !

!Float methodsFor: 'comparing'!

< aNumber 
	"Answer whether the receiver is less than the argument.
	The primitive fails if it cannot coerce the argument to a Float"

	<primitive: 43>
	^aNumber lessFromFloat: self!

<= aNumber 
	"Answer whether the receiver is less than or equal to the argument.   
	The primitive fails if it cannot coerce the argument to a Float"

	<primitive: 45>
	^super <= aNumber!

= aNumber 
	"Answer whether the receiver is equal to the argument. 
	The primitive fails if it cannot coerce the argument to a Float"

	<primitive: 47>
	^super = aNumber!

> aNumber 
	"Answer whether the receiver is greater than the argument. 
	The primitive fails if it cannot coerce the argument to a Float"

	<primitive: 44>
	^super > aNumber!

>= aNumber 
	"Answer whether the receiver is greater than or equal to the argument.  
	The primitive fails if it cannot coerce the argument to a Float"

	<primitive: 46>
	^super >= aNumber!

~= aNumber 
	"Answer whether the receiver is not equal to the argument. 
	The primitive fails if it cannot coerce the argument to a Float"

	<primitive: 48>
	^super ~= aNumber! !

!Float methodsFor: 'truncation and round off'!

fractionPart
	"Answer a Float whose value is the difference between the  
	receiver and the receiver's truncated value.  Optional.  See Object 
	documentation whatIsAPrimitive."

	<primitive: 52>
	^self - self truncated!

rounded
	"Answer the integer nearest the receiver."

	<primitive: 590>
	self >= 0.0
		ifTrue: [^(self + 0.5) truncated]
		ifFalse: [^(self - 0.5) truncated]!

truncated
	"Answer a SmallInteger equal to the value of the receiver     
	without its fractional part. Fail if the truncated value cannot be    
	represented as a SmallInteger.  In that case, the code below will   
	compute a LargeInteger truncated value. Essential. See Object  
	documentation whatIsAPrimitive."

	<primitive: 51>
	| max |
	max := SmallInteger maxVal // 2 + 1.
	^(self quo: max asFloat)
		* max + (self rem: max asFloat) truncated! !

!Float methodsFor: 'coercing'!

coerce: aNumber
	"Convert a number to a compatible form"

	^aNumber asFloat!

generality
	"Answer the number representing the ordering of the receiver in the
	generality hierarchy."

	^80! !

!Float methodsFor: 'double dispatching'!

differenceFromDouble: aDouble

	^aDouble - self asDouble!

differenceFromFloat: aFloat 
	"Presumably here because Float - failed.
	If the receiver's magnitude is very small, then aFloat's magnitude
	must be very small, and the calculation underflowed.
	Otherwise, both are very large and the calculation overflowed"
	^aFloat asDouble - self asDouble
	"^self class
		raise: (self abs > 1.0
				ifTrue: [#overflowSignal]
				ifFalse: [#underflowSignal])
		receiver: aFloat
		selector: #-
		arg: self
		errorString: 'Can''t represent the difference as a Float'"!

differenceFromFraction: aFraction

	^aFraction asFloat - self!

differenceFromInteger: anInteger

	^anInteger asFloat - self!

lessFromDouble: aDouble

	^aDouble < self asDouble!

lessFromFloat: aFloat

	^self class
		raise: #errorSignal
		receiver: aFloat
		selector: #<
		arg: self
		errorString: 'This should not happen'!

lessFromFraction: aFraction

	^aFraction asFloat < self!

lessFromInteger: anInteger

	^anInteger asFloat < self!

productFromDouble: aDouble

	^aDouble * self asDouble!

productFromFloat: aFloat 
	"Presumably here because Float * failed.
	If the receiver's magnitude is very small, then aFloat's magnitude
		must be very small, and the calculation underflowed.
	Otherwise, both are very large and the calculation overflowed"
	^self asDouble * aFloat asDouble
	"^self class
		raise: (self abs > 1.0
				ifTrue: [#overflowSignal]
				ifFalse: [#underflowSignal])
		receiver: aFloat
		selector: #*
		arg: self
		errorString: 'Can''t represent the product as a Float'"!

productFromFraction: aFraction

	^aFraction asFloat * self!

productFromInteger: anInteger

	^anInteger asFloat * self!

quotientFromDouble: aDouble

	^aDouble / self asDouble!

quotientFromFloat: aFloat 
	"Presumably here because Float / failed.
	First check for division by zero.
	If the receiver's magnitude is smaller than aFloat's magnitude, the
		calculation overflowed, since the quotient's magnitude > 1.0.
	Otherwise, the receiver was larger (in magnitude) than the argument,
		so the quotient's magnitude < 1.0 and underflow must have occurred"

	self = 0.0
		ifTrue: [^self class
				raise: #divisionByZeroSignal
				receiver: aFloat
				selector: #/
				arg: self
				errorString: 'Can''t divide a number by zero']
		ifFalse: [^aFloat asDouble / self asDouble.
			"^self class
				raise: (self abs > aFloat abs
						ifTrue: [#underflowSignal]
						ifFalse: [#overflowSignal])
				receiver: aFloat
				selector: #/
				arg: self
				errorString: 'Can''t represent the quotient as a Float'"]!

quotientFromFraction: aFraction

	^aFraction asFloat / self!

quotientFromInteger: anInteger

	^anInteger asFloat / self!

sumFromDouble: aDouble

	^aDouble + self asDouble!

sumFromFloat: aFloat 
	"Presumably here because Float + failed.
	If the receiver's magnitude is very small, then aFloat's magnitude
		must be very small, and the calculation underflowed.
	Otherwise, both are very large and the calculation overflowed"
	^self asDouble + aFloat asDouble
	"^self class
		raise: (self abs > 1.0
				ifTrue: [#overflowSignal]
				ifFalse: [#underflowSignal])
		receiver: aFloat
		selector: #+
		arg: self
		errorString: 'Can''t represent the sum as a Float'"!

sumFromFraction: aFraction

	^aFraction asFloat + self!

sumFromInteger: anInteger

	^anInteger asFloat + self! !

!Float methodsFor: 'converting'!

asDouble
	"Answer the receiver itself."

	^Double fromNumber: self!

asFloat
	"Answer the receiver itself."

	^self! !

!Float methodsFor: 'fileIn/Out'!

isManifest
	"Answer whether receiver is manifestly storable."
	^true!

storeBinaryOn: stream
	"Put a binary representation of the receiver into stream."

	stream storeFloat: self! !

!Float methodsFor: 'private: private'!

defaultNumberOfDigits
	"Answer how many digits of accuracy this class supports"

	^6!

exponent
	"Answer the SmallInteger to whose power two is raised. 
	Consider the receiver to be represented as a power of 
	two multiplied by a mantissa (between one and two). 
	Optional. See Object documentation whatIsAPrimitive."

	<primitive: 53>
	| positive |
	self >= 1.0 ifTrue: [^self floorLog: 2].
	self > 0.0
		ifTrue: 
			[positive := (1.0 / self) exponent.
			self = (1.0 / (1.0 timesTwoPower: positive))
				ifTrue: [^positive negated]
				ifFalse: [^positive negated - 1]].
	self = 0.0 ifTrue: [^0].
	^self negated exponent!

timesTwoPower: anInteger 
	"Answer the receiver multiplied by 2.0 raised to the power of 
	the argument. Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 54>
	^self * (2.0 raisedToInteger: anInteger)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Float class
	instanceVariableNames: ''!


!Float class methodsFor: 'class initialization'!

initialize
	"Constants from Computer Approximations, pp. 182-183 
	Pi = 3.14159265358979323846264338327950288 
	Pi/2 = 1.57079632679489661923132169163975144 
	Pi/4 = 0.78539816339744830961566084581987572 
	Pi*2 = 6.28318530717958647692528676655900576 
	Pi/180 = 0.01745329251994329576923690768488612 
	2.0 ln = 0.69314718055994530941723212145817657 
	2.0 sqrt = 1.41421356237309504880168872420969808"

	"Float initialize."

	Pi := 3.1415927.
	RadiansPerDegree := Pi / 180.0! !

!Float class methodsFor: 'instance creation'!

readFrom: aStream 
	"Answer a new Float as described on the stream, aStream."

	^(super readFrom: aStream) asFloat! !

!Float class methodsFor: 'constants access'!

largestMantissa
	^16777215!

pi
	"Answer the constant, Pi."

	^Pi!

radiansPerDegree
	"Answer the constant, RadiansPerDegree."

	^RadiansPerDegree!

unity
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber * aNumber class unity = aNumber

	This must be true regardless of how a given subclass chooses to define #*"

	^1.0!

zero
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber + aNumber class zero = aNumber

	This must be true regardless of how a given subclass chooses to define #+"

	^0.0! !

Float initialize!
