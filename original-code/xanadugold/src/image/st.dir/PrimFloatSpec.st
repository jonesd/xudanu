'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:08 pm'!

PrimSpec subclass: #PrimFloatSpec
	instanceVariableNames: 'myBitCount {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
PrimFloatSpec comment:
'Specifies different precisions and representations of floating point numbers.'!

(PrimFloatSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY xpp ); yourself)!

!PrimFloatSpec methodsFor: 'accessing'!

{Int32 INLINE} bitCount
	"How many total bits per value"
	
	^myBitCount! !

!PrimFloatSpec methodsFor: 'create'!

create: primClass {Category} with: bitCount {Int32}

	super create: primClass.
	myBitCount := bitCount.! !

!PrimFloatSpec methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual
		bitXor: (FHash fastHash.UInt32: myBitCount)!

{BooleanVar} isEqual: other {Heaper}

	other cast: PrimFloatSpec into: [ :spec |
		^myBitCount = spec bitCount]
	others:
		[^false].
	^ false "compiler fodder"! !

!PrimFloatSpec methodsFor: 'private: making'!

{PrimArray} privateCopy: array {PrimArray}
	with: size {Int32 default: -1}
	with: start {Int32 default: Int32Zero}
	with: count {Int32 default: -1}
	with: offset {Int32 default: Int32Zero}
	"Make a copy of an array with a different representation size. The arguments are the same as in PrimArray::copy."
	
	[Eric thingToDo. "Add case for generic floating point--essentially PtrArray of PrimFloat"
	self == (PrimSpec iEEE64 basicCast: Heaper star) ifTrue: [^IEEE64Array make: size with: array with: start with: count with: offset].
	self == (PrimSpec iEEE32 basicCast: Heaper star) ifTrue: [^IEEE32Array make: size with: array with: start with: count with: offset].
	Heaper BLAST: #BadPrimSpec] translateOnly.
	[^myClass create: size with: start with: count with: offset] smalltalkOnly.
	^ NULL "compiler fodder"! !

!PrimFloatSpec methodsFor: 'making'!

{PrimArray} array: count {Int32 default: Int32Zero}
	"Make an array initialized to zero values"

	[Eric thingToDo. "Add case for generic floating point--essentially PtrArray of PrimFloat"
	self == (PrimSpec iEEE64 basicCast: Heaper star) ifTrue: [^IEEE64Array make: count].
	self == (PrimSpec iEEE32 basicCast: Heaper star) ifTrue: [^IEEE32Array make: count].
	Heaper BLAST: #BadPrimSpec] translateOnly.
	[^myClass create: count] smalltalkOnly.
	^ NULL "compiler fodder"!

{PrimArray} arrayFromBuffer: count {Int32} with: buffer {void star}
	"Make an array with the values at the given address"
	
	["Generic case of unspecified size can't be handled here."
	self == (PrimSpec iEEE64 basicCast: Heaper star) ifTrue: [^IEEE64Array make: count with: buffer].
	self == (PrimSpec iEEE32 basicCast: Heaper star) ifTrue: [^IEEE32Array make: count with: buffer].
	Heaper BLAST: #BadPrimSpec] translateOnly.
	[^myClass create: count with: buffer] smalltalkOnly.
	^ NULL "compiler fodder"!

{PrimFloatValue} preciseValue: number {IEEE128}
	"A boxed floating point value from a large precision number"
	
	"myBitCount = 32 ifTrue: [^PrimIEEE32 make: self with: number].
	myBitCount = 64 ifTrue: [^PrimIEEE64 make: self with: number]"
	self unimplemented.
	^NULL "fodder"!

{PrimFloatValue} value: number {IEEE64}
	"A boxed floating point value"
	
	myBitCount = 32 ifTrue: [^PrimIEEE32 make: number].
	myBitCount = 64 ifTrue: [^PrimIEEE64 make: number].
	^NULL "fodder"! !

!PrimFloatSpec methodsFor: 'smalltalk: passe'!

{Int32} precision

	self passe "bitCount"! !

!PrimFloatSpec methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myBitCount _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: myBitCount.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimFloatSpec class
	instanceVariableNames: ''!

(PrimFloatSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY xpp ); yourself)!

!PrimFloatSpec class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PrimFloat CLIENT} preciseValue: number {IEEE128}
{Int32 CLIENT} precision
{PrimFloat CLIENT} value: number {IEEE64}
"! !