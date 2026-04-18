'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:15 pm'!

Stream subclass: #Random
	instanceVariableNames: 'seed increment modulus fmodulus multiplier '
	classVariableNames: 'DefaultGenerator Increments MaxGenerator Moduli Multipliers '
	poolDictionaries: ''
	category: 'Magnitude-Numbers'!
Random comment:
'An instance of class Random provides an endless supply of random numbers.
We produce a uniform deviate in the half-open interval [0.0,1.0) using a
linear congruential generator.

See "Numerical Recipes" (W.H. Press, B.P. Flannery, S.A. Teukolsky, W.T. Vetterling;
Cambridge University Press 1986), pp. 191-199.

Instance Variables:
	seed			<Integer> the first of the series.
	increment		<Integer>
	modulus			<Integer>
	multiplier		<Integer>
	fmodulus		<Float>
					The recurrance parameters.

Class Variables:
	DefaultGenerator	<Integer> used to choose a generator if the client
						doesn''t select one.
	MaxGenerator		<Integer> Highest numbered generator permitted;
						this is the length of the 3 arrays named below.
	Increments			<Array of: Integer>
	Moduli				<Array of: Integer>
	Multipliers			<Array of: Integer>
						Constants for the recurrance parameters.  generator:
						selects from these, e.g. generator #2 uses:
							{Increments at: 2, Moduli at:2, Multipliers at: 2}.'!


!Random methodsFor: 'accessing'!

contents
	"Random numbers do not have a contents so provide
	an error notification."

	^self shouldNotImplement!

next
	"Answer the next random number."

	^self step asFloat / fmodulus!

nextPut: anObject
	"Random numbers do not implement nextPut: so provide an
	error notification."

	^self shouldNotImplement!

{Integer} upTo: limit {Integer}
	"produce a random integer from 0 (inclusive) to limit (exclusive)"
	| tester |
	tester _ self next.
	ArithmeticValue overflowSignal 
		handle: [:ex | ^ (self upTo: (limit bitShift: -16)) * 65536 +
					"(65536 * self next) truncated + "
					(65536 * self next) truncated]
		do: [^(tester * limit) truncated]! !

!Random methodsFor: 'testing'!

atEnd
	"Answer false that the stream is not at an end."

	^false! !

!Random methodsFor: 'private: private'!

generator: aSmallInteger 
	"Chooses a parameter triplet."

	| generatorIndex |
	generatorIndex _ aSmallInteger.
	generatorIndex < 1 | (generatorIndex > MaxGenerator)
		ifTrue: 
			[self error: 'No such generator; proceed for generator #1'.
			generatorIndex _ 1].
	increment _ Increments at: generatorIndex.
	modulus _ Moduli at: generatorIndex.
	fmodulus _ modulus asFloat.
	multiplier _ Multipliers at: generatorIndex!

seed: aSmallInteger
	"Initialize the first random number."
	
	seed _ aSmallInteger  \\ modulus!

setSeed
	"Initialize the first random number."
	
	seed _ Time millisecondClockValue bitAnd: 65535
		"Time millisecondClockValue gives a large integer;  I only want the lower 16 bits."!

step
	"Produce the next random seed."

	^seed _ seed * multiplier + increment \\ modulus! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Random class
	instanceVariableNames: ''!


!Random class methodsFor: 'class initialization'!

initialize
	"Set the recurrance parameter constants."
	"These values are appropriate for   
		SmallInteger maxVal = ((2 raisedToInteger: 29) - 1)"
	"Random initialize"

	DefaultGenerator _ 1.
	MaxGenerator _ 7.
	Moduli _ #(120050 214326 244944 233280 175000 121500 145800).
	Multipliers _ #(2311 1807 1597 1861 2661 4081 3661).
	Increments _ #(25367 45289 51749 49297 36979 25673 30809)! !

!Random class methodsFor: 'instance creation'!

fromGenerator: g seededWith: s 
	"Answer a new random number generator."

	| r |
	r _ self basicNew.
	r generator: g.
	r seed: s.
	^r!

new
	"Answer a new random number generator, seeded from the time-of-day. "
	"The simple, naive interface..."

	^self fromGenerator: DefaultGenerator
		  seededWith: Time millisecondClockValue! !

Random initialize!
