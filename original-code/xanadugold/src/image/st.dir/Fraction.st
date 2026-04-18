'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:12 pm'!

Number subclass: #Fraction
	instanceVariableNames: 'numerator denominator '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
Fraction comment:
'Instances of class Fraction represent some rational number as a fraction.  They can be created as a result of an arithmetic operation if one of the operands is a Fraction and the other is not a Float.  All public arithmetic operations return reduced fractional results.

Fraction is logically a subclass of the (virtual) class Rational, along with Integer.  Rational numbers represent the ratio of one integer to another, and may be either Integers or Fractions--hence, for most operations that do not require Integers, the two classes are interchangeable.

Instance Variables:
	numerator 		<Integer>
	denominator 	<Integer>'!


!Fraction methodsFor: 'arithmetic'!

* aNumber 
	"Answer the result of multiplying the receiver by the argument, aNumber.
	Result is a new Fraction unless the argument is a Float, in which case
	the result is a Float."

	^aNumber productFromFraction: self!

+ aNumber 
	"Answer the sum of the receiver and the argument, aNumber.  
	Sum is a new Fraction unless the argument is a Float, in which
	case the sum is a Float."

	^aNumber sumFromFraction: self!

- aNumber  
	"Answer the difference between the receiver and the argument, aNumber.
	The difference is a new Fraction unless the argument is a Float, in which case
	the result is a Float."

	^aNumber differenceFromFraction: self!

/ aNumber 
	"Answer the result of dividing receiver by the argument, aNumber. 
	The result is a new Fraction unless the argument is a Float, in which
	case the result is a Float."

	^aNumber quotientFromFraction: self!

negated
	"Answer a Fraction that is the negation of the receiver."

	^Fraction numerator: numerator negated denominator: denominator!

reciprocal
	"Answer 1 divided by the receiver.  Result is the denominator or the
	denominator negated if the numerator of the receiver is 1 or -1 
	respectively. Else the result is a new Float.  Fail if the numerator 
	of the receiver is 0."

	numerator = 1 ifTrue: [^denominator].
	numerator = -1 ifTrue: [^denominator negated].
	^Fraction numerator: denominator denominator: numerator! !

!Fraction methodsFor: 'accessing'!

denominator
	"Answer the denominator of the receiver."

	^denominator!

numerator
	"Answer the numerator of the receiver."

	^numerator! !

!Fraction methodsFor: 'testing'!

isZero
	"Answer whether 'self = self class zero'.  We can't use #= because
	#= is defined in terms of #isZero"

	^numerator isZero! !

!Fraction methodsFor: 'comparing'!

< aFraction 
	"Answer whether the receiver is less than the argument."

	^aFraction lessFromFraction: self!

hash
	"Answer a SmallInteger unique to the receiver."

	^numerator hash bitXor: denominator hash! !

!Fraction methodsFor: 'truncation and round off'!

truncated
	"Answer an Integer nearest the receiver toward zero."

	^numerator quo: denominator! !

!Fraction methodsFor: 'coercing'!

coerce: aNumber
	"Convert a number to a compatible form"

	^aNumber asRational!

generality
	"Answer the number representing the ordering of the receiver in the
	generality hierarchy."

	^60! !

!Fraction methodsFor: 'double dispatching'!

differenceFromDouble: aDouble

	^aDouble - self asDouble!

differenceFromFloat: aFloat

	^aFloat - self asFloat!

differenceFromFraction: aFraction 

	denominator = aFraction denominator
		ifTrue: [^(self species
					numerator: aFraction numerator - numerator
					denominator: denominator) reduced].
	^(self species
		numerator: aFraction numerator * denominator - (numerator * aFraction denominator)
		denominator: denominator * aFraction denominator) reduced!

differenceFromInteger: anInteger 
	"Reduction should not be necessary"

	^self species
		numerator: anInteger * denominator - numerator
		denominator: denominator!

lessFromDouble: aDouble

	^aDouble < self asDouble!

lessFromFloat: aFloat

	^aFloat < self asFloat!

lessFromFraction: aFraction

	^aFraction numerator * denominator < (numerator * aFraction denominator)!

lessFromInteger: anInteger

	^anInteger * denominator < numerator!

productFromDouble: aDouble

	^aDouble * self asDouble!

productFromFloat: aFloat

	^aFloat * self asFloat!

productFromFraction: aFraction 

	^(self species
		numerator: aFraction numerator * numerator
		denominator: aFraction denominator * denominator) reduced!

productFromInteger: anInteger 

	^(self species
		numerator: anInteger * numerator
		denominator: denominator) reduced!

quotientFromDouble: aDouble

	^aDouble / self asDouble!

quotientFromFloat: aFloat

	^aFloat / self asFloat!

quotientFromFraction: aFraction 

	^(self species
		numerator: aFraction numerator * denominator
		denominator: aFraction denominator * numerator) reduced!

quotientFromInteger: anInteger 

	^(self species
		numerator: anInteger * denominator
		denominator: numerator) reduced!

sumFromDouble: aDouble

	^aDouble + self asDouble!

sumFromFloat: aFloat

	^aFloat + self asFloat!

sumFromFraction: aFraction 

	denominator = aFraction denominator
		ifTrue: [^(self species
					numerator: numerator + aFraction numerator
					denominator: denominator) reduced].
	^(self species
		numerator: numerator * aFraction denominator + (aFraction numerator * denominator)
		denominator: denominator * aFraction denominator) reduced!

sumFromInteger: anInteger 
	"Reduction should not be necessary"

	^self species
		numerator: anInteger * denominator + numerator
		denominator: denominator! !

!Fraction methodsFor: 'converting'!

asDouble
	"Answer a new Double that represents the same value as does the receiver."

	^numerator asDouble / denominator asDouble!

asFloat
	"Answer a new Float that represents the same value as does the receiver."

	^numerator asFloat / denominator asFloat!

asRational
	"Answer the receiver itself."

	^self!

reduceGeneralityIfPossible
	"Answer the receiver transformed to a lower generality, if such a 
	transformation is possible without losing information. If not, answer 
	the receiver"

	^self reduced! !

!Fraction methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument, aStream, the receiver's numerator
	and denominator separated by / and enclosed in parentheses."

	aStream nextPut: $(.
	numerator printOn: aStream.
	aStream nextPut: $/.
	denominator printOn: aStream.
	aStream nextPut: $)! !

!Fraction methodsFor: 'private: private'!

reduced
	"Answer a Fraction determined by finding the greatest common 
	divisor of the numerator and denominator of the receiver. Answer 
	the reduced numerator if the reduced denominator is 1."

	| gcd |
	gcd := numerator gcd: denominator.
	denominator = gcd ifTrue: [^numerator // gcd].
	gcd = 1 ifTrue: [^self].
	^Fraction numerator: numerator // gcd denominator: denominator // gcd!

setNumerator: nInteger denominator: dInteger 
	"Initialize the instance variables. Fail if the denominator is zero."

	dInteger = 0
		ifTrue: [^self class raise: #divisionByZeroSignal
					receiver: nInteger
					selector: #/
					arg: dInteger
					errorString: 'Can''t create a Fraction with a zero denominator']
		ifFalse: 
			[numerator := nInteger truncated.
			denominator := dInteger truncated abs.
			dInteger < 0
				ifTrue: ["keep sign in numerator"
						numerator := numerator negated]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Fraction class
	instanceVariableNames: ''!


!Fraction class methodsFor: 'instance creation'!

numerator: numInteger denominator: denInteger 
	"Answer a new Fraction numInteger/denInteger."

	^self basicNew setNumerator: numInteger denominator: denInteger! !

!Fraction class methodsFor: 'constants access'!

unity
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber * aNumber class unity = aNumber

	This must be true regardless of how a given subclass chooses to define #*"

	^self numerator: 1 denominator: 1!

zero
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber + aNumber class zero = aNumber

	This must be true regardless of how a given subclass chooses to define #+"

	^self numerator: 0 denominator: 1! !