'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:20 pm'!

SequenceableCollection subclass: #ArrayedCollection
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Abstract'!
ArrayedCollection comment:
'The abstract class ArrayedCollection represents a collection of elements with integers as external keys.   Its subclasses are
	Array		elements are pointers
	ByteArray	elements are bytes
	RunArray	elements are typically runs of the same thing
	String		elements are characters
	Text		elements are characters with style
	WordArray	elements are words

It re-implements several messages inherited from SequenceableCollection in order to obtain some performance gains.  

Subclasses should not implement methods for
	adding
		add:
	removing
		remove:ifAbsent:'!


!ArrayedCollection methodsFor: 'accessing'!

size
	"Answer the number of indexable fields in the receiver. This value is the 
	same as the largest legal subscript.  Primitive is specified here to override 
	SequenceableCollection size.  Essential.  See Object documentation 
	whatIsAPrimitive. "

	<primitive: 62>
	^self basicSize! !

!ArrayedCollection methodsFor: 'adding'!

add: newObject
	"ArrayedCollections cannot implement add:."

	self shouldNotImplement! !

!ArrayedCollection methodsFor: 'printing'!

storeOn: aStream 
	"Append to the argument aStream a sequence of characters that is an
	expression whose evaluation creates an object similar to the receiver.
	For an ArrayedCollection, the general format is
		((class-name new: size) 
			at: index put: element; at: nextIndex put: element; yourself)
	"

	aStream nextPutAll: '(('.
	aStream nextPutAll: self class name.
	aStream nextPutAll: ' new: '.
	aStream store: self size.
	aStream nextPut: $).
	(self storeElementsFrom: 1 to: self size on: aStream)
		ifFalse: [aStream nextPutAll: '; yourself'].
	aStream nextPut: $)! !

!ArrayedCollection methodsFor: 'private: private'!

defaultElement
	"Answer the object that is stored when no specific object is indicated."

	^nil!

storeElementsFrom: firstIndex to: lastIndex on: aStream 
	"Append to the argument aStream a description of elements of the
	receiver starting with the element at position firstIndex and ending
	with the element at position lastIndex.  The general format for each
	position is
			at: index put: element
	separated by semicolons."

	| noneYet defaultElement arrayElement |
	noneYet _ true.
	defaultElement _ self defaultElement.
	firstIndex to: lastIndex do: 
		[:index | 
		arrayElement _ self at: index.
		arrayElement = defaultElement
			ifFalse: 
				[noneYet
					ifTrue: [noneYet _ false]
					ifFalse: [aStream nextPut: $;].
				aStream nextPutAll: ' at: '.
				aStream store: index.
				aStream nextPutAll: ' put: '.
				aStream store: arrayElement]].
	^noneYet! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ArrayedCollection class
	instanceVariableNames: ''!


!ArrayedCollection class methodsFor: 'instance creation'!

new
	"Answer a new instance of ArrayedCollection with size = 0."

	^self new: 0!

new: size withAll: value 
	"Answer a new instance of ArrayedCollection whose every element is 
	equal to the argument, value."

	^(self new: size)
		atAllPut: value!

with: anObject 
	"Answer a new instance of ArrayedCollection, containing only anObject."

	| newCollection |
	newCollection _ self new: 1.
	newCollection at: 1 put: anObject.
	^newCollection!

with: firstObject with: secondObject 
	"Answer a new instance of ArrayedCollection, containing firstObject 
	and secondObject."

	| newCollection |
	newCollection _ self new: 2.
	newCollection at: 1 put: firstObject.
	newCollection at: 2 put: secondObject.
	^newCollection!

with: firstObject with: secondObject with: thirdObject 
	"Answer a new instance of ArrayedCollection, containing only these 
	three objects."

	| newCollection |
	newCollection _ self new: 3.
	newCollection at: 1 put: firstObject.
	newCollection at: 2 put: secondObject.
	newCollection at: 3 put: thirdObject.
	^newCollection!

with: firstObject with: secondObject with: thirdObject with: fourthObject 
	"Answer a new instance of ArrayedCollection, containing the four 
	arguments as the elements."

	| newCollection |
	newCollection _ self new: 4.
	newCollection at: 1 put: firstObject.
	newCollection at: 2 put: secondObject.
	newCollection at: 3 put: thirdObject.
	newCollection at: 4 put: fourthObject.
	^newCollection! !