'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:14 pm'!

Number subclass: #LimitedPrecisionReal
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
LimitedPrecisionReal comment:
'LimitedPrecisionReal contains the levels of protocol that are common between the various possible representations of Real, possibly nonRational, Numbers.  The most familiar of these in a computer environment are single- and double-precision floats; more obscure forms could include Radicals and unique values such as Pi.'!


!LimitedPrecisionReal methodsFor: 'comparing'!

hash
	"Answer a SmallInteger unique to the receiver."

	^(self mantissa: 16) bitXor: (self exponent + self sign + 1)! !

!LimitedPrecisionReal methodsFor: 'truncation and round off'!

integerPart
	"Answer a new Float whose value is the receiver's truncated value."

	^self - self fractionPart! !

!LimitedPrecisionReal methodsFor: 'converting'!

asRational
	"Answer a Rational number--Integer or Fraction--representing the receiver.
	This conversion uses the continued fraction method to approximate 
	a floating point number."

	| num1 denom1 num2 denom2 int frac newD temp limit |
	limit := (self class unity * 10) raisedTo: self defaultNumberOfDigits.
	num1 := self truncated.	"The first of two alternating numerators"
	denom1 := 1.		"The first of two alternating denominators"
	num2 := 1.		"The second numerator"
	denom2 := 0.		"The second denominator--will update"
	int := num1.		"The integer part of self"
	frac := self fractionPart.		"The fractional part of self"
	[frac = 0]
		whileFalse: 
			["repeat while the fractional part is not zero"
			newD := 1.0 / frac.			"Take reciprocal of the fractional part"
			int := newD truncated.		"get the integer part of this"
			frac := newD fractionPart.	"and save the fractional part for next time"
			temp := num2.				"Get old numerator and save it"
			num2 := num1.				"Set second numerator to first"
			num1 := num1 * int + temp.	"Update first numerator"
			temp := denom2.				"Get old denominator and save it"
			denom2 := denom1.			"Set second denominator to first"
			denom1 := int * denom1 + temp.		"Update first denominator"
			limit < denom1
				ifTrue: 
					["Is ratio past float precision?  If so, pick which 
					of the two ratios to use"
					num2 = 0.0 
						ifTrue: ["Is second denominator 0?"
								^Fraction numerator: num1 denominator: denom1].
					^Fraction numerator: num2 denominator: denom2]].
	"If fractional part is zero, return the first ratio"
	denom1 = 1
		ifTrue: ["Am i really an Integer?"
				^num1"Yes, return Integer result"]
		ifFalse: ["Otherwise return Fraction result"
				^Fraction numerator: num1 denominator: denom1]!

degreesToRadians
	"Answer the conversion to radians.  The receiver is assumed to 
	represent degrees."

	^self * self class radiansPerDegree!

radiansToDegrees
	"Answer the conversion to degrees.  The receiver is assumed to 
	represent radians."

	^self / self class radiansPerDegree!

reduceGeneralityIfPossible
	"Answer the receiver transformed to a lower genrality, if such a 
	transformation is possible without losing information. If not, answer 
	the receiver"

	^self asRational! !

!LimitedPrecisionReal methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument, aStream, a literal form of the receiver 
	using a reasonable number of significant digits."

	self printOn: aStream digits: self defaultNumberOfDigits! !

!LimitedPrecisionReal methodsFor: 'private: private'!

absPrintOn: aStream digits: digits 
	"Print on aStream the receiver using the argument, digits, as the number of
	significant figures."

	| fuzz x exp q i radix |
	"x is myself normalized to [1.0, 10.0), exp is my exponent"
	radix := self class zero + 10.
	exp := 
		self < 1.0
			ifTrue: [(radix / self floorLog: radix) negated]
			ifFalse: [self floorLog: radix].

	x := self / (radix raisedTo: exp).
	fuzz := radix raisedTo: 1 - digits.
	"round the last digit to be printed"
	x := 0.5 * fuzz + x.
	x >= radix
		ifTrue: 
			["check if rounding has unnormalized x"
			x := x / radix.
			exp := exp + 1].
	(exp < 6 and: [exp > -4])
		ifTrue: 
			["decimal notation"
			q := 0.
			exp < 0
				ifTrue: [aStream nextPutAll: '0.'.
						1 to: -1 - exp do: [:j | aStream nextPut: $0]]]
		ifFalse: 
			["scientific notation"
			q := exp.
			exp := 0].
	[x >= fuzz]
		whileTrue: 
			["use fuzz to track significance"
			i := x truncated.
			aStream nextPut: (Character value: (48 + i) ).
			x := x - i * radix.
			fuzz := fuzz * radix.
			exp := exp - 1.
			exp = -1 ifTrue: [aStream nextPut: $.]].
	[exp >= -1]
		whileTrue: 
			[aStream nextPut: $0.
			exp := exp - 1.
			exp = -1 ifTrue: [aStream nextPut: $.]].
	q ~= 0
		ifTrue: 
			[aStream nextPut: $e.
			q printOn: aStream]!

mantissa: nBits
	"Answer an Integer that is the most significant nBits of the 
	mantissa of the receiver."

	^(self abs timesTwoPower: nBits-self exponent-1) truncated!

printOn: aStream digits: digits 
	"Print the receiver on aStream using the argument, digits, 
	as the number of significant figures." 

	self > 0.0
		ifTrue: [self absPrintOn: aStream digits: digits]
		ifFalse: [self = 0.0
					ifTrue: 
						[aStream nextPutAll: '0.0']
					ifFalse: 
						[aStream nextPutAll: '-'.
						self negated = 0.0
							ifTrue: [aStream nextPutAll: '0.0']
							ifFalse: [self negated absPrintOn: aStream digits: digits]]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LimitedPrecisionReal class
	instanceVariableNames: ''!


!LimitedPrecisionReal class methodsFor: 'client protocol'!

{String} exportName
	"See Heape::exportName."

	^'FloatValue'! !