'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:05 pm'!

Object subclass: #FuncPtr
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
FuncPtr comment:
'FuncPtr is a class used to simulate C and C++ pointers-to-functions.
(See also: TypedPtr)
Unlike TypedPtrs, FuncPtrs cannot be converted to a nice bit pattern and stored in a struct-field-like charPrimArray.
They also cannot be incremented, decremented, subscripted, etc (though pointers TO them CAN).

The following operations are defined:

	Smalltalk									C / C++ equivalent.  (Actually, should be another *)
	---------									-----------------------------------------------------
	
	aFuncPtr apply								(*aFuncPtr)()
	aFuncPtr applyWith: a1						(*aFuncPtr)(a1)
	aFuncPtr applyWith: a1	 with: a2			(*aFuncPtr)(a1,a2)
	aFuncPtr applyWith: a1	 with: a2 with: a3	(*aFuncPtr)(a1,a2,a3)
	aFuncPtr applyWithArguments: args			(*aFuncPtr)(args)
	
	FuncPtr class: aClass message: aMessage	(&function)
'!


!FuncPtr methodsFor: 'Smalltalk instance creation'!

clone

	^self class withPrimArray: myPrimArray from: myOffset count: myCount! !

!FuncPtr methodsFor: 'twiddling'!

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

!FuncPtr methodsFor: 'Smalltalk accessing'!

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

!FuncPtr methodsFor: 'private: Smalltalk private'!

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

!FuncPtr methodsFor: 'Smalltalk initialization'!

class: aClass message: aMessage
	"create"

	myFuncsClass _ aClass.
	myFuncsMessage _ aMessage.
	
	^self!

withPrimArray: aPrimArray {PrimArray} from: aStart {UInt2} count: aCount {UInt2}
	"Initialize FuncPtr instance"
	
	myPrimArray _ aPrimArray.
	myOffset _ aStart.
	myCount _ aCount.

	(myCount + myOffset) > (myPrimArray count)
		ifTrue:  [self error: 'Overruns containing PrimArray'].
	
	^self! !

!FuncPtr methodsFor: 'accessing'!

apply
	" (*ptr)() "
	
	^myFuncsClass perform: myFuncsMessage!

applyWith: arg1
	" (*ptr)(arg1) "
	
	^myFuncsClass perform: myFuncsMessage with: arg1.!

applyWith: arg1 with: arg2
	" (*ptr)(arg1,arg2) "
	
	^myFuncsClass perform: myFuncsMessage with: arg1 with: arg2.!

applyWith: arg1 with: arg2 with: arg3
	" (*ptr)(arg1,arg2,arg3) "
	
	^myFuncsClass perform: myFuncsMessage with: arg1 with: arg2 with: arg3.!

applyWithArguments: argList
	" (*ptr)(argList) "
	
	^myFuncsClass perform: myFuncsMessage withArguments: argList.!

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
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FuncPtr class
	instanceVariableNames: ''!


!FuncPtr class methodsFor: 'Smalltalk instance creation'!

class: aClass message: aMessage
	"create"

	^self new class: aClass message: aMessage!

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