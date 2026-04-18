'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:12 pm'!

Heaper subclass: #PrimSpec
	instanceVariableNames: 'myClass {Category}'
	classVariableNames: '
		TheIEEE32Spec {PrimFloatSpec} 
		TheIEEE64Spec {PrimFloatSpec} 
		TheInt32Spec {PrimIntegerSpec} 
		TheIntegerVarSpec {PrimIntegerSpec} 
		ThePtrSpec {PrimPointerSpec} 
		TheSharedPtrSpec {PrimPointerSpec} 
		TheUInt32Spec {PrimIntegerSpec} 
		TheUInt8Spec {PrimIntegerSpec} '
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
PrimSpec comment:
'A specification of a kind of primitive data type which can be stored in PrimArrays. It gives you protocol for creating and copying PrimArrays. The class and characteristics of this object determine what kind of things are stored there, and how much precision they have.'!

(PrimSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY xpp ); add: #DEFERRED; yourself)!

!PrimSpec methodsFor: 'private: making'!

{PrimArray} privateCopy: array {PrimArray}
	with: size {Int32 default: -1}
	with: start {Int32 default: Int32Zero}
	with: count {Int32 default: -1}
	with: offset {Int32 default: Int32Zero}
	"Support for copy:with:with:with:with:"
	
	self subclassResponsibility.! !

!PrimSpec methodsFor: 'smalltalk: defaults'!

{PrimArray} array

	^self array: 0!

{PrimArray} copy: array {PrimArray}
	^self copy: array with: -1 with: 0 with: 0 with: 0!

{PrimArray} copy: array {PrimArray}
	with: count {Int32 default: -1}
	^self copy: array with: count with: 0 with: 0 with: 0!

{PrimArray} copy: array {PrimArray}
	with: count {Int32 default: -1}
	with: start {Int32 default: Int32Zero}
	^self copy: array with: count with: start with: 0 with: 0!

{PrimArray} copy: array {PrimArray}
	with: count {Int32 default: -1}
	with: start {Int32 default: Int32Zero}
	with: before {Int32 default: Int32Zero}
	^self copy: array with: count with: start with: before with: 0! !

!PrimSpec methodsFor: 'protected:'!

{Category INLINE} arrayClass
	^myClass! !

!PrimSpec methodsFor: 'protected: create'!

create: primClass {Category}
	super create.
	myClass _ primClass.! !

!PrimSpec methodsFor: 'making'!

{PrimArray} array: count {Int32 default: Int32Zero}
	"Make an array initialized to some reasonable zero value"
	
	self subclassResponsibility!

{PrimArray} arrayFromBuffer: count {Int32} with: buffer {void star}
	"Make an array with the values at the given address"

	self subclassResponsibility!

{PrimArray} arrayWith: value {Heaper}
	"Make a single element array containing the given value"
	
	| result {PrimArray} |
	result _ self array: 1.
	result at: Int32Zero storeValue: value.
	^result!

{PrimArray} arrayWithThree: value {Heaper} with: other {Heaper} with: another {Heaper}
	"Make a two element array containing the given values"
	
	| result {PrimArray} |
	result _ self array: 3.
	result at: Int32Zero storeValue: value.
	result at: 1 storeValue: other.
	result at: 2 storeValue: another.
	^ result!

{PrimArray} arrayWithTwo: value {Heaper} with: other {Heaper}
	"Make a two element array containing the given values"
	
	| result {PrimArray} |
	result _ self array: 2.
	result at: Int32Zero storeValue: value.
	result at: 1 storeValue: other.
	^ result.!

{PrimArray} copy: array {PrimArray}
	with: count {Int32 default: -1}
	with: start {Int32 default: Int32Zero}
	with: before {Int32 default: Int32Zero}
	with: after {Int32 default: Int32Zero}
	"Make a copy of an array with a different representation size. The arguments are the same as in PrimArray::copy."
	
	| copyCount {Int32} |
	count < Int32Zero
		ifTrue: [copyCount _ array count - start]
		ifFalse:
			[copyCount _ count.
			start + copyCount > array count
				ifTrue: [Heaper BLAST: #IndexOutOfBounds]].
	^self privateCopy: array with: copyCount + before + after with: start with: copyCount with: before!

{PrimArray} copyGrow: array {PrimArray} with: after {Int32}
	"Make a copy of the array into a larger array.  The array has 'after' slots after the copied elements."
	
	^self copy: array with: -1 with: Int32Zero with: Int32Zero with: after! !

!PrimSpec methodsFor: 'accessing'!

{Int32 CLIENT} sizeofElement
	"Essential. The size of a single element of the array, to be used to allocated space for copyTo/FromBuffer. In the same units as C sizeof ()."
	
	self unimplemented.
	^Int32Zero "fodder"! !

!PrimSpec methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myClass _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myClass.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimSpec class
	instanceVariableNames: ''!

(PrimSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY xpp ); add: #DEFERRED; yourself)!

!PrimSpec class methodsFor: 'private: init'!

{void} initSpecs
	"moved from initTime because MS C++/NT does not like large initTimes"

	TheUInt8Spec := PrimIntegerSpec create: UInt8Array with: 8 with: false.
	TheUInt32Spec := PrimIntegerSpec create: UInt32Array with: 32 with: false.
	TheInt32Spec := PrimIntegerSpec create: Int32Array with: 32 with: true.
	TheIntegerVarSpec := PrimIntegerSpec create: IntegerVarArray with: -1 with: true.
	TheIEEE32Spec := PrimFloatSpec create: IEEE32Array with: 32.
	TheIEEE64Spec := PrimFloatSpec create: IEEE64Array with: 64.
	ThePtrSpec := PrimPointerSpec create: PtrArray.
	TheSharedPtrSpec := PrimPointerSpec create: SharedPtrArray.! !

!PrimSpec class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self initSpecs!

linkTimeNonInherited

	TheUInt8Spec := NULL.
	TheUInt32Spec := NULL.
	TheInt32Spec := NULL.
	TheIntegerVarSpec := NULL.
	TheIEEE32Spec := NULL.
	TheIEEE64Spec := NULL.
	ThePtrSpec := NULL.
	TheSharedPtrSpec := NULL.! !

!PrimSpec class methodsFor: 'pseudo constructors'!

{PrimFloatSpec INLINE} iEEE32

	^TheIEEE32Spec!

{PrimFloatSpec INLINE} iEEE64

	^TheIEEE64Spec!

{PrimFloatSpec} iEEE: precision {Int32}
	
	precision = 32 ifTrue: [^TheIEEE32Spec].
	precision = 64 ifTrue: [^TheIEEE64Spec].
	self unimplemented.
	^NULL!

{PrimIntegerSpec INLINE} int32

	^TheInt32Spec!

{PrimIntegerSpec INLINE} integerVar

	^TheIntegerVarSpec!

{PrimPointerSpec INLINE} pointer
	"A spec for pointers to object"

	^ThePtrSpec!

{PrimPointerSpec INLINE} sharedPointer

	^TheSharedPtrSpec!

{PrimIntegerSpec} signedInteger: bitCount {Int32}

	bitCount = 32 ifTrue: [^TheInt32Spec].
	self unimplemented.
	^NULL!

{PrimIntegerSpec} toHold: value {IntegerVar}
	"The least demanding spec that will hold the given value"
	
	value < IntegerVar0
		ifTrue: [value < Int32Min
			ifTrue: [^self integerVar]
			ifFalse: [^self int32]]
		ifFalse: [value <= Int32Max
			ifTrue: [value <= UInt8Max
				ifTrue: [^self uInt8]
				ifFalse: [^self int32]]
			ifFalse: [value <= UInt32Max
				ifTrue: [^self uInt32]
				ifFalse: [^self integerVar]]]!

{PrimIntegerSpec INLINE} uInt32

	^TheUInt32Spec!

{PrimIntegerSpec INLINE} uInt8

	^TheUInt8Spec!

{PrimIntegerSpec} unsignedInteger: bitCount {Int32}

	bitCount = 32 ifTrue: [^TheUInt32Spec].
	bitCount = 8 ifTrue: [^TheUInt8Spec].
	self unimplemented.
	^NULL! !

!PrimSpec class methodsFor: 'smalltalk: system'!

info.stProtocol
"{PrimArray CLIENT} arrayFromBuffer: count {Int32} with: buffer {void star}
{PrimArray CLIENT} arrayWith: value {Heaper}
{PrimArray CLIENT} arrayWithThree: value {Heaper} with: other {Heaper} with: another {Heaper}
{PrimArray CLIENT} arrayWithTwo: value {Heaper} with: other {Heaper}
{Int32 CLIENT} sizeofElement
"! !