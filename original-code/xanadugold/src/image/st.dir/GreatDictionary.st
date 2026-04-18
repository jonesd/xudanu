'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:25 pm'!

GreatSet variableSubclass: #GreatDictionary
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Unordered'!



!GreatDictionary methodsFor: 'accessing'!

associationAt: key 
	"Answer the association at key.  If key is not found, raise a signal."

	^self associationAt: key ifAbsent: [self keyNotFoundError: key]!

associationAt: key ifAbsent: aBlock 
	"Answer the association at key.  If key is not found, answer the
	result of evaluating aBlock."

	^ (self fetchSub: key) associationAt: key ifAbsent: aBlock!

associations
	"Answer an OrderedCollection containing the receiver's associations in an 
	arbitrary order."

	| aCollection |
	aCollection _ OrderedCollection new: self size.
	self associationsDo: [:key | aCollection add: key].
	^aCollection!

at: key 
	"Answer the value at key.  If key is not found, raise a signal."

	^self at: key ifAbsent: [self keyNotFoundError: key]!

at: key ifAbsent: aBlock 
	"Answer the value at key.  If key is not found, answer the
	result of evaluating aBlock."

	^ (self fetchSub: key) at: key ifAbsent: aBlock!

at: key ifAbsentRaise: aSignal
	"Answer the value at key.  If key is not found,
	raise aSignal with key as the parameter."

	^ (self fetchSub: key) at: key ifAbsentRaise: aSignal!

at: key put: anObject 
	"Set the value at key to be anObject.  If key is not found, create a new
	entry for key and set is value to anObject. Answer anObject."

	| oldC sub |
	oldC _ (sub _ self fetchSub: key) size.
	sub at: key put: anObject.
	sub size > oldC ifTrue: [tally _ tally + 1].
	^anObject!

keyAtValue: value 
	"Answer the key whose value equals the argument, value.  If there is none,
	raise a signal."

	^self keyAtValue: value ifAbsent: [self valueNotFoundError: value]!

keyAtValue: value ifAbsent: exceptionBlock
	"Answer the key whose value equals the argument, value.  If there is none, 
	answer the result of evaluating exceptionBlock."
 
	self associationsDo: 
		[:association | value == association value ifTrue: [^association key]].
	^exceptionBlock value!

keys
	"Answer a set containing the receiver's keys."

	| aSet |
	aSet _ Set new: self size.
	self keysDo: [:key | aSet add: key].
	^aSet!

values
	"Answer a Bag containing the receiver's values."

	| aBag |
	aBag _ Bag new.
	self do: [:value | aBag add: value].
	^aBag! !

!GreatDictionary methodsFor: 'testing'!

includes: anObject 
	"Answer whether anObject is one of the receiver's elements."

	self do: [:each | anObject = each ifTrue: [^true]].
	^false!

occurrencesOf: anObject 
	"Answer how many of the receiver's elements are equal to anObject."

	| count |
	count _ 0.
	self do: [:each | anObject = each ifTrue: [count _ count + 1]].
	^count! !

!GreatDictionary methodsFor: 'adding'!

add: anAssociation 
	"Include newObject as one of the receiver's elements.  Answer newObject."
	| subset oldSize |
	oldSize _ (subset _ self fetchSub: anAssociation key) size.
	subset add: anAssociation.
	subset size > oldSize ifTrue: [tally _ tally + 1].
	^anAssociation!

declare: key from: aDictionary 
	"Add key to the receiver.  If key already exists, do nothing.  If aDictionary includes
	key, then remove it from aDictionary and use its association as the entry to the
	receiver."

	(self includesKey: key) ifTrue: [^self].
	(aDictionary includesKey: key)
		ifTrue: 
			[self add: (aDictionary associationAt: key).
			aDictionary removeKey: key]
		ifFalse: 
			[self at: key put: nil]!

grow
	"Increase the number of elements of the collection."

	| newSelf |
	newSelf _ self copyEmpty: self basicSize + self growSize.
	self associationsDo: [:each | newSelf noCheckAdd: each].
	self become: newSelf! !

!GreatDictionary methodsFor: 'removing'!

remove: anObject 
	"Provide an error notification that removing an element
	 from a Dictionary is not allowed."

	self shouldNotImplement!

remove: anObject ifAbsent: exceptionBlock 
	"Provide an error notification that Dictionaries can not respond to
	remove: messages."

	self shouldNotImplement! !

!GreatDictionary methodsFor: 'enumerating'!

collect: aBlock 
	"Evaluate aBlock with each of the values of the receiver as the  
	argument.  Collect the resulting values into a collection that is like 
	the receiver.  Answer the new collection."

	| newCollection |
	newCollection _ Bag new.
	self do: [:each | newCollection add: (aBlock value: each)].
	^newCollection!

do: aBlock   
	"Evaluate aBlock with each of the receiver's elements as the argument."

	tally = 0 ifTrue: [^self].
	1 to: self basicSize do: 
		[:index | (self basicAt: index) do: aBlock].
	^ self!

select: aBlock 
	"Evaluate aBlock with each of the values of the receiver as the 
	argument.  Collect into a new dictionary, only those associations 
	for which aBlock evaluates to true. "

	| newCollection |
	newCollection _ self species new.
	self associationsDo: 
		[:each | (aBlock value: each value)
			ifTrue: [newCollection add: each]].
	^newCollection! !

!GreatDictionary methodsFor: 'converting'!

asSortedCollection
	"Answer a new instance of SortedCollection whose elements are the elements of
	the receiver.  The sort order is the default less than or equal ordering."

	| aSortedCollection |
	aSortedCollection _ SortedCollection new: self size.
	self associationsDo: [:association | aSortedCollection add: association].
	^aSortedCollection! !

!GreatDictionary methodsFor: 'printing'!

printOn: aStream  
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	| tooMany |
	tooMany _ aStream position + self maxPrint.
	aStream nextPutAll: self class name, ' ('.
	self associationsDo: 
		[:element | 
		aStream position > tooMany ifTrue: [aStream nextPutAll: '...etc...)'. ^self].
		element printOn: aStream.
		aStream space].
	aStream nextPut: $)!

storeOn: aStream 
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates an collection similar to the receiver. The general format
	for a Dictionary is
		((class-name new) at: key put: value; at: key put: value; ... ; yourself)"

	self isEmpty ifTrue: [^aStream nextPutAll: '(', self class name, ' new)'].
	aStream nextPutAll: '((', self class name, ' new: ',
							self basicSize printString, ')'.
	self associationsDo: 
			[:assoc | 
			aStream nextPutAll: ' at: '; store: assoc key; nextPutAll: ' put: '; store: assoc value; nextPut: $;].
	aStream nextPutAll: ' yourself)'
	"self associationsDo: 
			[:each | 
			noneYet
				ifTrue: [noneYet _ false]
				ifFalse: [aStream nextPut: $;].
			aStream nextPutAll: ' add: '.
			aStream store: each]."! !

!GreatDictionary methodsFor: 'dictionary testing'!

includesAssociation: anAssociation 
	"Answer whether the receiver has an element (association between a key and
	a value) that is equal to the argument, anAssociation."

	^super includes: anAssociation!

includesKey: key 
	"Answer whether the receiver has a key equal to the argument, key."

	^ (self fetchSub: key) includesKey: key! !

!GreatDictionary methodsFor: 'dictionary removing'!

removeAssociation: anAssociation 
	"Remove the key and value association, anAssociation, from the 
	receiver.  Answer anAssociation.  If the key is not in the receiver,
	then provide an error notification that it was not found."

	^self removeAssociation: anAssociation ifAbsent: [self notFoundError]!

removeAssociation: anAssociation ifAbsent: anExceptionBlock 
	"Remove the key and value association, anAssociation, from the 
	receiver.  If not found, answer the result of evaluating 
	anExceptionBlock, otherwise answer anAssociation."

	| subdict oldSize |
	oldSize _ (subdict _ self fetchSub: anAssociation key) size.
	subdict removeAssociation: anAssociation ifAbsent: anExceptionBlock.
	oldSize > subdict size ifTrue: [tally _ tally - 1].
	^ anAssociation!

removeKey: key 
	"Remove key from the receiver.  If key is not in the receiver, raise a signal.  Otherwise, answer the value associated with key."

	^self removeKey: key ifAbsent: [self keyNotFoundError: key]!

removeKey: key ifAbsent: aBlock 
	"Remove key from the receiver.  If key is not in the receiver, 
	answer the result of evaluating aBlock.  Otherwise, answer the value 
	associated with key."

	| sub oldSize oldVal |
	oldSize _ (sub _ self fetchSub: key) size.
	oldVal _ sub removeKey: key ifAbsent: aBlock.
	sub size < oldSize ifTrue: [tally _ tally - 1].
	^oldVal! !

!GreatDictionary methodsFor: 'dictionary enumerating'!

associationsDo: aBlock 
	"Evaluate aBlock for each of the receiver's key/value associations."

	tally = 0 ifTrue: [^self].
	self basicCollection do: [:subDict | 
		subDict associationsDo: aBlock]!

keysDo: aBlock 
	"Evaluate aBlock for each of the receiver's keys."

	self associationsDo: [:association | aBlock value: association key]! !

!GreatDictionary methodsFor: 'user interface'!

inspect
	"Create and schedule a DictionaryInspector in which the user can examine the
	receiver's variables."

	Cursor wait showWhile: [InspectorView open: (DictionaryInspector inspect: self)]! !

!GreatDictionary methodsFor: 'private: private'!

keyNotFoundError: key
	"Raise a signal indicating that the key was
	not found." 

	^Dictionary keyNotFoundSignal raiseWith: key!

noCheckAdd: anAssociation 
	"Assume that the association is in the receiver and add it
	without checking to make sure."

	(self fetchSub: anAssociation key) noCheckAdd: anAssociation.
	tally _ tally + 1!

rehash
	"Recompute the hash numbers for the elements of the receiver."

	"Smalltalk rehash."

	| newSelf |
	newSelf _ self species new: self basicSize.
	self associationsDo: [:each | newSelf noCheckAdd: each].
	self become: newSelf!

valueNotFoundError: value
	"Raise a signal indicating that the value was
	not found."

	^Dictionary valueNotFoundSignal raiseWith: value! !

!GreatDictionary methodsFor: 'fileIn/Out'!

storeBinaryOn: stream

	stream storeRecordOfClass: self class.
	stream nextPut: self size.
	self associationsDo: [:assoc | stream nextPut: assoc]! !

!GreatDictionary methodsFor: 'private: greatness'!

initialize

	1 to: self basicSize do: [:i | 
		self basicAt: i put: (Dictionary new: 128)]! !