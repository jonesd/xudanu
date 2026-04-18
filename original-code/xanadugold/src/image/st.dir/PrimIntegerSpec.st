'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:10 pm'!

PrimSpec subclass: #PrimIntegerSpec
	instanceVariableNames: '
		myBitCount {Int32}
		amSigned {BooleanVar}
		myMin {Int32}
		myMax {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(PrimIntegerSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY xpp ); yourself)!

!PrimIntegerSpec methodsFor: 'accessing'!

{Int32 INLINE} bitCount
	"How many bits, or zero if it is unlimited"
	
	^myBitCount!

{PrimIntegerSpec} combine: other {PrimIntegerSpec}
	"A spec whose range of values contains both ranges"
	
	self == other ifTrue: [^self].
	myBitCount == Int32Zero ifTrue: [^self].
	other bitCount == Int32Zero ifTrue: [^other].
	myBitCount < other bitCount ifTrue: [^other].
	myBitCount > other bitCount ifTrue: [^self].
	amSigned == other isSigned ifTrue: [^self].
	"here we get ad hoc since we need to expand to the next larger size"
	myBitCount == 8 ifTrue: [^PrimSpec int32].
	^PrimSpec integerVar!

{BooleanVar INLINE} isSigned
	"Whether it allows negative values"
	
	^amSigned! !

!PrimIntegerSpec methodsFor: 'create'!

create: primClass {Category} with: bitCount {Int32} with: isSigned {BooleanVar}

	super create: primClass.
	myBitCount := bitCount.
	amSigned := isSigned.
	myBitCount ~~ -1 ifTrue:
		[amSigned ifTrue:
			[[myMin := (2 raisedTo: myBitCount - 1) negated.
			myMax := myMin negated - 1] smalltalkOnly.
			'myMin = 1 << (myBitCount - 1);
			myMax = ~myMin;' translateOnly]
		ifFalse:
			[[myMin := Int32Zero.
			myMax := (2 raisedTo: myBitCount) - 1] smalltalkOnly.
			'myMin = Int32Zero;
			/* the shift is done in two steps to avoid five-bit truncation on SPARCs */
			myMax = ~(((~Int32Zero) << (myBitCount - 1)) << 1);' translateOnly]]! !

!PrimIntegerSpec methodsFor: 'testing'!

{UInt32} actualHashForEqual
	| signPart {UInt32} |
	amSigned ifTrue: [signPart _ 255] ifFalse: [signPart _ UInt32Zero].
	^(self getCategory hashForEqual
		bitXor: (FHash fastHash.UInt32: myBitCount))
		bitXor: signPart!

{BooleanVar} canHold: value {IntegerVar}
	"Whether this spec can hold the given value"
	
	[^myBitCount = -1 or: [value >= myMin and: [value <= myMax]]] smalltalkOnly.
	'if (myBitCount = -1) {
		return TRUE;
	} else if (amSigned) {
		return value >= myMin && value <= myMax;
	} else {
		return (unsigned) value.asLong () >= (unsigned) myMin
			&& (unsigned) value.asLong () <= (unsigned) myMax;
	}' translateOnly!

{BooleanVar} isEqual: other {Heaper}

	other cast: PrimIntegerSpec into: [ :spec |
		^myBitCount = spec bitCount
			and: [amSigned == spec isSigned]]
	others:
		[^false].
	^ false "compiler fodder"! !

!PrimIntegerSpec methodsFor: 'making'!

{PrimArray} array: count {Int32 default: Int32Zero}
	"Make an array initialized to zero values"
	
	[self == (PrimSpec uInt32 basicCast: Heaper star) ifTrue: [^UInt32Array make: count].
	self == (PrimSpec uInt8 basicCast: Heaper star) ifTrue: [^UInt8Array make: count].
	self == (PrimSpec int32 basicCast: Heaper star) ifTrue: [^Int32Array make: count].
	self == (PrimSpec integerVar basicCast: Heaper star) ifTrue: [^IntegerVarArray zeros: count].
	Heaper BLAST: #BadPrimSpec] translateOnly.
	[^myClass create: count] smalltalkOnly.
	^ NULL "compiler fodder"!

{PrimArray} arrayFromBuffer: count {Int32} with: buffer {void star}
	"Make an array with the values at the given address"
	
	[self == (PrimSpec uInt32 basicCast: Heaper star) ifTrue: [^UInt32Array make: count with: buffer].
	self == (PrimSpec uInt8 basicCast: Heaper star) ifTrue: [^UInt8Array make: count with: buffer].
	self == (PrimSpec int32 basicCast: Heaper star) ifTrue: [^Int32Array make: count with: buffer].
	self == (PrimSpec integerVar basicCast: Heaper star) ifTrue: [^IntegerVarArray make: count with: buffer].
	Heaper BLAST: #BadPrimSpec] translateOnly.
	[^myClass create: count with: buffer] smalltalkOnly.
	^ NULL "compiler fodder"!

{PrimIntegerArray} string: string {char star}
	"Make an array the contents of the string"
	
	self == (PrimSpec uInt8 basicCast: Heaper star) ifTrue: [^UInt8Array string: string].
	self unimplemented.
	^NULL "fodder"!

{PrimIntValue INLINE} value: number {IntegerVar}
	"A boxed integer value"
	
	^PrimIntValue make: number! !

!PrimIntegerSpec methodsFor: 'private: making'!

{PrimArray} privateCopy: array {PrimArray}
	with: size {Int32 default: -1}
	with: start {Int32 default: Int32Zero}
	with: count {Int32 default: -1}
	with: offset {Int32 default: Int32Zero}
	"Make a copy of an array with a different representation size. The arguments are the same as in PrimArray::copy."
	
	[self == (PrimSpec uInt32 basicCast: Heaper star) ifTrue: [^UInt32Array make: size with: array with: start with: count with: offset].
	self == (PrimSpec uInt8 basicCast: Heaper star) ifTrue: [^UInt8Array make: size with: array with: start with: count with: offset].
	self == (PrimSpec int32 basicCast: Heaper star) ifTrue: [^Int32Array make: size with: array with: start with: count with: offset].
	self == (PrimSpec integerVar basicCast: Heaper star) ifTrue: [^IntegerVarArray make: size with: array with: start with: count with: offset].
	Heaper BLAST: #BadPrimSpec] translateOnly.
	[^myClass create: size with: array with: start with: count with: offset] smalltalkOnly.
	^ NULL "compiler fodder"! !

!PrimIntegerSpec methodsFor: 'smalltalk: passe'!

{Int32} precision

	self passe "bitCount"! !

!PrimIntegerSpec methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myBitCount _ receiver receiveInt32.
	amSigned _ receiver receiveBooleanVar.
	myMin _ receiver receiveInt32.
	myMax _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: myBitCount.
	xmtr sendBooleanVar: amSigned.
	xmtr sendInt32: myMin.
	xmtr sendInt32: myMax.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimIntegerSpec class
	instanceVariableNames: ''!

(PrimIntegerSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY xpp ); yourself)!

!PrimIntegerSpec class methodsFor: 'smalltalk: system'!

info.stProtocol
"{BooleanVar CLIENT} isSigned
{Int32 CLIENT} precision
{PrimIntegerArray CLIENT} string: string {char star}
{PrimInteger CLIENT} value: number {IntegerVar}
"! !