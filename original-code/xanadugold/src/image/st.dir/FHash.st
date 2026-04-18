'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:31 pm'!

Heaper subclass: #FHash
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fhash'!


"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FHash class
	instanceVariableNames: ''!



!FHash class methodsFor: 'hooks: global: xpp hooks'!

{UInt32} fastHash.String: aString {char star}
	"Adapted from
		Fast Hashing of Variable-Length Text Strings
		Peter K. Pearson
		Communications of the ACM
		June 1990
		Volume 33, Number 6, pp 677-680
		
		The original generates an 8-bit value using the iterand
				result = hashSBox [ string[i] xor result ]
	"
	| result {UInt32} strSize {Int32} |
	
	result _ UInt32Zero.
	strSize _ aString count.
	Int32Zero almostTo: strSize do: [ :i {Int32} |
		result _ ((StringHashSBoxes at: (i bitAnd: 7)) at: ((aString at: i + 1) asInteger bitXor: (result bitAnd: 255))) bitXor: result].
		^ result
	
	"The following piece of code should produce a collection with values identical to the X++ test"
	" | coll str |
	coll _ OrderedCollection new.
	coll add: (Association key: 'foo' value: (FHash fastHash.String: 'foo')).
	coll add: (Association key: 'oof' value: (FHash fastHash.String: 'oof')).
	coll add: (Association key: 'bar' value: (FHash fastHash.String: 'bar')).
	coll add: (Association key: 'car' value: (FHash fastHash.String: 'car')).
	coll add: (Association key: 'cars' value: (FHash fastHash.String: 'cars')).
	str _ 'this is a long string to hash'.
	coll add: (Association key: str value: (FHash fastHash.String: str)).
	str _ 'this is a longer string to hash'.
	coll add: (Association key: str value: (FHash fastHash.String: str)).
	str _ 'this is a test..'.
	coll add: (Association key: str value: (FHash fastHash.String: str)).
	str _ ' is thisa test..'.
	coll add: (Association key: str value: (FHash fastHash.String: str)).
	str _ 'a test..this is '.
	coll add: (Association key: str value: (FHash fastHash.String: str)).
	coll
	"!

{UInt32} fastHash.UInt32: anInt {UInt32}
	"325221869 = 94349 * 88801 mod 29 bits"
	^ (anInt * 325221869)  bitAnd: (Integer MAXINT)

"The values produced by the code fragment below should be the same as the integer part of xpp/fhashr.txt"
"
| i coll |
coll _ OrderedCollection new.
i _ 0.
[i < 20000] whileTrue: [
	coll add: (Association key: i value: (Heaper fastHash.UInt32: i)).
	i _ i + 431].
coll
"!

{UInt32} fastHash.UInt8Array.Int: aByteArray {UInt8 star} with: aCount {int}
	"Adapted from
		Fast Hashing of Variable-Length Text Strings
		Peter K. Pearson
		Communications of the ACM
		June 1990
		Volume 33, Number 6, pp 677-680
		
		The original generates an 8-bit value using the iterand
				result = hashSBox [ string[i] xor result ]
	"
	"Cloned from fastHashString: by michael 9 July 1991.
	 Hacked to use a count and hash a vector that may contain zeroes."
	 	
	| result {UInt32} |
	self passe.
	
	result _ UInt32Zero.
	Int32Zero almostTo: aCount do: [ :i {Int32} |
		result _ ((StringHashSBoxes at: (i bitAnd: 7)) at: ((aByteArray at: i + 1) asInteger bitXor: (result bitAnd: 255))) bitXor: result].
	^ result! !

!FHash class methodsFor: 'smalltalk: passe'!

{UInt32} fastHash.UInt1Array.Int: aByteArray {UInt1 star} with: aCount {int}
	"Adapted from
		Fast Hashing of Variable-Length Text Strings
		Peter K. Pearson
		Communications of the ACM
		June 1990
		Volume 33, Number 6, pp 677-680
		
		The original generates an 8-bit value using the iterand
				result = hashSBox [ string[i] xor result ]
	"
	"Cloned from fastHashString: by michael 9 July 1991.
	 Hacked to use a count and hash a vector that may contain zeroes."
	 	
	| result {UInt32} |
	self passe.
	
	result _ UInt32Zero.
	Int32Zero almostTo: aCount do: [ :i {Int32} |
		result _ ((StringHashSBoxes at: (i bitAnd: 7)) at: ((aByteArray at: i + 1) asInteger bitXor: (result bitAnd: 255))) bitXor: result].
	^ result!

{UInt4} fastHash.UInt4: anInt {UInt4}
	"325221869 = 94349 * 88801 mod 29 bits"
	self passe.
	^ (anInt * 325221869)  bitAnd: (Integer MAXINT)

"The values produced by the code fragment below should be the same as the integer part of xpp/fhashr.txt"
"
| i coll |
coll _ OrderedCollection new.
i _ 0.
[i < 20000] whileTrue: [
	coll add: (Association key: i value: (Heaper fastHash.UInt4: i)).
	i _ i + 431].
coll
"! !