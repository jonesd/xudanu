'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:14 pm'!

TypedPtr subclass: #UInt2Ptr
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!


!UInt2Ptr methodsFor: 'accessing'!

{UInt2} at: index {UInt2}
	" ptr[index] "
	
	"Answer the value of an indexable field in the receiver. Fail if the 
	argument index is not an Integer or is out of bounds. Essential. See 
	documentation in Object metaclass."
	
	| tempIndex tempInt |
	
	tempIndex _ self doIndex: index.
	tempInt _ (myUnderlyingArray at: tempIndex) bitShift: 8.
 	tempInt _ tempInt + (myUnderlyingArray at: tempIndex + 1).
 	^tempInt!

{UInt2} at: index {UInt2} put: value {UInt2}
	" ptr[index] = "
	
	"Store the argument value in the indexable field of the receiver indicated by 
	index. Fail if the index is not an Integer or is out of bounds. Fail if the 
	value is not of the right type for this kind of collection. Answer the 
	value that was stored. Essential. See documentation in Object metaclass."
	
	| tempIndex |
	
	tempIndex _ self doIndex: index.
	myUnderlyingArray at: tempIndex put: ((value bitShift: -8) bitAnd: 16rFF).
 	myUnderlyingArray at: tempIndex + 1 put: (value bitAnd: 16rFF).
 	^value bitAnd: 16rFFFF! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UInt2Ptr class
	instanceVariableNames: ''!


!UInt2Ptr class methodsFor: 'private: Smalltalk private'!

{Integer} indexShift
	"Answer the base-2 log of the size of each of our elements. "

	^1! !