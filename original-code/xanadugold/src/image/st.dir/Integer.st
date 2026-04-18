'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:12 pm'!

Number subclass: #Integer
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
Integer comment:
'Class Integer is a common abstract superclass for all Integer implementations.  Subclasses are SmallInteger, LargePositiveInteger, and LargeNegativeInteger.

Integer is logically a subclass of the (virtual) class Rational, along with Fraction.  Rational numbers represent the ratio of one integer to another, and may be either Integers or Fractions--hence, for most operations that do not require Integers, the two classes are interchangeable.
'!



!Integer methodsFor: 'arithmetic'!

* aNumber 
	"Answer the result of multiplying the receiver by the argument, aNumber."

	^aNumber productFromInteger: self!

+ aNumber 
	"Answer the sum of the receiver and the argument, aNumber."

	^aNumber sumFromInteger: self!

- aNumber 
	"Answer the difference between the receiver and aNumber."

	^aNumber differenceFromInteger: self!

/ aNumber 
	"Answer the result of dividing receiver by the argument, 
	anInteger, if the division is exact."

	^aNumber quotientFromInteger: self!

// aNumber 
	"Answer the result of dividing the receiver by the argument.
	The result is rounded down towards negative infinity to make it 
	a whole integer."

	| q |
	self = 0 ifTrue: [^0].
	q := self quo: aNumber.
	(q negative
		ifTrue: [q * aNumber ~= self]
		ifFalse: [q = 0 and: [self negative ~= aNumber negative]])
		ifTrue: [^q - 1"Truncate towards minus infinity"]
		ifFalse: [^q]!

quo: aNumber 
	"Answer the result of dividing the receiver by the argument.
	The result is rounded down towards zero to make it a whole integer."

	^aNumber quoFromInteger: self!

truncateDivide: aNumber 
	"Answer the result of dividing the receiver by the argument.
	The result is rounded down towards negative infinity to make it 
	a whole integer."

	^ self // aNumber! !

!Integer methodsFor: 'accessing'!

at: index 
	"Override implementation in Object since Integer
	instances are not element indexable using this protocol."

	^self shouldNotImplement!

at: index put: value 
	"Override implementation in Object since Integer
	instances are not element indexable using this protocol."

	^self shouldNotImplement!

denominator
	"Answer the denominator of the receiver. Integers are a special case 
	of Rational numbers where the denominator is 1 and the numerator 
	is the value itself"

	^1!

digitAt: n 
	"Answer the value of an apparent indexable field."

	^self subclassResponsibility!

digitAt: index put: value 
	"Store the argument value in the indexable field of the receiver  
	indicated by index.  Answer with the value that was stored."

	^self subclassResponsibility!

digitLength
	"Answer the number of bytes needed to represent the absolute value
	of the receiver."

	^self subclassResponsibility!

lastDigit
	"Answer the last digit of the integer."

	^self digitAt: self digitLength!

lastDigitGet: digit 
	"Store the argument, digit, as the last digit of the integer.
	Answer digit."

	^self digitAt: self digitLength put: digit!

numerator
	"Answer the numerator of the receiver. Integers are a special case of 
	Rational numbers where the denominator is 1 and the numerator is 
	the value itself"

	^self!

size
	"Override implementation in Object since Integer
	instances are not element indexable using this protocol."

	^self shouldNotImplement! !

!Integer methodsFor: 'testing'!

even
	"Answer whether the receiver is an even number."

	^((self digitAt: 1) bitAnd: 1) = 0!

isInteger
	"Answer that the receiver is an Integer."

	^true!

isZero
	"Answer whether 'self = self class zero'.  We can't use #= because
	#= is defined in terms of #isZero"

	1 to: self digitLength do:
		[ :i |  (self digitAt: i) = 0
					ifFalse:	[^false]].
	^true!

odd
	"Answer whether the receiver is an odd number."

	^((self digitAt: 1) bitAnd: 1) = 1! !

!Integer methodsFor: 'comparing'!

< anInteger
	"Answer whether the receiver is less than the argument."

	^anInteger lessFromInteger: self!

hash
	"Answer a SmallInteger unique to the receiver."

	^(self lastDigit bitShift: 8) + (self digitAt: 1)! !

!Integer methodsFor: 'truncation and round off'!

ceiling
	"Answer the receiver itself."
	
	^self!

floor
	"Answer the receiver itself."
	
	^self!

lo3bytes
	"Return the SmallInteger which is the effect of bitAnding with 16rFFFFFF"
	
	^ self!

rounded
	"Answer the receiver itself."
	
	^self!

truncated
	"Answer the receiver itself."

	^self! !

!Integer methodsFor: 'enumerating'!

timesRepeat: aBlock 
	"Evaluate the argument, aBlock, the number of times represented by
	the receiver."

	| count |
	count := 1.
	[count <= self]
		whileTrue: 
			[aBlock value.
			count := count + 1]! !

!Integer methodsFor: 'factorization and divisibility'!

factorial
	"Answer the factorial of the receiver. Fail if the 
	receiver is less than 0. 
	
	For example, 6 factorial == 6*5*4*3*2*1."

	| tmp |
	self < 0
		ifTrue: [^self class
			raise: #domainErrorSignal
			receiver: self
			selector: #factorial
			errorString: 'Factorial is invalid on negative numbers'].
	tmp := 1.
	2 to: self do: [:i | tmp := tmp * i].
	^tmp!

gcd: anInteger 
	"Answer the greatest common divisor of the receiver and anInteger."
	"Euclid's algorithm."

	| m n t |
	m := self abs max: anInteger abs.
	n := self abs min: anInteger abs.
	[n = 0]
		whileFalse: 
			[t := n.
			n := m \\ n.
			m := t].
	^m!

lcm: n 
	"Answer the least common multiple of the receiver and the argument, n."

	^self // (self gcd: n) * n! !

!Integer methodsFor: 'bit manipulation'!

allMask: mask 
	"Treat the argument as a bit mask.  Answer whether all of the
	bits that are 1 in the argument are 1 in the receiver."

	^mask = (self bitAnd: mask)!

anyMask: mask 
	"Treat the argument as a bit mask.  Answer whether any of the
	bits that are 1 in the argument are 1 in the receiver."

	^0 ~= (self bitAnd: mask)!

bitAnd: aNumber 
	"Answer the logical AND of the twos-complement  
	representation of the receiver with the twos-complement 
	representation of the argument."

	^self
		digitLogic: aNumber
		op: #bitAnd:
		length: (self digitLength max: aNumber digitLength)!

bitAt: i 
	"Answer the bit at the ith position."

	^(self bitAnd: (1 bitShift: i - 1)) = 0
		ifTrue: [0]
		ifFalse: [1]!

bitInvert
	"Answer an Integer whose bits are the complement of the receiver."

	^-1 - self!

bitOr: aNumber 
	"Answer the logical OR of the twos-complement  
	representation of the receiver with the twos-complement 
	representation of the argument."

	^self
		digitLogic: aNumber
		op: #bitOr:
		length: (self digitLength max: aNumber digitLength)!

bitShift: anInteger   
	"Answer the result of a logical SHIFT of the twos-complement    
	representation of the receiver with the twos-complement   
	representation of the argument.  Shift left if the argument is  
	positive, right if the argument is negative.  Zeros are shifted in from 
	the right in left shifts.  The sign bit is extended in right shifts."

	| result abs |
	anInteger >= 0 ifTrue: [^(self
			digitLshift: (anInteger bitAnd: 7)
			bytes: (anInteger bitShift: -3)
			lookfirst: true) compressed].
	abs := 0 - anInteger.
	result := (self
				digitRshift: (abs bitAnd: 7)
				bytes: (abs bitShift: -3)
				lookfirst: self digitLength) compressed.
	(self negative and: [self anyBitTo: abs])
		ifTrue: [result := result - 1].
	^result!

bitShiftRight: anInteger   
	
	^ self bitShift: (anInteger negated)!

bitXor: aNumber 
	"Answer the result of a logical XOR of the twos-complement  
	representation of the receiver with the twos-complement 
	representation of the argument."

	^self
		digitLogic: aNumber
		op: #bitXor:
		length: (self digitLength max: aNumber digitLength)!

highBit
	"Answer the index of the high order bit of the binary
	representation of the receiver."

	^self subclassResponsibility!

maskClear: mask 
	"Treat the argument as a bit mask.  Answer a copy of the receiver with the
	corresponding bits turned off."

	^self bitAnd: (mask bitInvert)!

maskSet: mask 
	"Treat the argument as a bit mask.  Answer a copy of the receiver with the
	corresponding bits turned on."

	^self bitOr: mask!

noMask: mask 
	"Treat the argument as a bit mask.  Answer whether none of the bits
	that are 1 in the argument are 1 in the receiver."

	^0 = (self bitAnd: mask)! !

!Integer methodsFor: 'coercing'!

coerce: aNumber
	"Convert a number to a compatible form"

	^aNumber asInteger!

generality
	"Answer the number representing the ordering of the receiver in the
	generality hierarchy."

	^40! !

!Integer methodsFor: 'double dispatching'!

differenceFromDouble: aDouble

	^aDouble - self asDouble!

differenceFromFloat: aFloat

	^aFloat - self asFloat!

differenceFromFraction: aFraction 
	"Reduction should be unnecessary"

	^aFraction species
		numerator: aFraction numerator - (self * aFraction denominator)
		denominator: aFraction denominator!

differenceFromInteger: aNumber 
	"Answer the difference between the receiver and aNumber."

	self negative == aNumber negative
		ifTrue: [^aNumber digitSubtract: self]
		ifFalse: [^aNumber digitAdd: self]!

lessFromDouble: aDouble

	^aDouble < self asDouble!

lessFromFloat: aFloat

	^aFloat < self asFloat!

lessFromFraction: aFraction

	^aFraction numerator < (self * aFraction denominator)!

lessFromInteger: anInteger 
	"Answer whether the receiver is less than the argument."

	self negative == anInteger negative
		ifTrue: [anInteger negative
				ifTrue: [^(anInteger digitCompare: self) > 0]
				ifFalse: [^(anInteger digitCompare: self) < 0]]
		ifFalse: [^anInteger negative]!

productFromDouble: aDouble

	^aDouble * self asDouble!

productFromFloat: aFloat

	^aFloat * self asFloat!

productFromFraction: aFraction 

	^(aFraction species
		numerator: aFraction numerator * self
		denominator: aFraction denominator) reduced!

productFromInteger: aNumber 
	"Answer the result of multiplying the receiver by the argument, 
	aNumber."

	^(self digitMultiply: aNumber neg: self negative ~~ aNumber negative) compressed!

quoFromInteger: anInteger 
	"Answer the result of dividing the receiver by the argument. 
	The result is rounded down towards zero to make it a whole integer."

	^((anInteger
		digitDiv: self
		neg: self negative ~~ anInteger negative)
		at: 1) compressed!

quotientFromDouble: aDouble

	^aDouble / self asDouble!

quotientFromFloat: aFloat

	^aFloat / self asFloat!

quotientFromFraction: aFraction 

	^(aFraction species
		numerator: aFraction numerator
		denominator: aFraction denominator * self) reduced!

quotientFromInteger: aNumber 
	"Answer the result of dividing receiver by the argument, 
	anInteger, if the division is exact."

	^(Fraction numerator: aNumber denominator: self) reduced!

sumFromDouble: aDouble

	^aDouble + self asDouble!

sumFromFloat: aFloat

	^aFloat + self asFloat!

sumFromFraction: aFraction 
	"Reduction should be unnecessary"

	^aFraction species
		numerator: aFraction numerator + (self * aFraction denominator)
		denominator: aFraction denominator!

sumFromInteger: aNumber 
	"Answer the sum of the receiver and the argument, aNumber."

	self negative == aNumber negative
		ifTrue: [^(aNumber digitAdd: self) compressed]
		ifFalse: [^aNumber digitSubtract: self]! !

!Integer methodsFor: 'converting'!

asCharacter
	"Answer the Character whose value is the receiver."

	^Character value: self!

asDouble
	"Answer a Float that represents the receiver."

	| factor sum |
	sum := 0.0 asDouble.
	factor := self sign asDouble.
	1 to: self digitLength do: 
		[:i | 
		sum := factor * (self digitAt: i) + sum.
		factor := factor * 256.0].
	^sum!

asFloat
	"Answer a Float that represents the receiver."

	| factor sum |
	sum := 0.0.
	factor := self sign asFloat / 256.0.
	1 to: self digitLength do:
		[:i | sum := (factor := factor * 256.0) * (self digitAt: i) + sum].
	^sum!

asInteger
	"Answer the receiver itself."

	^self!

asRational
	"Answer a Rational number that represents the receiver.
	Integers are Rational"

	^self!

reduceGeneralityIfPossible
	"Answer the receiver transformed to a lower generality, if such a 
	transformation is possible without losing information. If not, answer 
	the receiver"

	^self compressed! !

!Integer methodsFor: 'printing'!

isLiteral
	"Answer that the receiver has a literal text form recognized 
	by the compiler. "

	^true!

printOn: aStream 
	"Print a representation of the receiver on the stream, aStream, in
	base 10."

	self printOn: aStream base: 10	"default print radix"!

printOn: aStream base: b 
	"Print a representation of the receiver on the stream, aStream, in
	base b where 2<=b<=256."

	| digits source dest i j pos t rem |
	i := self digitLength.
	"Estimate size of result, conservatively"
	digits := Array new: i * 8.
	pos := 0.
	dest := 
		i <= 1
			ifTrue: [self]
			ifFalse: [Integer new: i neg: false].
	source := self.
	[i > 1]
		whileTrue: 
			[rem := 0.
			j := i.
			[j > 0]
				whileTrue: 
					[t := (rem bitShift: 8) + (source digitAt: j).
					dest digitAt: j put: t // b.
					rem := t \\ b.
					j := j - 1].
			pos := pos + 1.
			digits at: pos put: rem.
			source := dest.
			(source digitAt: i) = 0 ifTrue: [i := i - 1]].
	(dest digitAt: 1) printOn: aStream base: b.
	[pos > 0]
		whileTrue:
			[aStream nextPut: (Character digitValue: (digits at: pos)).
			pos := pos - 1]!

printStringRadix: radix 
	"Answer a String representing the receiver as a base radix integer."

	| aStream |
	aStream := WriteStream on: (String new: 16).
	self printOn: aStream base: radix.
	^aStream contents!

storeStringRadix: radix 
	"Answer a String representing the receiver as a base radix integer in 
	Smalltalk syntax (e.g. 8r377)."

	| aStream |
	aStream := WriteStream on: (String new: 16).
	radix ~= 10
		ifTrue: 
			[radix printOn: aStream.
			aStream nextPutAll: 'r'].
	self printOn: aStream base: radix.
	^aStream contents! !

!Integer methodsFor: 'fileIn/Out'!

isManifest
	"Answer whether receiver is manifestly storable."

	^true!

storeBinaryOn: stream 
	"Put a binary representation of the receiver into stream."

	stream storeInteger: self! !

!Integer methodsFor: 'private: private'!

anyBitTo: pos 
	"Answer whether any bit from 1 to pos is non-zero, for testing for loss 
	of significant bits when shifting right"

	1 to: pos - 1 // 8 do: [:i | (self digitAt: i) ~= 0 ifTrue: [^true]].
	^(self digitAt: pos + 7 // 8)
		anyMask: (#(1 3 7 15 31 63 127 255 ) at: pos - 1 \\ 8 + 1)!

digitAdd: arg	
	"Answer the result of adding the receiver to the argument, arg."

	| len arglen i accum sum |
	accum := 0.
	(len := self digitLength) < (arglen := arg digitLength) ifTrue: [len := arglen].
	"Open code max: for speed"
	sum := Integer new: len neg: self negative.
	i := 1.
	[i <= len]
		whileTrue: 
			[accum := (accum bitShift: -8) + (self digitAt: i) + (arg digitAt: i).
			sum digitAt: i put: (accum bitAnd: 255).
			i := i + 1].
	accum > 255
		ifTrue: 
			[sum := sum growBy: 1.
			sum lastDigitGet: (accum bitShift: -8)].
	^sum!

digitCompare: arg 
	"Answer the result of comparing the receiver to the
	argument, arg, where both are presumed to have the
	same sign.  Answer -1 if arg is less than the receiver,
	1 if arg is greater than the receiver, and 0 otherwise."

	| len arglen t5 t6 |
	len := self digitLength.
	(arglen := arg digitLength) ~= len 
		ifTrue: [arglen > len
					ifTrue: [^-1]
					ifFalse: [^1]].
	[len > 0]
		whileTrue: 
			[(t5 := arg digitAt: len) ~= (t6 := self digitAt: len) 
				ifTrue: [t5 < t6
							ifTrue: [^1]
							ifFalse: [^-1]].
			len := len - 1].
	^0!

digitDiv: arg neg: ng 
	"Answer an array of (quotient, remainder) that is the receiver 
	divided by the argument arg and where the argument neg is a	 
	flag determining whether the result is negative or not."

	| quo rem ql d div dl al v1 v2 |
	((al := arg digitLength) = 1 and: [(arg digitAt: 1) = 0])
		ifTrue: [^self class
				raise: #divisionByZeroSignal
				receiver: self
				selector: #digitDiv:neg:
				args: (Array with: arg with: ng)
				errorString: 'Can''t divide by zero--Integer division'].
	ql := self digitLength - al + 1.
	ql <= 0 ifTrue: [^Array with: 0 with: self].
	d := 8 - arg lastDigit highBit.
	rem := self
				digitLshift: d
				bytes: 0
				lookfirst: false.
	div := arg
				digitLshift: d
				bytes: 0
				lookfirst: false.
	quo := Integer new: ql neg: ng.
	dl := div digitLength - 1."makes a copy and shifts"
	v1 := div digitAt: dl.
	v2 := dl = 1 ifTrue: [0]
				ifFalse: [div digitAt: dl - 1].
	1 to: ql do: 
		[:k | 
		| l j a q uj uj1 uj2 |
		j := rem digitLength + 1 - k.
		uj := (rem digitAt: j) bitShift: 8.
		uj1 := rem digitAt: j - 1.
		(rem digitAt: j) = v1
			ifTrue: [q := 255]
			ifFalse: [q := uj + uj1 // v1].
		uj2 := j < 3 ifTrue: [0]
					ifFalse: [rem digitAt: j - 2].
		[v2 * q > ((uj + uj1 - (q * v1) bitShift: 8) + uj2)]
			whileTrue: [q := q - 1].
		l := j - dl.
		a := 0.
		1 to: dl+1 do: 
			[:i | 
			"Subtract q*div from rem"
			a := (a bitShift: -8) + (rem digitAt: l) - ((div digitAt: i) * q).
			rem digitAt: l put: (a bitAnd: 255).
			l := l + 1].
		a < 0
			ifTrue: 
				["Add div back into rem, decrease q by 1"
				q := q - 1.
				l := j - dl.
				a := 0.
				1 to: div digitLength do: 
					[:i | 
					a := (a bitShift: -8) + (rem digitAt: l) + (div digitAt: i).
					rem digitAt: l put: (a bitAnd: 255).
					l := l + 1]].
		quo digitAt: quo digitLength + 1 - k put: q].
	rem := rem
				digitRshift: d
				bytes: 0
				lookfirst: dl.
	^Array with: quo with: rem!

digitLogic: arg op: op length: len 
	"Perform the indicated bit-wise operation between the
	reciever and arg.  This implementation depends on the
	fact that new Integers are initialized to be all zeros"

	| result neg1 neg2 rneg z1 z2 rz b1 b2 b rdigits |
	neg1 := self negative.
	neg2 := arg negative.
	rneg := 
		((neg1 ifTrue: [-1] ifFalse: [0])
			perform: op 
			with: (neg2
					ifTrue: [-1]
					ifFalse: [0])) < 0.
	result := Integer new: len neg: rneg.
	rz := z1 := z2 := true.
	rdigits := 1.
	1 to: result digitLength do: 
		[:i | 
		b1 := self digitAt: i.
		neg1 
			ifTrue: [b1 := z1
						ifTrue: [b1 = 0
									ifTrue: [0]
									ifFalse: 
										[z1 := false.
										256 - b1]]
						ifFalse: [255 - b1]].
		b2 := arg digitAt: i.
		neg2 
			ifTrue: [b2 := z2
						ifTrue: [b2 = 0
									ifTrue: [0]
									ifFalse: 
										[z2 := false.
										256 - b2]]
						ifFalse: [255 - b2]].
		b := b1 perform: op with: b2.
		rneg
			ifTrue:
				[rz
					ifTrue:
						[b = 0
							ifFalse:
								[result digitAt: i put: 256 - b.
								rdigits := i.
								rz := false]]
					ifFalse:
						[b := 255 - b.
						b = 0
							ifFalse:
								[result digitAt: i put: b.
								rdigits := i]]]
			ifFalse:
				[b = 0
					ifFalse:
						[result digitAt: i put: b.
						rdigits := i]]].
	rdigits ~= len ifTrue: [^(result growTo: rdigits) compressed].
	^result compressed!

digitLshift: n bytes: b lookfirst: a 
	 "Shift left 8*b+n bits, 0<=n<8.  Discard all digits beyond a,
	and all zeroes at or below a."

	| x f m len r digit |
	"shift by 8*b+n bits, 0<=n<8.  a true means check for a leading zero byte in the 
	result "
	x := 0.
	f := n - 8.
	m := 255 bitShift: 0 - n.
	len := self digitLength + 1 + b.
	(a and: [(self lastDigit bitShift: f) = 0])
		ifTrue: [len := len - 1].
	r := Integer new: len neg: self negative.
	1 to: b do: [:i | r digitAt: i put: 0].
	1 to: len - b do: 
		[:i | 
		digit := self digitAt: i.
		r 
			digitAt: i + b 
			put: (((digit bitAnd: m) bitShift: n) bitOr: x).
		"Avoid values > 8 bits"
		x := digit bitShift: f].
	^r!

digitMultiply: arg neg: ng 
	"Answer the result of multiplying the receiver by
	the argument arg, where the sign of the result is ng."

	| argSize mySize prod pl digit k acc |
	argSize := arg digitLength.
	((arg digitAt: 1) = 0 and: [argSize = 1]) ifTrue: [^0].
	mySize := self digitLength.
	pl := mySize + argSize.
	" Make a better guess at whether the product will overflow,
	to avoid having to copy the result. "
	((self digitAt: mySize) + 1) * ((arg digitAt: argSize) + 1) < 256
		ifTrue: [pl := pl - 1].
	prod := Integer new: pl neg: ng.
	"prod starts out all zero"
	1 to: mySize do: 
		[:i |
		acc := 0.
		(digit := self digitAt: i) ~= 0
			ifTrue: 
				[k := i.
				"Loop invariant: 0<=acc<=16rFFFF, k=i+j-1"
				1 to: argSize do: 
					[:j | 
					acc := (arg digitAt: j) * digit + (prod digitAt: k) + (acc bitShift: -8).
					prod digitAt: k put: (acc bitAnd: 255).
					k := k + 1].
				acc >= 256
					ifTrue:
						[prod digitAt: k put: (acc bitShift: -8)]]].
	^prod compressed!

digitRshift: anInteger bytes: b lookfirst: a 
	 "Shift right 8*b+anInteger bits, 0<=anInteger<8.  Discard all digits beyond a,
	and all zeroes at or below a."

	| n x r f m digit count i |
	n := 0 - anInteger.
	x := 0.
	f := n + 8.
	i := a.
	m := 255 bitShift: 0 - f.
	digit := self digitAt: i.
	[((digit bitShift: n) bitOr: x) = 0 and: [i ~= 1]] whileTrue:
		[x := digit bitShift: f "Can't exceed 8 bits".
		i := i - 1.
		digit := self digitAt: i].
	i <= b ifTrue: [^Integer new: 0 neg: self negative].  "All bits lost"
	r := Integer new: i - b neg: self negative.
	count := i.
	x := (self digitAt: b + 1) bitShift: n.
	b + 1 to: count do:
		[:j | digit := self digitAt: j + 1.
		r digitAt: j - b put: (((digit bitAnd: m) bitShift: f) bitOr: x) 
			"Avoid values > 8 bits".
		x := digit bitShift: n].
	^r!

digitSubtract: arg 
	"Answer the result of subtracting the argument arg
	from the receiver."

	| smaller larger i z sum sl al ng lastdigit |
	sl := self digitLength.
	al := arg digitLength.
	(sl = al
		ifTrue: 
			[[(self digitAt: sl) = (arg digitAt: sl) and: [sl > 1]]
				whileTrue: [sl := sl - 1].
			al := sl.
			(self digitAt: sl) < (arg digitAt: sl)]
		ifFalse: [sl < al])
		ifTrue: 
			[larger := arg.
			smaller := self.
			ng := self negative == false.
			sl := al]
		ifFalse: 
			[larger := self.
			smaller := arg.
			ng := self negative].
	sum := Integer new: sl neg: ng.
	lastdigit := 1.
	z := 0.
	"Loop invariant is -1<=z<=1"
	i := 1.
	[i <= sl]
		whileTrue: 
			[z := z + (larger digitAt: i) - (smaller digitAt: i).
			(sum digitAt: i put: (z bitAnd: 255)) ~= 0 ifTrue: [lastdigit := i].
			z := z bitShift: -8.
			i := i + 1].
	lastdigit = sl ifFalse: [sum := sum growTo: lastdigit].
	^sum compressed!

growBy: n 
	"Answer a copy of the receiver that is increased
	in size by n."

	^self growTo: self digitLength + n!

growTo: n 
	"Answer a copy of the receiver whose size is n."

	| x |
	x := self species basicNew: n.
	1 to: (self digitLength min: n)
		do: [:i | x digitAt: i put: (self digitAt: i)].
	^x! !

!Integer methodsFor: 'translator hack'!

asInt
	^self!

asLong
	^self!

basicCast: someClass
	someClass == Character ifTrue: [^ Character value: self].
	^ self!

DOTasInt
	^self!

DOTasInt32
	^self!

DOTasLong
	^self!

DOTasUInt32
	^self!

DOThashForEqual
	"^ (self * 99991 * 98953 // 14741) bitShiftRight: 2"
	^ ((self * 99991 bitAnd: 268435455) bitXor: 98953) bitShiftRight: 6  "smalltalk version"
	"^ (((self bitXor: 99991) * 98953) bitAnd: 268435455) bitShiftRight: 6" "c++ version"
	"actually, the c++ version should not to a bitAnd:, use the implicit modulus of the wordsize
	to get the same effect.  Smalltalk is just TOO nice about keeping all those bits....
	The bitshiftRight: of 6 bits appears to be an appropriate amount of bits to discard after
	several tests through a simple histogram on moduluses of 7 and 31"!

hashForEqual
	"^ (self * 99991 * 98953 // 14741) bitShiftRight: 2"
	^ (((self * 99991) lo3bytes) bitXor: 98953) bitShiftRight: 6  "smalltalk version"
	"^ (((self bitXor: 99991) * 98953) bitAnd: 268435455) bitShiftRight: 6" "c++ version"
	"actually, the c++ version should not to a bitAnd:, use the implicit modulus of the wordsize
	to get the same effect.  Smalltalk is just TOO nice about keeping all those bits....
	The bitshiftRight: of 6 bits appears to be an appropriate amount of bits to discard after
	several tests through a simple histogram on moduluses of 7 and 31"!

integer
	^ IntegerPos create: self!

isGE: arg
	^self >= arg!

minus: arg
	^self - arg!

plus: arg
	^self + arg!

{Behavior} publicClass
	^Integer! !

!Integer methodsFor: 'primes'!

sieve
	"1013 sieve"

	| sieve limit i j  result |
	self odd ifFalse: [^ (self + 1) sieve].
	sieve _ ByteArray new: self // 2 withAll: 1.
	limit _ self sqrt truncated // 2 + 1.
	i _ 3.
	[i <= limit]
		whileTrue: 
			[j _ i * 2.
			[j <= self]
				whileTrue: [j odd ifTrue: [sieve at: j // 2 put: 0].
					j _ j + i].
			i _ i + 2.
			[i <= limit and: [(sieve at: (i // 2)) == 0]]
				whileTrue: [i _ i + 2]].
	i _ 1.
	sieve do: [:v | v == 1 ifTrue: [i _ i + 1]].
	result _ (OrderedCollection new: i).
	result add: 2.
	1 to: self // 2 do: [:idx | (sieve at: idx) ~~ 0 ifTrue: [result add: idx * 2 + 1]].
	^ result.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Integer class
	instanceVariableNames: ''!



!Integer class methodsFor: 'instance creation'!

new: length neg: neg 
	"Answer an instance of a large integer whose size is length.  
	neg is a flag determining the sign of the integer."

	neg 
		ifTrue: [^LargeNegativeInteger basicNew: length]
		ifFalse: [^LargePositiveInteger basicNew: length]!

readFrom: aStream 
	"Answer a new Integer as described on the stream, aStream."

	^self readFrom: aStream radix: 10!

readFrom: aStream radix: radix 
	"Answer an instance of one of the concrete subclasses if Integer. 
	Initial minus sign accepted, and bases > 10 use letters A-Z.
	Imbedded radix specifiers not allowed;  use Integer 
	class readFrom: for that. Answer zero if there are no digits."

	| digit value neg |
	neg := aStream peekFor: $-.
	value := 0.
	[aStream atEnd]
		whileFalse: 
			[digit := aStream next digitValue.
			(digit < 0 or: [digit >= radix])
				ifTrue: 
					[aStream skip: -1.
					neg ifTrue: [^value negated compressed "catch 0 minVal"].
					^value]
				ifFalse: [value := value * radix + digit]].
	neg ifTrue: [^value negated compressed "catch 0 minVal"].
	^value! !

!Integer class methodsFor: 'constants access'!

unity
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber * aNumber class unity = aNumber

	This must be true regardless of how a given subclass chooses to define #*"

	^(self new: 1 neg: false) digitAt: 1 put: 1; yourself!

zero
	"Answer the value which allows, for any given arithmetic value, the following to be true

		aNumber + aNumber class zero = aNumber

	This must be true regardless of how a given subclass chooses to define #+"

	^self new: 1 neg: false! !

!Integer class methodsFor: 'global: cxx hacks'!

IntegerVar: somenum {long}
	^ somenum!

make: value {long}
	"create an integer"
	^ value!

MAXINT
	^ SmallInteger maxVal!

vector
	"Return the Class for vectors of subclasses of object. The constructor is then 
	sent to the returned class."

	^IntegerVarArray! !

!Integer class methodsFor: 'client protocol'!

{String} exportName
	"See Heape::exportName."

	^'IntValue'! !