'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:13 pm'!

Object subclass: #PtrPtr
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
PtrPtr comment:
'FuncPtr is a class used to simulate C and C++ pointers-to-functions.
(See also: TypedPtr)
Unlike TypedPtrs, FuncPtrs cannot be converted to a nice bit pattern and stored in a struct-field-like charPrimArray.

The following operations are defined:

	Smalltalk									C / C++ equivalent.  (Actually, should be another *)
	---------									-----------------------------------------------------
	aFuncPtr at								*aFuncPtr						aTypedPtr[0]
	aFuncPtr at: anInt							*aFuncPtr + anInt				aTypedPtr[anInt]
	aFuncPtr put: aValue						*aFuncPtr = aValue				aTypedPtr[0] = aValue
	aFuncPtr at: anInt put: aValue				*aFuncPtr + anInt = aValue	aTypedPtr[anInt] = aValue
	aFuncPtr preInc								++aFuncPtr
	aFuncPtr preInc: anInt						aFuncPtr =+ anInt
	aFuncPtr preDec							--aFuncPtr
	aFuncPtr preDec: anInt						aFuncPtr =- anInt
	aFuncPtr postInc							aFuncPtr++
	aFuncPtr postInc: anInt						aFuncPtr += anInt
	aFuncPtr postDec							aFuncPtr--
	aFuncPtr postDec: anInt					aFuncPtr -= anInt
	bFuncPtr _ aFuncPtr clone					bFuncPtr = aTypedPtr  (Remember that smalltalk vars are themselves pointers)
	
	aFuncPtr apply								(*aFuncPtr)()
	aFuncPtr applyWith: a1						(*aFuncPtr)(a1)
	aFuncPtr applyWith: a1						(*aFuncPtr)(a1,a2)
	aFuncPtr applyWith: a1						(*aFuncPtr)(a1,a2,a3)
	aFuncPtr applyWithArguments: args			(*aFuncPtr)(args)
	
	aFuncPtr apply: n							(*aFuncPtr[n])()
	aFuncPtr apply: n With: a1					(*aFuncPtr[n])(a1)
	aFuncPtr apply: n With: a1					(*aFuncPtr[n])(a1,a2)
	aFuncPtr apply: n With: a1					(*aFuncPtr[n])(a1,a2,a3)
	aFuncPtr apply: n WithArguments: args		(*aFuncPtr[n])(args)
	
	Smalltalk-only methods
	--------------------
	FuncPtr withPrimArray: x from: anInt count: anInt	(~declaration of a member of a struct)
	FuncPtr withPrimArray: x								(~declaration of a member of a union)
	FuncPtr withPrimArray: x from: anInt count: anInt	(~declaration of a member of a struct)
	FuncPtr withPrimArray: x							(~declaration of a member of a union or {make a copy} cast to another type)
	
	aFuncPtr primArray							(The address of the vector it''s built on...)
	aFuncPtr count								(number of elements here-to-right-end)
	aFuncPtr offset								(number of elements left of where we point in basic array)

FuncPtrs send self error if you try to make a reference outside the defined region.

These tests should NOT be converted to blasts, because the corresponding C/C++ operations do NOT do the tests.

(The underflow test currently only tests for the pointer going off the bottom of the basic PrimArray, not the bottom of the subset.)'!


!PtrPtr methodsFor: 'Smalltalk instance creation'!

clone

	^self class withPrimArray: myPrimArray from: myOffset count: myCount! !

!PtrPtr methodsFor: 'Smalltalk initialization'!

withPrimArray: aPrimArray {PrimArray} from: aStart {UInt2} count: aCount {UInt2}
	"Initialize FuncPtr instance"
	
	myPrimArray _ aPrimArray.
	myOffset _ aStart.
	myCount _ aCount.

	(myCount + myOffset) > (myPrimArray count)
		ifTrue:  [self error: 'Overruns containing PrimArray'].
	
	^self! !

!PtrPtr methodsFor: 'twiddling'!

postDec
	"ptr--"
	
	| tCopy |
	
	tCopy _ self copy.
	self preDec.
	^tCopy!

postDec: aBump {UInt2}
	"ptr -= aBump"
	
	| tCopy |
	
	tCopy _ self copy.
	self preDec: aBump.
	^tCopy!

postInc
	"ptr++"
	
	| tCopy |
	
	tCopy _ self copy.
	self preInc.
	^tCopy!

postInc: aBump {UInt2}
	"ptr += aBump"
	
	| tCopy |
	
	tCopy _ self copy.
	self preInc: aBump.
	^tCopy!

preDec
	"--ptr"
	
	^self preDec: 1!

preDec: aBump {UInt2}
	"ptr -= aBump"
	
	myOffset _ myOffset - aBump.
	myCount  _ myCount + aBump.
	
	^self!

preInc
	"++ptr"
		
	^self preInc: 1!

preInc: aBump {UInt2}
	"ptr += aBump"
		
	myOffset _ myOffset + aBump.
	myCount  _ myCount - aBump.
	
	^self! !

!PtrPtr methodsFor: 'Smalltalk accessing'!

{Integer} count
	"Answer the number of indexable fields in the receiver.  This value is the 
	same as the largest legal subscript + 1.  Essential.  See documentation in Object 
	metaclass."
	
	^myCount!

{Integer} offset
	"Answer the starting-point offset in the PrimArray we're built on. "

	^myOffset!

{PrimArray} primArray
	"Answer the CharPrimArray we're built on. "

	^myPrimArray! !

!PtrPtr methodsFor: 'accessing'!

at
	" *ptr "
	
	^self at: 0.!

{Char} at: index {UInt2}
	" ptr[index] "
	
	"Answer the value of an indexable field in the receiver. Fail if the 
	argument index is not an Integer or is out of bounds. Essential. See 
	documentation in Object metaclass."
	
	^myPrimArray at: (self doIndex: index)!

{Char} at: index {UInt2} put: value {Char}
	" ptr[index] = "
	
	"Store the argument value in the indexable field of the receiver indicated by 
	index. Fail if the index is not an Integer or is out of bounds. Fail if the 
	value is not of the right type for this kind of collection. Answer the 
	value that was stored. Essential. See documentation in Object metaclass."
	
	^myPrimArray at: (self doIndex: index) put: value!

put: value
	" *ptr = "
	
	^self at: 0 put: value.! !

!PtrPtr methodsFor: 'private: Smalltalk private'!

{UInt2} doIndex: index {UInt2}
	"Coerce the index to an integer type,
	 test it against subscript bounds,
	 scale it and add the offset."
	
	index isInteger ifFalse:
		[(index isKindOf: Number)
		ifTrue: [^self doIndex: index truncated]
		ifFalse: [self errorNonIntegerIndex]].
		
	index < 0 ifTrue: [self errorSubscriptBounds: index].
	index >= myCount ifTrue: [self errorSubscriptBounds: index].
	
	^index + myOffset! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PtrPtr class
	instanceVariableNames: ''!


!PtrPtr class methodsFor: 'Smalltalk instance creation'!

withFuncPtr: aFuncPtr {FuncPtr}
	"Create an instance from as much of the other FuncPtr as we can."

	^self new
		withPrimArray: (aFuncPtr primArray)
		from: 0
		count: (aFuncPtr count).!

withFuncPtr: aFuncPtr {FuncPtr} from: aStart {UInt2} count: aCount {UInt2}
	"Create an instance"

	^self new
		withCharPrimArray: (aFuncPtr primArray)
		from: ((aFuncPtr offset) + ( aStart ))
		count: aCount.!

withPrimArray: aPrimArray {PrimArray}
	"Create an instance of from as much of a PrimArray as we can."

	^self new withPrimArray: aPrimArray from: 0 count: (aPrimArray count)!

withPrimArray: aPrimArray {PrimArray} from: aStart {UInt2} count: aCount {UInt2}
	"Create an instance"

	^self new withPrimArray: aPrimArray from: aStart count: aCount! !