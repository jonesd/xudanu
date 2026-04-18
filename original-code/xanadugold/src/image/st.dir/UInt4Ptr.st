'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:15 pm'!

TypedPtr subclass: #UInt4Ptr
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!


!UInt4Ptr methodsFor: 'accessing'!

{UInt4} at: index {UInt2}
	" ptr[index] "
	
	"Answer the value of an indexable field in the receiver. Fail if the 
	argument index is not an Integer or is out of bounds. Essential. See 
	documentation in Object metaclass."
	
	| tempIndex tempInt |
	
	tempIndex _ self doIndex: index.
	tempInt _ (myUnderlyingArray at: tempIndex) bitShift: 24.
	tempInt _ tempInt + ((myUnderlyingArray at: tempIndex + 1) bitShift: 16).	
	tempInt _ tempInt + ((myUnderlyingArray at: tempIndex + 2) bitShift: 8).	
 	tempInt _ tempInt + (myUnderlyingArray at: tempIndex + 3).
 	^tempInt!

{UInt4} at: index {UInt2} put: value {UInt4}
	" ptr[index] = "
	
	"Store the argument value in the indexable field of the receiver indicated by 
	index. Fail if the index is not an Integer or is out of bounds. Fail if the 
	value is not of the right type for this kind of collection. Answer the 
	value that was stored. Essential. See documentation in Object metaclass."
	
	| tempIndex |
	
	tempIndex _ self doIndex: index.
	myUnderlyingArray at: tempIndex put: ((value bitShift: -24) bitAnd: 16rFF).
	myUnderlyingArray at: tempIndex + 1 put: ((value bitShift: -16) bitAnd: 16rFF).	
	myUnderlyingArray at: tempIndex + 2 put: ((value bitShift: -8) bitAnd: 16rFF).	
 	myUnderlyingArray at: tempIndex + 3 put: (value bitAnd: 16rFF).
 	^value bitAnd: 16rFFFFFFFF! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

UInt4Ptr class
	instanceVariableNames: ''!


!UInt4Ptr class methodsFor: 'private: Smalltalk private'!

{Integer} indexShift
	"Answer the base-2 log of the size of each of our elements. "

	^2! !