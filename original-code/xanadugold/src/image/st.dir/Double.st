'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:10 pm'!

LimitedPrecisionReal variableByteSubclass: #Double
	instanceVariableNames: ''
	classVariableNames: 'Pi RadiansPerDegree '
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
Double comment:
'Instances of the class Double represent floating-point numbers in IEEE 64-bit format.

These floating-point numbers are good for about 14 or 15 digits of accuracy, and the range is between plus and minus 10^307.
Here are some valid floating-point examples:
	8.0   13.3   0.3   2.5e6   1.27e-30  1.27e-31 -12.987654e12
The format consists mainly of no imbedded blanks, little e for tens power, and a digit on both sides of the decimal point.

Instance Variables: *byte indexed*

Class Variables: 
	Pi					<Double> 3.14159
	RadiansPerDegree	<Double> 0.0174533
'!


!Double methodsFor: 'accessing'!

at: index
        "Override implementation in Object since Double
        instances are not element indexable."
 
        ^self shouldNotImplement!

at: index put: value
        "Override implementation in Object since Double
        instances are not element indexable."
 
        ^self shouldNotImplement!

size
        "Override implementation in Object since Double
        instances are not element indexable."
 
        ^self shouldNotImplement! !

!Double methodsFor: 'arithmetic'!

* aNumber 
	"Answer a Double that is the result of multiplying the receiver by the 
	argument, aNumber.  The primitive fails if it cannot coerce the argument
	to a Double"

	<primitive: 569>
	^aNumber productFromDouble: self!

+ aNumber 
	"Answer a Double that is the result of adding the receiver to the argument.  
	The primitive fails if it cannot coerce the argument to a Double, or if 
	overflow occurs."

	<primitive: 561>
	^aNumber sumFromDouble: self!

- aNumber 
	"Answer a Double that is the difference between the receiver and aNumber.  
	The primitive fails if it cannot coerce the argument to a Double."

	<primitive: 562>
	^aNumber differenceFromDouble: self!

/ aNumber 
	"Answer a Double that is the exact result of dividing the receiver by the 
	argument, anInteger.  The primitive fails if it cannot coerce the argument 
	to a Double."

	<primitive: 570>
	^aNumber quotientFromDouble: self! !

!Double methodsFor: 'mathematical functions'!

arcCos
	"Answer the angle in radians.
	The receiver must be between -1.0 and 1.0
	The result will be between 0.0 and Pi"

	<primitive: 580>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #arcCos
		errorString: 'Receiver must be between 1.0 and -1.0'!

arcSin
	"Answer the angle in radians.
	The receiver must be between -1.0 and 1.0
	The result will be between -Pi/2 and Pi/2"

	<primitive: 579>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #arcSin
		errorString: 'Receiver must be between 1.0 and -1.0'!

arcTan
	"Answer the angle in radians.
	The receiver can be any valid Double
	The result will be between -Pi/2 and Pi/2"

	<primitive: 581>
	^self primitiveFailed!

cos
	"return the cosine of the receiver (an angle in radians)
	The receiver can be any valid Double
	The result will be between -1.0 and 1.0"

	<primitive: 577>
	^self primitiveFailed!

exp
	"return the exponential function of the receiver 
	The receiver may be between roughly -709.0 and 709.0 
	The result will be greater than 0.0"

	<primitive: 584>
	^self class
		raise: (self positive
				ifTrue: [#overflowSignal]
				ifFalse: [#underFlowSignal])
		receiver: self
		selector: #exp
		errorString: 'e raised to ' , self printString , ' cannot be expressed as a Double'!

floorLog10
	"Answer with a (quick) computation of (self log: 10) floor.
	The receiver must be greater than zero
	The result will be between -307 and 307"

	<primitive: 587>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #floorLog10
		errorString: 'Can''t take log of number <= 0'!

ln
	"answer the natural log of the reciever
	The receiver must be greater than 0.0
	The result will be between -709.0 and 709.0"

	<primitive: 583>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #ln
		errorString: 'Can''t take log of number <= 0'!

raisedTo: power 
	"return (receiver ** power)"

	<primitive: 585>
	^super raisedTo: power!

sin
	"return the sine of the receiver (an angle in radians)
	The receiver can be any valid Double
	The result will be between -1.0 and 1.0"

	<primitive: 576>
	^self primitiveFailed!

sqrt
	"Answer the square root of the receiver.
	The receiver must be positive
	The result will be positive"

	<primitive: 582>
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

	<primitive: 578>
	^self class
		raise: #domainErrorSignal
		receiver: self
		selector: #tan
		errorString: 'Can''t evaluate tan for pi/2, -pi/2, 3*pi/2, ...'! !

!Double methodsFor: 'testing'!

isZero
	"Answer whether 'self = self class zero'"

	^self = 0.0! !

!Double methodsFor: 'comparing'!

< aNumber 
	"Answer whether the receiver is less than the argument.
	The primitive fails if it cannot coerce the argument to a Double"

	<primitive: 563>
	^aNumber lessFromDouble: self!

<= aNumber 
	"Answer whether the receiver is less than or equal to the argument.   
	The primitive fails if it cannot coerce the argument to a Double"

	<primitive: 565>
	^super <= aNumber!

= aNumber 
	"Answer whether the receiver is equal to the argument.
	The primitive fails if it cannot coerce the argument to a Double"

	<primitive: 567>
	^super = aNumber!

> aNumber 
	"Answer whether the receiver is greater than the argument. 
	The primitive fails if it cannot coerce the argument to a Double"

	<primitive: 564>
	^super > aNumber!

>= aNumber 
	"Answer whether the receiver is greater than or equal to the argument.  
	The primitive fails if it cannot coerce the argument to a Double"

	<primitive: 566>
	^super >= aNumber!

~= aNumber 
	"Answer whether the receiver is not equal to the argument.
	The primitive fails if it cannot coerce the argument to a Double"

	<primitive: 568>
	^super ~= aNumber! !

!Double methodsFor: 'truncation and round off'!

fractionPart
	"Answer a Double whose value is the difference between the  
	receiver and the receiver's truncated value"

	<primitive: 572>
	^super fractionPart!

rounded
	"Answer the integer nearest the receiver."

	<primitive: 575>
	^super rounded!

truncated
	"Answer a SmallInteger equal to the value of the receiver     
	without its fractional part. Fail if the truncated value cannot be    
	represented as a SmallInteger.  In that case, the code below will   
	compute a LargeInteger truncated value"

	<primitive: 571>
	| max |
	max := SmallInteger maxVal // 2 + 1.
	^(self quo: max asDouble)
		* max + (self rem: max asDouble) truncated! !

!Double methodsFor: 'coercing'!

coerce: aNumber

	^aNumber asDouble!

generality

	^90! !

!Double methodsFor: 'double dispatching'!

differenceFromDouble: aDouble
	"Presumably here because Double - failed.
	If the receiver's magnitude is very small, then aDouble's magnitude
		must be very small, and the calculation underflowed.
	Otherwise, both are very large and the calculation overflowed"

	^self class
		raise: (self abs > 1.0
				ifTrue: [#overflowSignal]
				ifFalse: [#underflowSignal])
		receiver: aDouble
		selector: #-
		arg: self
		errorString: 'Result could not be expressed as a Double'!

differenceFromFloat: aFloat

	^aFloat asDouble - self!

differenceFromFraction: aFraction

	^aFraction asDouble - self!

differenceFromInteger: anInteger

	^anInteger asDouble - self!

lessFromDouble: aDouble

	^self class
		raise: #errorSignal
		receiver: aDouble
		selector: #<
		arg: self
		errorString: 'This should not happen'!

lessFromFloat: aFloat

	^aFloat asDouble < self!

lessFromFraction: aFraction

	^aFraction asDouble < self!

lessFromInteger: anInteger

	^anInteger asDouble < self!

productFromDouble: aDouble
	"Presumably here because Double * failed.
	If the receiver's magnitude is very small, then aDouble's magnitude
		must be very small, and the calculation underflowed.
	Otherwise, both are very large and the calculation overflowed"

	^self class
		raise: (self abs > 1.0
				ifTrue: [#overflowSignal]
				ifFalse: [#underflowSignal])
		receiver: aDouble
		selector: #*
		arg: self
		errorString: 'Result could not be expressed as a Double'!

productFromFloat: aFloat

	^aFloat asDouble * self!

productFromFraction: aFraction

	^aFraction asDouble * self!

productFromInteger: anInteger

	^anInteger asDouble * self!

quotientFromDouble: aDouble 
	"Presumably here because Double / failed.
	First check for division by zero.
	If the receiver's magnitude is smaller than aDouble's magnitude, the
		calculation overflowed, since the quotient's magnitude > 1.0.
	Otherwise, the receiver was larger (in magnitude) than the argument,
		so the quotient's magnitude < 1.0 and underflow must have occurred"

	self = 0.0
		ifTrue: [^self class
				raise: #divisionByZeroSignal
				receiver: aDouble
				selector: #/
				arg: self
				errorString: 'Can''t divide a number by zero']
		ifFalse: [^self class
				raise: (self abs > aDouble abs
						ifTrue: [#underflowSignal]
						ifFalse: [#overflowSignal])
				receiver: aDouble
				selector: #/
				arg: self
				errorString: 'Can''t represent the quotient as a Double']!

quotientFromFloat: aFloat

	^aFloat asDouble / self!

quotientFromFraction: aFraction

	^aFraction asDouble / self!

quotientFromInteger: anInteger

	^anInteger asDouble / self!

sumFromDouble: aDouble
	"Presumably here because Double + failed.
	If the receiver's magnitude is very small, then aDouble's magnitude
		must be very small, and the calculation underflowed.
	Otherwise, both are very large and the calculation overflowed"

	^self class
		raise: (self abs > 1.0
				ifTrue: [#overflowSignal]
				ifFalse: [#underflowSignal])
		receiver: aDouble
		selector: #+
		arg: self
		errorString: 'Can''t represent the sum as a Double'!

sumFromFloat: aFloat

	^aFloat asDouble + self!

sumFromFraction: aFraction

	^aFraction asDouble + self!

sumFromInteger: anInteger

	^anInteger asDouble + self! !

!Double methodsFor: 'converting'!

asDouble
	"Answer the receiver itself."

	^self!

asFloat
	"Answer the receiver as a float.
	If the receiver's magnitude is too great to store in a float
		raise an overflow signal
	If the receiver's magnitude is too small (the magnitude is too
		small for a float), raise an underflow signal"

	<primitive: 588>
	^self class
		raise: (self abs > 1.0
				ifTrue: [#overflowSignal]
				ifFalse: [#underflowSignal])
		receiver: self
		selector: #asFloat
		errorString: 'This double can''t be represented in a float'! !

!Double methodsFor: 'private: private'!

defaultNumberOfDigits
	"Answer how many digits of accuracy this class supports"

	^14!

exponent
	"Answer the SmallInteger to whose power two is raised.
	Consider the receiver to be represented as a power of 
	two multiplied by a mantissa (between one and two)"

	| positive |

	<primitive: 573>
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
	the argument"

	<primitive: 574>
	^self * (2 asDouble raisedToInteger: anInteger)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Double class
	instanceVariableNames: 'notANumberClass '!


!Double class methodsFor: 'class initialization'!

initialize
	"Constants from Computer Approximations, pp. 182-183 
	Pi = 3.14159265358979323846264338327950288 
	Pi/2 = 1.57079632679489661923132169163975144 
	Pi/4 = 0.78539816339744830961566084581987572 
	Pi*2 = 6.28318530717958647692528676655900576 
	Pi/180 = 0.01745329251994329576923690768488612 
	2.0 ln = 0.69314718055994530941723212145817657 
	2.0 sqrt = 1.41421356237309504880168872420969808"

	"Double initialize."

	Pi := -1 asDouble arcCos.
	RadiansPerDegree := Pi / 180.0.
	(Smalltalk includesKey: #NotANumber)
		ifTrue:	[notANumberClass := NotANumber]! !

!Double class methodsFor: 'instance creation'!

coerceFloat: aNumber
	"Answer a floating point number that represents aNumber"

	^aNumber asDouble!

fromNumber: aNumber 
	"Answer a Double that represents the same value as aNumber. 
	Fails the primitive if aNumber is a Double, or if it cannot be coerced
	to a Double"

	<primitive: 560>
	aNumber class == self
		ifTrue:	[^aNumber].
	aNumber class == Float
		ifTrue:	[^self primitiveFailed].
	^Object errorSignal
		handle: [:ex | ex returnWith: (self
				raise: #coercionErrorSignal
				receiver: self
				selector: #fromNumber:
				arg: aNumber
				errorString: 'Can''t coerce an instance of ',aNumber class name,' to a Float')]
		do: [self fromNumber: aNumber asFloat]! !

!Double class methodsFor: 'constants access'!

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

	^self fromNumber: 1!

zero
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber + aNumber class zero = aNumber

	This must be true regardless of how a given subclass chooses to define #+"

	^self fromNumber: 0! !

Double initialize!
