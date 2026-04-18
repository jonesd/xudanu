'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:31 pm'!

Symbol variableByteSubclass: #ByteSymbol
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Text'!
ByteSymbol comment:
'Instances of class ByteSymbol are uniquely stored, immutable, indexed collections of Characters.  See Symbol for more information.  ByteSymbols store characters as bytes: the access protocol translates between these and real Character objects.

Instance Variables: *byte indexed*'!


!ByteSymbol methodsFor: 'accessing'!

at: index 
	"Answer the Character stored in the field of the receiver indexed by the 
	argument.  Fail if the index argument is not an Integer or is out of bounds.  
	Optional.  See Object documentation whatIsAPrimitive."

	<primitive: 63>
	^Character value: (super at: index)! !

!ByteSymbol methodsFor: 'private: private'!

species
	^ByteString!

string: aString 
	self size = aString size ifFalse: [self error: 'aString size must be equal to receiver size'].
	1 to: aString size do: [:j |
		| code |
		(code _ (aString at: j) asciiValue) < 256
			ifTrue: [self basicAt: j put: code]
			ifFalse: 
				[| two |
				two _ TwoByteSymbol new: self size.
				two string: aString.
				self become: two.
				^self]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ByteSymbol class
	instanceVariableNames: ''!


!ByteSymbol class methodsFor: 'instance creation'!

new: size
	"Redefined here to override String new:"
	^self basicNew: size! !