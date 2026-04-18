'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:08 pm'!

PrimDataArray subclass: #PrimFloatArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(PrimFloatArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!PrimFloatArray methodsFor: 'accessing'!

{void} at: index {Int32} storeFloat: value {IEEE64}
	"Store a floating point value"
	
	self basicAt: 1 + index put: value!

{Int32 CLIENT} bitCount
	"Return the maximum precision that can be stored in this array."
	
	self subclassResponsibility!

{IEEE64} floatAt: index {Int32}
	"Get an actual floating point number"
	
	^self basicAt: 1 + index! !

!PrimFloatArray methodsFor: 'testing'!

{UInt32} elementsHash: count {Int32 default: -1} with: start {Int32 default: Int32Zero}
	
	^self getCategory hashForEqual bitXor: (FHash fastHash.UInt32: count)! !

!PrimFloatArray methodsFor: 'bulk accessing'!

{Int32} indexOf: value {Heaper}
	with: start {Int32 default: Int32Zero}
	with: n {Int32 default: 1}

	^self indexOfObject: (value cast: PrimFloatValue) asIEEE64 with: start with: n!

{Int32} indexPast: value {Heaper}
	with: start {Int32 default: Int32Zero}
	with: n {Int32 default: 1}

	^self indexPastObject: (value cast: PrimFloatValue) asIEEE64 with: start with: n! !

!PrimFloatArray methodsFor: 'smalltalk: passe'!

{Int32} precision

	self passe "bitCount"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimFloatArray class
	instanceVariableNames: ''!

(PrimFloatArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!PrimFloatArray class methodsFor: 'creation'!

{PrimFloatArray CLIENT} zeros: precision {Int32} with: count {Int32}
	"Make an array initialized to zero values"

	precision == 64 ifTrue: [^IEEE64Array make: count].
	precision == 32 ifTrue: [^IEEE32Array make: count].
	Heaper BLAST: #UnimplementedPrecision.
	"compiler fodder"
	^NULL! !