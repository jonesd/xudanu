'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:12 pm'!

PrimeSizeProvider subclass: #SCPrimeSizeProvider
	instanceVariableNames: ''
	classVariableNames: '
		MySoleProvider {UNKNOWN} 
		SCMySoleProvider {SCPrimeSizeProvider} '
	poolDictionaries: ''
	category: 'Xanadu-tabtool'!
SCPrimeSizeProvider comment:
'This is a specialized table tool that provides a "reasonable" prime number greater than a provided number.  The number returned will be prime if the number passed in is < 1,000,000 (a bit less, really).   The number returned is guaranteed to be odd.

SCPrimeSizeProvider rejects many primes to be nice for secondary clustering at the cost of increased table size, LPPrimeSizeProvider does not claim to do this.

Implementation notes:

  The list of numbers that will be returned is currently initialized during init time.  It was produced by taking a stream of prime numbers, eliminating all primes m such that m-2 is not prime and taking every nth of the resulting stream, where n increased as the list was stepped over.
  By using only primes (n) where n-2 is also prime, the number is useful to provide an easy second prime.  This is useful when doing double hashing (See Knuth III).
 
 The smalltalk code to generate the table is as follows:
 
1010000 sieve inspect.

| t |
t _ IdentityGreatSet newForSize: 86000.
t addAll: self.
self select: [:it | t includes: (it - 2)] inspect.

| i inc new |
new _ OrderedCollection new.
i _ 2.
inc _ 1.0.
[i < self size] whileTrue: [
	new add: (self at: i).
	i _ i + inc truncated.
	inc _ inc + 0.45].
new inspect.

| oo |
oo _ '''' asText writeStream.
1 to: self size do: [:idx |
	oo << ''	smallPrimeTable at: '' << (idx-1) << '' store: '' 
		<< (self at: idx) << '!

(SCPrimeSizeProvider getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!SCPrimeSizeProvider methodsFor: 'creation'!

create: aSmallPrimeTable {UInt4Array}
	super create: aSmallPrimeTable! !

!SCPrimeSizeProvider methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SCPrimeSizeProvider class
	instanceVariableNames: ''!

(SCPrimeSizeProvider getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!SCPrimeSizeProvider class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	| smallPrimeTable {UInt4Array} |
	self REQUIRES: UInt32Array.
	self REQUIRES: PrimeSizeProvider.
	smallPrimeTable _ UInt32Array make: 207.
	smallPrimeTable at: UInt40 storeUInt: 7.
	smallPrimeTable at: 1 storeUInt: 13.
	smallPrimeTable at: 2 storeUInt: 19.
	smallPrimeTable at: 3 storeUInt: 31.
	smallPrimeTable at: 4 storeUInt: 61.
	smallPrimeTable at: 5 storeUInt: 103.
	smallPrimeTable at: 6 storeUInt: 151.
	smallPrimeTable at: 7 storeUInt: 199.
	smallPrimeTable at: 8 storeUInt: 283.
	smallPrimeTable at: 9 storeUInt: 433.
	smallPrimeTable at: 10 storeUInt: 619.
	smallPrimeTable at: 11 storeUInt: 829.
	smallPrimeTable at: 12 storeUInt: 1051.
	smallPrimeTable at: 13 storeUInt: 1291.
	smallPrimeTable at: 14 storeUInt: 1489.
	smallPrimeTable at: 15 storeUInt: 1873.
	smallPrimeTable at: 16 storeUInt: 2089.
	smallPrimeTable at: 17 storeUInt: 2383.
	smallPrimeTable at: 18 storeUInt: 2803.
	smallPrimeTable at: 19 storeUInt: 3361.
	smallPrimeTable at: 20 storeUInt: 3673.
	smallPrimeTable at: 21 storeUInt: 4093.
	smallPrimeTable at: 22 storeUInt: 4483.
	smallPrimeTable at: 23 storeUInt: 5011.
	smallPrimeTable at: 24 storeUInt: 5653.
	smallPrimeTable at: 25 storeUInt: 6361.
	smallPrimeTable at: 26 storeUInt: 6949.
	smallPrimeTable at: 27 storeUInt: 7759.
	smallPrimeTable at: 28 storeUInt: 8821.
	smallPrimeTable at: 29 storeUInt: 9463.
	smallPrimeTable at: 30 storeUInt: 10333.
	smallPrimeTable at: 31 storeUInt: 11353.
	smallPrimeTable at: 32 storeUInt: 12253.
	smallPrimeTable at: 33 storeUInt: 13759.
	smallPrimeTable at: 34 storeUInt: 14629.
	smallPrimeTable at: 35 storeUInt: 16141.
	smallPrimeTable at: 36 storeUInt: 17419.
	smallPrimeTable at: 37 storeUInt: 18133.
	smallPrimeTable at: 38 storeUInt: 19699.
	smallPrimeTable at: 39 storeUInt: 20809.
	smallPrimeTable at: 40 storeUInt: 22039.
	smallPrimeTable at: 41 storeUInt: 23203.
	smallPrimeTable at: 42 storeUInt: 25303.
	smallPrimeTable at: 43 storeUInt: 26893.
	smallPrimeTable at: 44 storeUInt: 28279.
	smallPrimeTable at: 45 storeUInt: 30139.
	smallPrimeTable at: 46 storeUInt: 31849.
	smallPrimeTable at: 47 storeUInt: 33151.
	smallPrimeTable at: 48 storeUInt: 34591.
	smallPrimeTable at: 49 storeUInt: 36781.
	smallPrimeTable at: 50 storeUInt: 38671.
	smallPrimeTable at: 51 storeUInt: 41203.
	smallPrimeTable at: 52 storeUInt: 43321.
	smallPrimeTable at: 53 storeUInt: 45319.
	smallPrimeTable at: 54 storeUInt: 47743.
	smallPrimeTable at: 55 storeUInt: 49531.
	smallPrimeTable at: 56 storeUInt: 51481.
	smallPrimeTable at: 57 storeUInt: 54403.
	smallPrimeTable at: 58 storeUInt: 56599.
	smallPrimeTable at: 59 storeUInt: 59023.
	smallPrimeTable at: 60 storeUInt: 62143.
	smallPrimeTable at: 61 storeUInt: 65173.
	smallPrimeTable at: 62 storeUInt: 68113.
	smallPrimeTable at: 63 storeUInt: 70489.
	smallPrimeTable at: 64 storeUInt: 72871.
	smallPrimeTable at: 65 storeUInt: 76261.
	smallPrimeTable at: 66 storeUInt: 79633.
	smallPrimeTable at: 67 storeUInt: 81931.
	smallPrimeTable at: 68 storeUInt: 84811.
	smallPrimeTable at: 69 storeUInt: 87559.
	smallPrimeTable at: 70 storeUInt: 90679.
	smallPrimeTable at: 71 storeUInt: 93763.
	smallPrimeTable at: 72 storeUInt: 97003.
	smallPrimeTable at: 73 storeUInt: 99709.
	smallPrimeTable at: 74 storeUInt: 103291.
	smallPrimeTable at: 75 storeUInt: 106753.
	smallPrimeTable at: 76 storeUInt: 110503.
	smallPrimeTable at: 77 storeUInt: 113719.
	smallPrimeTable at: 78 storeUInt: 117373.
	smallPrimeTable at: 79 storeUInt: 120919.
	smallPrimeTable at: 80 storeUInt: 124303.
	smallPrimeTable at: 81 storeUInt: 128659.
	smallPrimeTable at: 82 storeUInt: 132439.
	smallPrimeTable at: 83 storeUInt: 136069.
	smallPrimeTable at: 84 storeUInt: 140731.
	smallPrimeTable at: 85 storeUInt: 145513.
	smallPrimeTable at: 86 storeUInt: 149419.
	smallPrimeTable at: 87 storeUInt: 152533.
	smallPrimeTable at: 88 storeUInt: 156679.
	smallPrimeTable at: 89 storeUInt: 160753.
	smallPrimeTable at: 90 storeUInt: 165703.
	smallPrimeTable at: 91 storeUInt: 171253.
	smallPrimeTable at: 92 storeUInt: 176089.
	smallPrimeTable at: 93 storeUInt: 179899.
	smallPrimeTable at: 94 storeUInt: 183511.
	smallPrimeTable at: 95 storeUInt: 187909.
	smallPrimeTable at: 96 storeUInt: 192979.
	smallPrimeTable at: 97 storeUInt: 198463.
	smallPrimeTable at: 98 storeUInt: 203773.
	smallPrimeTable at: 99 storeUInt: 208459.
	smallPrimeTable at: 100 storeUInt: 214009.
	smallPrimeTable at: 101 storeUInt: 219799.
	smallPrimeTable at: 102 storeUInt: 225079.
	smallPrimeTable at: 103 storeUInt: 229849.
	smallPrimeTable at: 104 storeUInt: 234811.
	smallPrimeTable at: 105 storeUInt: 241363.
	smallPrimeTable at: 106 storeUInt: 246811.
	smallPrimeTable at: 107 storeUInt: 252913.
	smallPrimeTable at: 108 storeUInt: 259213.
	smallPrimeTable at: 109 storeUInt: 265273.
	smallPrimeTable at: 110 storeUInt: 270241.
	smallPrimeTable at: 111 storeUInt: 276049.
	smallPrimeTable at: 112 storeUInt: 282241.
	smallPrimeTable at: 113 storeUInt: 287671.
	smallPrimeTable at: 114 storeUInt: 294949.
	smallPrimeTable at: 115 storeUInt: 300823.
	smallPrimeTable at: 116 storeUInt: 307033.
	smallPrimeTable at: 117 storeUInt: 312679.
	smallPrimeTable at: 118 storeUInt: 318349.
	smallPrimeTable at: 119 storeUInt: 323509.
	smallPrimeTable at: 120 storeUInt: 328513.
	smallPrimeTable at: 121 storeUInt: 334513.
	smallPrimeTable at: 122 storeUInt: 341953.
	smallPrimeTable at: 123 storeUInt: 347959.
	smallPrimeTable at: 124 storeUInt: 354373.
	smallPrimeTable at: 125 storeUInt: 360511.
	smallPrimeTable at: 126 storeUInt: 366853.
	smallPrimeTable at: 127 storeUInt: 374683.
	smallPrimeTable at: 128 storeUInt: 381301.
	smallPrimeTable at: 129 storeUInt: 388183.
	smallPrimeTable at: 130 storeUInt: 394633.
	smallPrimeTable at: 131 storeUInt: 400723.
	smallPrimeTable at: 132 storeUInt: 406501.
	smallPrimeTable at: 133 storeUInt: 413869.
	smallPrimeTable at: 134 storeUInt: 420319.
	smallPrimeTable at: 135 storeUInt: 426409.
	smallPrimeTable at: 136 storeUInt: 431911.
	smallPrimeTable at: 137 storeUInt: 440581.
	smallPrimeTable at: 138 storeUInt: 447571.
	smallPrimeTable at: 139 storeUInt: 454891.
	smallPrimeTable at: 140 storeUInt: 463033.
	smallPrimeTable at: 141 storeUInt: 470599.
	smallPrimeTable at: 142 storeUInt: 477361.
	smallPrimeTable at: 143 storeUInt: 486043.
	smallPrimeTable at: 144 storeUInt: 492631.
	smallPrimeTable at: 145 storeUInt: 499183.
	smallPrimeTable at: 146 storeUInt: 506593.
	smallPrimeTable at: 147 storeUInt: 514651.
	smallPrimeTable at: 148 storeUInt: 521659.
	smallPrimeTable at: 149 storeUInt: 528403.
	smallPrimeTable at: 150 storeUInt: 536149.
	smallPrimeTable at: 151 storeUInt: 542119.
	smallPrimeTable at: 152 storeUInt: 550339.
	smallPrimeTable at: 153 storeUInt: 557983.
	smallPrimeTable at: 154 storeUInt: 565393.
	smallPrimeTable at: 155 storeUInt: 572683.
	smallPrimeTable at: 156 storeUInt: 579643.
	smallPrimeTable at: 157 storeUInt: 586921.
	smallPrimeTable at: 158 storeUInt: 594961.
	smallPrimeTable at: 159 storeUInt: 602269.
	smallPrimeTable at: 160 storeUInt: 610543.
	smallPrimeTable at: 161 storeUInt: 618031.
	smallPrimeTable at: 162 storeUInt: 625969.
	smallPrimeTable at: 163 storeUInt: 632941.
	smallPrimeTable at: 164 storeUInt: 640669.
	smallPrimeTable at: 165 storeUInt: 648103.
	smallPrimeTable at: 166 storeUInt: 655219.
	smallPrimeTable at: 167 storeUInt: 663583.
	smallPrimeTable at: 168 storeUInt: 671521.
	smallPrimeTable at: 169 storeUInt: 679519.
	smallPrimeTable at: 170 storeUInt: 687133.
	smallPrimeTable at: 171 storeUInt: 696769.
	smallPrimeTable at: 172 storeUInt: 704779.
	smallPrimeTable at: 173 storeUInt: 712891.
	smallPrimeTable at: 174 storeUInt: 721663.
	smallPrimeTable at: 175 storeUInt: 729571.
	smallPrimeTable at: 176 storeUInt: 739303.
	smallPrimeTable at: 177 storeUInt: 747499.
	smallPrimeTable at: 178 storeUInt: 755719.
	smallPrimeTable at: 179 storeUInt: 764839.
	smallPrimeTable at: 180 storeUInt: 773209.
	smallPrimeTable at: 181 storeUInt: 781801.
	smallPrimeTable at: 182 storeUInt: 790291.
	smallPrimeTable at: 183 storeUInt: 797581.
	smallPrimeTable at: 184 storeUInt: 807943.
	smallPrimeTable at: 185 storeUInt: 817153.
	smallPrimeTable at: 186 storeUInt: 824779.
	smallPrimeTable at: 187 storeUInt: 833479.
	smallPrimeTable at: 188 storeUInt: 842353.
	smallPrimeTable at: 189 storeUInt: 852199.
	smallPrimeTable at: 190 storeUInt: 860941.
	smallPrimeTable at: 191 storeUInt: 869599.
	smallPrimeTable at: 192 storeUInt: 877939.
	smallPrimeTable at: 193 storeUInt: 885883.
	smallPrimeTable at: 194 storeUInt: 894613.
	smallPrimeTable at: 195 storeUInt: 904681.
	smallPrimeTable at: 196 storeUInt: 912943.
	smallPrimeTable at: 197 storeUInt: 921841.
	smallPrimeTable at: 198 storeUInt: 930619.
	smallPrimeTable at: 199 storeUInt: 941011.
	smallPrimeTable at: 200 storeUInt: 949453.
	smallPrimeTable at: 201 storeUInt: 958879.
	smallPrimeTable at: 202 storeUInt: 967849.
	smallPrimeTable at: 203 storeUInt: 976309.
	smallPrimeTable at: 204 storeUInt: 986599.
	smallPrimeTable at: 205 storeUInt: 996409.
	smallPrimeTable at: 206 storeUInt: 1005679.
	SCMySoleProvider _ SCPrimeSizeProvider create: smallPrimeTable.!

linkTimeNonInherited
	SCMySoleProvider _ NULL.! !

!SCPrimeSizeProvider class methodsFor: 'make'!

make
	^ SCMySoleProvider! !