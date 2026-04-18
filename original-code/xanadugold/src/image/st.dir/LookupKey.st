'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:42 pm'!

Magnitude subclass: #LookupKey
	instanceVariableNames: 'key '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Support'!
LookupKey comment:
'An instance of class LookupKey serves as the key for looking up entries in a Dictionary.  Subclasses of LookupKey are dictionary entries.  An available example is Association.

Instance Variables:
	key <Object> that can be used for testing associations'!


!LookupKey methodsFor: 'accessing'!

key
	"Answer the lookup key of the receiver."

	^key!

key: anObject 
	"Store the argument, anObject, as the lookup key of the receiver."

	key _ anObject! !

!LookupKey methodsFor: 'comparing'!

< aLookupKey 
	"Answer whether the receiver is less than the argument."

	^key < aLookupKey key!

= aLookupKey 
	"Answer whether the receiver is equal to the argument."

	self species = aLookupKey species
		ifTrue: [^key = aLookupKey key]
		ifFalse: [^false]!

hash
	"Answer a SmallInteger unique to the receiver."

	^key hash! !

!LookupKey methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	key printOn: aStream! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LookupKey class
	instanceVariableNames: ''!


!LookupKey class methodsFor: 'instance creation'!

key: aKey 
	"Answer a new instance of the receiver with the argument as the lookup up."

	^self new key: aKey! !