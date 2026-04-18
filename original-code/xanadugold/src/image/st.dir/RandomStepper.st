'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:30 pm'!

Stepper subclass: #RandomStepper
	instanceVariableNames: '
		nSeeds {UInt4}
		p {UInt4}
		q {UInt4}
		seeds {UInt4Array}
		currVal {UInt4}
		idx {UInt4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-psrand'!
RandomStepper comment:
'This is a Fibonacci style pseudo random number generator.
Once initialized, values are produced by adding elements from
an array of numbers.  The array has a length N, and two
indices P and Q, which are separated by some distance D.
This array is filled initially with N numbers produces by a
congruential pseudo-random number generator from a given seed.
The contents of this array should not all be even.
The two indices are initially P==0 and Q==D.  Each value
is then
	(seed[P] + seed[Q]) mod MAXINT.
When the next value is needed, seed[P] receives the above
value, and P and Q are incremented modulo N.  The effect
with a word size S, is that a seed with S*N bits where groups
of S bits separated by S*D bits are mixed together with each step.
If N and D are mutually prime, all bits will eventually influence all
other bits yielding cycles with lengths greatly exceeding the number
range.  One pair of N and D, 11 and 5, respectively, seem to work
work quite well, while only needing a small seed array.
Empirically, this seems to generate uniformly distributed values.
According to my source for this algorithm (Van Nostrand Encyclopedia
of Computer Science, "random numbers"), this passes most
randomness tests.  (Actually, I picked this up from one of the
Ann Arbor hackers ages ago, who in turn read about it in an
article by Guy Steele.  The encyclopedia also happens to mention
it.)
'!

(RandomStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RandomStepper methodsFor: 'private: private create'!

create: seed {UInt32} with: numSeeds {UInt32} with: sep {UInt32} 
	"This constructor produces a new sequence"
	| gen {UInt32} |
	super create.
	seeds _ UInt32Array make: numSeeds.
	nSeeds _ numSeeds.
	p _ UInt32Zero.
	q _ p + sep.
	gen _ seed.
	UInt32Zero almostTo: nSeeds do: [ :i {UInt32} |
		"This loop uses a standard congruential pseudorandom number generator to produce the seed data
		for the Fibonacci generator.  The intermediate value in the expression producing 'gen,' below, is not to
		exceed 2^32."
		seeds at: i storeUInt: gen.
		gen _ (gen * 65497 + 379) bitAnd: Integer MAXINT].
	currVal _ ((seeds uIntAt: p) + (seeds uIntAt: q)) bitAnd: Integer MAXINT.
	idx _ UInt32Zero!

create: origSeeds {UInt32Array} with: numSeeds {UInt32} with: initP {UInt32} with: initQ {UInt32} with: index {UInt32}
	"This constructor is used by copy to clone an existing sequence"
	super create.
	seeds _ UInt32Array make: numSeeds.
	nSeeds _ numSeeds.
	p _ initP.
	q _ initQ.
	UInt32Zero almostTo: nSeeds do: [ :i {UInt32} |
		seeds at: i store: (origSeeds fetch: i)].
	currVal _ ((seeds fetch: p) + (seeds fetch: q)) bitAnd: Integer MAXINT.
	idx _ index!

{void} destruct
	seeds destroy.
	super destruct! !

!RandomStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	^ currVal integer!

{BooleanVar} hasValue
	^ true!

{void} step
	seeds at: p storeUInt: currVal.
	p _ (p + 1) \\ nSeeds. 
	q _ (q + 1) \\ nSeeds.
	currVal _ ((seeds uIntAt: p) + (seeds uIntAt: q)) bitAnd: Integer MAXINT.
	idx _ idx + 1! !

!RandomStepper methodsFor: 'create'!

{Stepper} copy
	^ RandomStepper create: seeds with: nSeeds with: p with: q with: idx! !

!RandomStepper methodsFor: 'special'!

{IntegerVar} index
	"This indicates how many steps the sequence has taken; its utility is questionable."
	^ idx!

{UInt32} value
	^ currVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RandomStepper class
	instanceVariableNames: ''!

(RandomStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RandomStepper class methodsFor: 'pseudoconstructor'!

make: seed {UInt32}
	^ RandomStepper create: seed with: 11 with: 5!

make: seed {UInt32} with: nSeeds {UInt32} with: sep {UInt32}
	^ RandomStepper create: seed with: nSeeds with: sep! !