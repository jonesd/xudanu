'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:11 pm'!

PrimeSizeProvider subclass: #LPPrimeSizeProvider
	instanceVariableNames: ''
	classVariableNames: 'MySoleProvider {LPPrimeSizeProvider} '
	poolDictionaries: ''
	category: 'Xanadu-tabtool'!
LPPrimeSizeProvider comment:
'This is a non-stepper stepper that returns a stream of prime numbers.

SCPrimeSizeProvider rejects many primes to be nice for secondary clustering at the cost of increased table size, LPPrimeSizeProvider does not claim to do this.

 - michael 31 July 1991'!

(LPPrimeSizeProvider getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!LPPrimeSizeProvider methodsFor: 'creation'!

create: aSmallPrimeTable {UInt32Array}
	super create: aSmallPrimeTable! !

!LPPrimeSizeProvider methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LPPrimeSizeProvider class
	instanceVariableNames: ''!

(LPPrimeSizeProvider getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!LPPrimeSizeProvider class methodsFor: 'make'!

{LPPrimeSizeProvider INLINE} make
	^ MySoleProvider! !

!LPPrimeSizeProvider class methodsFor: 'initialization'!

{UInt32Array} primeTable
	| smallPrimeTable {UInt32Array} |

	smallPrimeTable _ UInt32Array make: 71.
	smallPrimeTable at: UInt32Zero storeUInt: 7.
	smallPrimeTable at: 1 storeUInt: 19.
	smallPrimeTable at: 2 storeUInt: 41.
	smallPrimeTable at: 3 storeUInt: 67.
	smallPrimeTable at: 4 storeUInt: 101.
	smallPrimeTable at: 5 storeUInt: 139.
	smallPrimeTable at: 6 storeUInt: 191.
	smallPrimeTable at: 7 storeUInt: 241.
	smallPrimeTable at: 8 storeUInt: 313.
	smallPrimeTable at: 9 storeUInt: 401.
	smallPrimeTable at: 10 storeUInt: 499.
	smallPrimeTable at: 11 storeUInt: 617.
	smallPrimeTable at: 12 storeUInt: 751.
	smallPrimeTable at: 13 storeUInt: 911.
	smallPrimeTable at: 14 storeUInt: 1091.
	smallPrimeTable at: 15 storeUInt: 1297.
	smallPrimeTable at: 16 storeUInt: 1543.
	smallPrimeTable at: 17 storeUInt: 1801.
	smallPrimeTable at: 18 storeUInt: 2113.
	smallPrimeTable at: 19 storeUInt: 2459.
	smallPrimeTable at: 20 storeUInt: 2851.
	smallPrimeTable at: 21 storeUInt: 3331.
	smallPrimeTable at: 22 storeUInt: 3833.
	smallPrimeTable at: 23 storeUInt: 4421.
	smallPrimeTable at: 24 storeUInt: 5059.
	smallPrimeTable at: 25 storeUInt: 5801.
	smallPrimeTable at: 26 storeUInt: 6607.
	smallPrimeTable at: 27 storeUInt: 7547.
	smallPrimeTable at: 28 storeUInt: 8599.
	smallPrimeTable at: 29 storeUInt: 9697.
	smallPrimeTable at: 30 storeUInt: 11004.
	smallPrimeTable at: 31 storeUInt: 12479.
	smallPrimeTable at: 32 storeUInt: 14057.
	smallPrimeTable at: 33 storeUInt: 15803.
	smallPrimeTable at: 34 storeUInt: 17881.
	smallPrimeTable at: 35 storeUInt: 20117.
	smallPrimeTable at: 36 storeUInt: 22573.
	smallPrimeTable at: 37 storeUInt: 28499.
	smallPrimeTable at: 38 storeUInt: 32003.
	smallPrimeTable at: 39 storeUInt: 35759.
	smallPrimeTable at: 40 storeUInt: 40009.
	smallPrimeTable at: 41 storeUInt: 44729.
	smallPrimeTable at: 42 storeUInt: 50053.
	smallPrimeTable at: 43 storeUInt: 55933.
	smallPrimeTable at: 44 storeUInt: 62483.
	smallPrimeTable at: 45 storeUInt: 69911.
	smallPrimeTable at: 46 storeUInt: 77839.
	smallPrimeTable at: 47 storeUInt: 86929.
	smallPrimeTable at: 48 storeUInt: 96787.
	smallPrimeTable at: 49 storeUInt: 108041.
	smallPrimeTable at: 50 storeUInt: 120473.
	smallPrimeTable at: 51 storeUInt: 134087.
	smallPrimeTable at: 52 storeUInt: 149287.
	smallPrimeTable at: 53 storeUInt: 166303.
	smallPrimeTable at: 54 storeUInt: 185063.
	smallPrimeTable at: 55 storeUInt: 205957.
	smallPrimeTable at: 56 storeUInt: 228887.
	smallPrimeTable at: 57 storeUInt: 254663.
	smallPrimeTable at: 58 storeUInt: 282833.
	smallPrimeTable at: 59 storeUInt: 313979.
	smallPrimeTable at: 60 storeUInt: 347287.
	smallPrimeTable at: 61 storeUInt: 384317.
	smallPrimeTable at: 62 storeUInt: 424667.
	smallPrimeTable at: 63 storeUInt: 468841.
	smallPrimeTable at: 64 storeUInt: 517073.
	smallPrimeTable at: 65 storeUInt: 569927.
	smallPrimeTable at: 66 storeUInt: 627553.
	smallPrimeTable at: 67 storeUInt: 691183.
	smallPrimeTable at: 68 storeUInt: 760657.
	smallPrimeTable at: 69 storeUInt: 836483.
	smallPrimeTable at: 70 storeUInt: 919757.
	^ smallPrimeTable! !

!LPPrimeSizeProvider class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited

	self REQUIRES: UInt32Array.
	MySoleProvider _ LPPrimeSizeProvider create: self primeTable.!

linkTimeNonInherited
	MySoleProvider _ NULL.! !