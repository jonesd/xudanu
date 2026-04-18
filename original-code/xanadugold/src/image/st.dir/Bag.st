'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:23 pm'!

Collection subclass: #Bag
	instanceVariableNames: 'contents '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Unordered'!
Bag comment:
'A Bag is an unordered collection of elements.  It stores these elements in a dictionary, tallying up occurrences of equal objects.  Because a Bag can store an occurrence only once, its clients should beware that objects they store will not necessarily be retrieved such that == is true.  If the client cares, a subclass of Bag should be created.

Instance Variables:
	contents		<Dictionary> of associations between elements and the number of occurrences of each element in the Bag'!


!Bag methodsFor: 'accessing'!

at: anInteger
	"Provide an error notification that elements of a Bag
	are not accessible by external keys."
 
	^self notKeyedError!

at: anInteger put: anObject
	"Provide an error notification that elements of a Bag
	are not accessible by external keys."

	^self notKeyedError!

size
	"Answer how many elements the receiver contains."

	| tally |
	tally _ 0.
	contents do: [:each | tally _ tally + each].
	^tally!

sortedCounts
	"Answer a collection of counts with elements, sorted by decreasing 
	count. "

	| counts |
	counts _ SortedCollection sortBlock: [:x :y | x >= y].
	contents associationsDo: 
		[:assn | counts add: (Association key: assn value value: assn key)].
	^counts!

sortedElements
	"Answer a collection of elements with counts, sorted by element."

	| elements |
	elements _ SortedCollection new.
	contents associationsDo: [:assn | elements add: assn].
	^ elements! !

!Bag methodsFor: 'testing'!

includes: anObject 
	"Answer whether anObject is one of the receiver's elements."

	^contents includesKey: anObject!

occurrencesOf: anObject 
	"Answer how many of the receiver's elements are equal to anObject."

	(self includes: anObject)
		ifTrue: [^contents at: anObject]
		ifFalse: [^0]! !

!Bag methodsFor: 'adding'!

add: newObject 
	"Include newObject as one of the receiver's elements.  Answer newObject."

	^self add: newObject withOccurrences: 1!

add: newObject withOccurrences: anInteger 
	"Add the element newObject to the elements of the receiver.  Do so as
	though the element were added anInteger number of times.  Answer newObject."

	(self includes: newObject)
		ifTrue: [contents at: newObject put: anInteger + (contents at: newObject)]
		ifFalse: [contents at: newObject put: anInteger].
	^newObject! !

!Bag methodsFor: 'removing'!

remove: oldObject ifAbsent: exceptionBlock  
	"Remove oldObject as one of the receiver's elements.  If several of the
	elements are equal to oldObject, only one is removed. If no element is equal to
	oldObject, answer the result of evaluating anExceptionBlock.  Otherwise,
	answer the argument, oldObject."

	| count |
	(self includes: oldObject)
		ifTrue: [(count _ contents at: oldObject) = 1
				ifTrue: [contents removeKey: oldObject]
				ifFalse: [contents at: oldObject put: count - 1]]
		ifFalse: [^exceptionBlock value].
	^oldObject! !

!Bag methodsFor: 'enumerating'!

do: aBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument."

	contents associationsDo: [:assoc | assoc value timesRepeat: [aBlock value: assoc key]]! !

!Bag methodsFor: 'private: private'!

setDictionary
	"Initialize the instance variable."

	contents _ Dictionary new! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Bag class
	instanceVariableNames: ''!


!Bag class methodsFor: 'instance creation'!

new
	"Create an instance of Bag whose contents are empty."

	^super new setDictionary! !