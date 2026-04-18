'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:41 pm'!

LookupKey subclass: #Association
	instanceVariableNames: 'value '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Support'!
Association comment:
'An Association is a pair of associated objects--a key and a value.  It can serve as an entry in a dictionary.  Think of the key as the left-hand side of the dictionary and the value as the right-hand side.

Instance Variable:
	value	<Object>'!


!Association methodsFor: 'accessing'!

key: aKey value: anObject 
	"Store the arguments as the variables of the receiver."

	key _ aKey.
	value _ anObject!

refAssign: anObject 
	"Store the argument, anObject, as the value of the receiver."

	value _ anObject!

refValue
	"Answer the value of the receiver."

	^value!

value
	"Answer the value of the receiver."

	^value!

value: anObject 
	"Store the argument, anObject, as the value of the receiver."

	value _ anObject! !

!Association methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument, aStream, the two elements of the 
	Association separated by a right arrow."

	super printOn: aStream.
	aStream nextPutAll: '->'.
	value printOn: aStream! !

!Association methodsFor: 'comparing'!

sameAs: anAssociation
	^ (anAssociation isKindOf: Association) and: [(self key = anAssociation key) and: [self value = anAssociation value]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Association class
	instanceVariableNames: ''!


!Association class methodsFor: 'instance creation'!

key: newKey value: newValue
	"Answer a new instance of the receiver with the arguments as the key and
	value of the association."

	^(super key: newKey) value: newValue! !