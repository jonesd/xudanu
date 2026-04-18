'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:12 pm'!

Heaper subclass: #PrimeSizeProvider
	instanceVariableNames: 'smallPrimeTable {UInt32Array}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tabtool'!
PrimeSizeProvider comment:
'This is a non-stepper stepper that returns a stream of prime numbers.

SCPrimeSizeProvider rejects many primes to be nice for secondary clustering at the cost of increased table size, LPPrimeSizeProvider does not claim to do this.

 - michael 31 July 1991'!

(PrimeSizeProvider getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!PrimeSizeProvider methodsFor: 'accessing'!

{IntegerVar} primeAfter: attempt {IntegerVar}

	| val {UInt32} idx {UInt32} lim {UInt32} |
	
	idx _ UInt32Zero.
	val _ attempt DOTasLong.
	lim _ smallPrimeTable count.
	[(idx < lim) and: [val > (smallPrimeTable uIntAt: idx)]] 
		whileTrue: [idx _ idx + 1].
	idx >= smallPrimeTable count
		ifTrue: [^ (attempt * 2) + 1]
		ifFalse: [^ Integer IntegerVar: (smallPrimeTable uIntAt: idx)]!

{UInt32} uInt32PrimeAfter: attempt {UInt32}

	| val {UInt32} idx {UInt32} lim {UInt32} |
	
	idx _ UInt32Zero.
	val _ attempt.
	lim _ smallPrimeTable count.
	[(idx < lim) and: [val > (smallPrimeTable uIntAt: idx)]] 
		whileTrue: [idx _ idx + 1].
	idx >= smallPrimeTable count
		ifTrue: [^ (attempt * 2) + 1]
		ifFalse: [^ smallPrimeTable uIntAt: idx]! !

!PrimeSizeProvider methodsFor: 'creation'!

create: aSmallPrimeTable {UInt32Array}
	super create.
	smallPrimeTable _ aSmallPrimeTable.! !

!PrimeSizeProvider methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimeSizeProvider class
	instanceVariableNames: ''!

(PrimeSizeProvider getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!PrimeSizeProvider class methodsFor: 'creation'!

{PrimeSizeProvider INLINE} make
	^LPPrimeSizeProvider make! !

!PrimeSizeProvider class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	self REQUIRES: LPPrimeSizeProvider.! !