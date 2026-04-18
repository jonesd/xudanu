'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:14 pm'!

Object subclass: #TypedPtr
	instanceVariableNames: 'myUnderlyingArray myOffset mySize myCount '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
TypedPtr comment:
'TypedPtr is the common superclass for a set of classes used to simulate C and C++ pointers-to-objects-of-known-size.
They are built on UInt1Arrays, which are SUPPOSED to be heapers pointed at by strong pointers.
This is JUST FOR CONVENIENCE at the smalltalk level.  These classes should compile to NORMAL C POINTERS.
(See also: FuncPtr)

The Current types:
	CharPtr		(char *)		(character - note that Smalltalk distinguishes chars from ints)
	UInt1Ptr	(UInt1 *)		(1-byte unsigned integer)
	UInt2Ptr	(UInt2 *)		(2-byte unsigned integer)
	UInt4Ptr	(UInt4 *)		(4-byte unsigned integer)

The following operations are defined:

	Smalltalk							C / C++ equivalent.  (Actually, should be another *)
	---------							-----------------------------------------------------
	aTypedPtr at						*aTypedPtr						aTypedPtr[0]
	aTypedPtr at: anInt				*aTypedPtr + anInt			aTypedPtr[anInt]
	aTypedPtr put: aValue				*aTypedPtr = aValue			aTypedPtr[0] = aValue
	aTypedPtr at: anInt put: aValue	*aTypedPtr + anInt = aValue	aTypedPtr[anInt] = aValue
	aTypedPtr preInc					++aTypedPtr
	aTypedPtr preInc: anInt			aTypedPtr =+ anInt
	aTypedPtr preDec					--aTypedPtr
	aTypedPtr preDec: anInt			aTypedPtr =- anInt
	aTypedPtr postInc					aTypedPtr++
	aTypedPtr postInc: anInt			aTypedPtr += anInt
	aTypedPtr postDec					aTypedPtr--
	aTypedPtr postDec: anInt			aTypedPtr -= anInt
	bTypedPtr _ aTypedPtr clone		bTypedPtr = aTypedPtr  (Remember that smalltalk vars are themselves pointers)
	
	Smalltalk-only methods
	--------------------
	TypedPtr withUInt1Array: x from: anInt count: anInt		(~declaration of a member of a struct)
	TypedPtr withUInt1Array: x								(~declaration of a member of a union)
	TypedPtr withUInt1Array: x from: anInt count: anInt		(~declaration of a member of a struct)
	TypedPtr withUInt1Array: x								(~declaration of a member of a union or {make a copy} cast to another type)
	TypedPtr newZeroed: anInt			myType ptr[anInt];		(~declaration of a dynamic array of the type.)
	TypedPtr newZeroed				myType ptr;			(~declaration of a dynamic simple variable of the type.)
																( newZeroed{: anInt} also corresponds to "ptr = calloc(sizeof(myType) {* anInt});" )
																( newZeroed{: anInt} also corresponds to "ptr = new myType{[anInt}}; (and zero it)" )
	
	aTypedPtr unerlyingArray			(The address of the vector it''s built on...)
	aTypedPtr rawSize					(sizeof(the vector of things it points to))
	aTypedPtr count					(number of elements here-to-right-end)
	aTypedPtr offset					(sizeof(what''s left of where we point in basic array))
	aTypedPtr indexShift				(base-2 log of sizeof(*aTypedPtr))

TypedPtrs send self error if you try to make a reference outside the defined region.

These tests should NOT be converted to blasts, because the corresponding C/C++ operations do NOT do the tests.

(The underflow test currently only tests for the pointer going off the bottom of the underlying array, not the bottom of the subset.)'!


!TypedPtr methodsFor: 'Smalltalk instance creation'!

clone

	^self class withByteArray: myUnderlyingArray from: myOffset count: myCount! !

!TypedPtr methodsFor: 'Smalltalk initialization'!

withByteArray: aByteArray {ByteArray} from: aStart {UInt2} count: aCount {UInt2}
	"Initialize virtual superclass of TypedFixedSubArray classes"
	
	| tempSize |
	
	myUnderlyingArray _ aByteArray.
	myOffset _ aStart.
	myCount _ aCount.
	tempSize _ (1 bitShift: self class indexShift).
	mySize _ tempSize* aCount.
	(tempSize - 1 bitAnd: myOffset) isZero
		ifFalse: [self error: 'Allignment error'].
	(mySize + myOffset) > (myUnderlyingArray sizeInBytes)
		ifTrue:  [self error: 'Overruns underlying array'].
	
	^self! !

!TypedPtr methodsFor: 'twiddling'!

postDec
	"ptr--"
	
	| tCopy |
	
	tCopy _ self clone.
	self preDec.
	^tCopy!

postInc
	"ptr++"
	
	| tCopy |
	
	tCopy _ self clone.
	self preInc.
	^tCopy!

preDec
	"--ptr"
	
	^self preDec: 1!

preDec: aBump {UInt2}
	"ptr -= aBump"
	
	| tempSize |
	
	tempSize _ (aBump bitShift: self class indexShift).
		
	myOffset _ myOffset - tempSize.
	mySize    _ mySize    + tempSize.
	myCount  _ myCount + aBump.
	
	^self!

preInc
	"++ptr"
		
	^self preInc: 1!

preInc: aBump {UInt2}
	"ptr += aBump"
	
	| tempSize |
	
	tempSize _ (aBump bitShift: self class indexShift).
		
	myOffset _ myOffset + tempSize.
	mySize    _ mySize    - tempSize.
	myCount  _ myCount - aBump.
	
	^self! !

!TypedPtr methodsFor: 'Smalltalk accessing'!

{Integer} count
	"Answer the number of indexable fields in the receiver.  This value is the 
	same as the largest legal subscript + 1.  Essential.  See documentation in Object 
	metaclass."
	
	"Note that we can get the size of the elements by asking the subclass 'indexShift'
	and using it to shift a 1. "

	^myCount!

{Integer} offset
	"Answer the starting-point offset in the CharPrimArray we're built on. "

	^myOffset!

{Integer} rawSize
	"Answer the size of our subset of the CharPrimArray we're built on. "

	^mySize!

{ByteArray} underlyingArray
	"Answer the underlying array we're built on. "

	^myUnderlyingArray! !

!TypedPtr methodsFor: 'accessing'!

+ value
	" ptr + value "
	
	^self clone preInc: value.!

- value
	" ptr - value "

	(value isKindOf: Number) ifTrue: [
		^self clone preDec: value.
	].
	(value isKindOf: TypedPtr) and: [
	((self class indexShift) = (value class indexShift)) and: [
	(myUnderlyingArray == (value underlyingArray)) ifTrue: [
		^(myOffset - (value offset)) bitShift: (self class indexShift negated).
	]]].
	self error: 'Difference of incomparable TypedPtrs'!

at
	" *ptr "
	
	^self at: 0.!

put: value
	" *ptr = "
	
	^self at: 0 put: value.! !

!TypedPtr methodsFor: 'private: Smalltalk private'!

{UInt2} doIndex: index {UInt2}
	"Coerce the index to an integer type,
	 test it against subscript bounds,
	 scale it and add the offset."
	 
	 "This method is overridden in UInt1Ptr to delete the (redundant) scaling."
	
	index isInteger ifFalse:
		[(index isKindOf: Number)
		ifTrue: [^self doIndex: index truncated]
		ifFalse: [self errorNonIntegerIndex]].
		
	index < 0 ifTrue: [self errorSubscriptBounds: index].
	index >= myCount ifTrue: [self errorSubscriptBounds: index].
	
	^(index bitShift: self class indexShift) + myOffset + 1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TypedPtr class
	instanceVariableNames: ''!


!TypedPtr class methodsFor: 'Smalltalk instance creation'!

newZeroed
	"myType ptr;"
	"ptr = calloc(sizeof(myType));"
	"ptr = new myType; (and clear it to 0)"
	
	"Answer a TypedPtr pointing to a new (initially zeroed) single element"

	^self newZeroed: 1!

newZeroed: aSize
	"myType ptr[aSize]"
	"ptr = calloc(aSize * sizeof(myType))"
	"ptr = new myType[aSize]; (and clear it to 0)"
	
	"Answer a TypedPtr pointing to a new (initially zeroed) array"
	| tSize tArray |

	tSize _ aSize bitShift: (self indexShift).
	tArray _ ByteArray create: tSize.
	1 to: tSize do: [ :i |
		tArray at: i put: 0 ].
	^self withByteArray: tArray.!

withByteArray: aByteArray {ByteArray}
	"Create an instance (of a real subclass) from as much of a UInt1Array as we can."

	^self new withByteArray: aByteArray from: 0 count: (aByteArray sizeInBytes bitShift: (0 - self indexShift))!

withByteArray: aByteArray {ByteArray} from: aStart {UInt2} count: aCount {UInt2}
	"Create an instance (of a real subclass)"

	^self new withByteArray: aByteArray from: aStart count: aCount!

withTypedPtr: aTypedPtr {TypedPtr}
	"Create an instance (of a real subclass) from as much of the other TypedPtr as we can."

	^self new
		withByteArray: (aTypedPtr underlyingArray)
		from: 0
		count: (aTypedPtr rawSize bitShift: (0 - self indexShift)).!

withTypedPtr: aTypedPtr {TypedPtr} from: aStart {UInt2} count: aCount {UInt2}
	"Create an instance from (a subset of) an existing TypedPtr"
	
	((aTypedPtr rawSize) - (aTypedPtr offset)) < (aCount bitShift: (self indexShift))
		ifTrue: [ self error: 'new one overflows old one' ].
		
	^self new
		withByteArray: (aTypedPtr underlyingArray)
		from: ((aTypedPtr offset) + ( aStart bitShift: (aTypedPtr class indexShift)))
		count: aCount.! !

!TypedPtr class methodsFor: 'testing'!

test
	"Run some tests on the TypedPtr classes"

	"TypedPtr test."

	|  underlyingArrayP uInt1PtrP uInt2PtrP uInt4PtrP |

	underlyingArrayP _ CharPrimArray createFromString: 'This is a test!!?'.
	uInt1PtrP _ UInt1Ptr withByteArray: underlyingArrayP from: 3 count: 6.
	uInt2PtrP _ UInt2Ptr withByteArray: underlyingArrayP from: 4 count: 5.
	uInt4PtrP _ UInt4Ptr withByteArray: underlyingArrayP from: 4 count: 3.

	Transcript cr. underlyingArrayP printOn: Transcript. Transcript endEntry.
	Transcript cr; show: '16r'. (uInt1PtrP at: 5) printOn: Transcript base: 16. Transcript endEntry.
	Transcript cr; show: '16r'. (uInt2PtrP at: 1) printOn: Transcript base: 16. Transcript endEntry.
	Transcript cr; show: '16r'. (uInt4PtrP at: 2) printOn: Transcript base: 16. Transcript endEntry.

	uInt1PtrP at: 5 put: 16r41.
	uInt2PtrP at: 1 put: 16r532E.
	uInt4PtrP at: 2 put: 16r53543F21.

	Transcript cr. underlyingArrayP printOn: Transcript. Transcript endEntry.
	Transcript cr; show: '16r'. (uInt1PtrP at: 5) printOn: Transcript base: 16. Transcript endEntry.
	Transcript cr; show: '16r'. (uInt2PtrP at: 1) printOn: Transcript base: 16. Transcript endEntry.
	Transcript cr; show: '16r'. (uInt4PtrP at: 2) printOn: Transcript base: 16. Transcript endEntry.

	uInt2PtrP at: 1 put: 16r002E.
	Transcript cr. underlyingArrayP printOn: Transcript. Transcript endEntry.

	uInt2PtrP at: 1 put: 16r532E.
	Transcript cr. underlyingArrayP printOn: Transcript. Transcript endEntry.

	^self!

test2
	"Run some tests on the TypedPtr classes"
	
	"TypedPtr test2."

	|  charPrimArrayP "uInt1PtrP" |
	
	charPrimArrayP _ CharPrimArray createFromString: '123456789
'.
	"uInt1PtrP _ UInt1Ptr withCharPrimArray: charPrimArrayP from: 3 count: 6."
	
	Transcript cr. charPrimArrayP printOn: Transcript. Transcript endEntry.
	Transcript cr. 0 to: 10 do: [:i | (charPrimArrayP at: i) asInteger printOn: Transcript base: 16. Transcript show: ' ']. Transcript endEntry.
	"Transcript cr; show: '16r'. (uInt1PtrP at: 5) printOn: Transcript base: 16. Transcript endEntry."
	
	^self! !