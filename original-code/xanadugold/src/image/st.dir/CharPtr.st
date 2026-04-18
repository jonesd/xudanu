'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:05 pm'!

TypedPtr subclass: #CharPtr
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!


!CharPtr methodsFor: 'accessing'!

{Char} at: index {UInt2}
	" ptr[index] "
	
	"Answer the value of an indexable field in the receiver. Fail if the 
	argument index is not an Integer or is out of bounds. Essential. See 
	documentation in Object metaclass."
	
	^(myUnderlyingArray at: (self doIndex: index)) asCharacter!

{Char} at: index {UInt2} put: value {Char}
	" ptr[index] = "
	
	"Store the argument value in the indexable field of the receiver indicated by 
	index. Fail if the index is not an Integer or is out of bounds. Fail if the 
	value is not of the right type for this kind of collection. Answer the 
	value that was stored. Essential. See documentation in Object metaclass."
	
	^myUnderlyingArray at: (self doIndex: index) put: (value asInteger)!

{Char} at: index {UInt2} putAll: aCollection {Char}
	" ptr[index] = "
	
	"Append the elements of aCollection onto the receiver.  Answer aCollection."
	
	| tPtr |
	
	(index + (aCollection size)) > (self rawSize) ifTrue: [self error: 'putAll overflow'].

	tPtr _ self clone.
	aCollection do: [:v | tPtr at: index put: v; preInc].
	^aCollection!

{Char} putAll: aCollection {Char}
	" ptr[index] = "
	
	"Append the elements of aCollection onto the receiver.  Answer aCollection."
	
	| tPtr |
	
	(aCollection size) > (self rawSize) ifTrue: [self error: 'putAll overflow'].

	tPtr _ self clone.
	aCollection do: [:v | tPtr put: v; preInc].
	^aCollection! !

!CharPtr methodsFor: 'private: Smalltalk private'!

{UInt2} doIndex: index {UInt2}
	"Coerce the index to an integer type,
	 test it against subscript bounds,
	 scale it and add the offset."
	 
	 "This method is overridden in CharPtr to delete the scaling."
	
	index isInteger ifFalse:
		[(index isKindOf: Number)
		ifTrue: [^self doIndex: index truncated]
		ifFalse: [self errorNonIntegerIndex]].
		
	index < 0 ifTrue: [self errorSubscriptBounds: index].
	index >= myCount ifTrue: [self errorSubscriptBounds: index].
	
	^index + myOffset + 1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CharPtr class
	instanceVariableNames: ''!


!CharPtr class methodsFor: 'private: Smalltalk private'!

{Integer} indexShift
	"Answer the base-2 log of the size of each of our elements. "

	^0! !