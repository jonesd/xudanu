'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:55 pm'!

Rectangle subclass: #CharacterBlock
	instanceVariableNames: 'stringIndex character '
	classVariableNames: ''
	poolDictionaries: 'TextConstants '
	category: 'Graphics-Support'!
CharacterBlock comment:
'Class CharacterBlock represents information about displayed characters.  Instances are used to return the results of methods
	Paragraph characterBlockAtPoint: aPoint and
	Paragraph characterBlockForIndex: stringIndex.
Any recomposition or movement of a Paragraph can make the information obsolete.

Instance Variables:
	stringIndex	<Integer> the position of the receiver in the displayed string
	character	<Character> the displayed character

Pool Dictionary:
	TextConstants	<Dictionary>'!


!CharacterBlock methodsFor: 'comparing'!

< aCharacterBlock 
	"Answer whether the string index of the receiver precedes that of 
	the argument, aCharacterBlock."

	^stringIndex < aCharacterBlock stringIndex!

<= aCharacterBlock 
	"Answer whether the string index of the receiver does not come after that of
	aCharacterBlock."

	^(self > aCharacterBlock) not!

= aCharacterBlock 
	"Answer whether the string index of the receiver is that same
	as that of the argument, aCharacterBlock."

	self species = aCharacterBlock species
		ifTrue: [^stringIndex = aCharacterBlock stringIndex]
		ifFalse: [^false]!

> aCharacterBlock 
	"Answer whether the string index of the receiver comes after that of
	aCharacterBlock."

	^aCharacterBlock < self!

>= aCharacterBlock 
	"Answer whether the string index of the receiver does not precede that of
	aCharacterBlock."

	^(self < aCharacterBlock) not! !

!CharacterBlock methodsFor: 'copying'!

copy
	"Answer another instance just like the receiver."

	^self deepCopy! !

!CharacterBlock methodsFor: 'accessing'!

character
	"Answer the character in the receiver."

	^character!

stringIndex
	"Answer the position of the receiver in the string that it indexes."

	^stringIndex!

stringIndex: index
	 "Store the argument index as the position of the character in the string."

	stringIndex _ index! !

!CharacterBlock methodsFor: 'printing'!

printOn: aStream  
	"Append to the argument aStream a sequence of characters that identifies the receiver.
	The general format is
		a CharacterBlock with index stringindex and character character and rectangle etc."

	aStream nextPutAll: 'a CharacterBlock with index '.
	stringIndex printOn: aStream.
	aStream nextPutAll: ' and character '.
	character printOn: aStream.
	aStream nextPutAll: ' and rectangle '.
	super printOn: aStream! !

!CharacterBlock methodsFor: 'private: private'!

newStringIndex: anInteger Character: aCharacter BoundingRectangle: aRectangle 	
	stringIndex _ anInteger.
	character _ aCharacter.
	super origin: aRectangle topLeft.
	super corner: aRectangle corner!

newStringIndex: anInteger Character: aCharacter TopLeft: originPoint Extent: extentPoint 
	stringIndex _ anInteger.
	character _ aCharacter.
	super origin: originPoint.
	super extent: extentPoint! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CharacterBlock class
	instanceVariableNames: ''!


!CharacterBlock class methodsFor: 'instance creation'!

stringIndex: anInteger character: aCharacter boundingRectangle: aRectangle 
	"Answer an instance of the receiver with values set to the arguments."

	^self new
		newStringIndex: anInteger
		Character: aCharacter
		BoundingRectangle: aRectangle!

stringIndex: anInteger character: aCharacter topLeft: originPoint extent: extentPoint 
	"Answer an instance of the receiver with values set to the arguments."

	^self new
		newStringIndex: anInteger
		Character: aCharacter
		TopLeft: originPoint
		Extent: extentPoint! !