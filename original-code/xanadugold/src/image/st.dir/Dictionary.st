'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:24 pm'!

Set variableSubclass: #Dictionary
	instanceVariableNames: ''
	classVariableNames: 'KeyNotFoundSignal ValueNotFoundSignal '
	poolDictionaries: ''
	category: 'Collections-Unordered'!
Dictionary comment:
'A Dictionary is a set of associations.

Several special kinds of Dictionaries exist in the system. They are
	IdentityDictionary		do lookup using == rather than =
	MethodDictionary		like IdentityDictionary except removal is implemented as an atomic operation
	LiteralDictionary 		check for equality and class of keys;  used by the compiler
	SystemDictionary		contains information about the system

Instance Variables: *indexed*

Class Variables:
	KeyNotFoundSignal		<Signal> Key not found
	ValueNotFoundSignal	<Signal> Value not found'!


!Dictionary methodsFor: 'accessing'!

associationAt: key 
	"Answer the association at key.  If key is not found, raise a signal."

	^self associationAt: key ifAbsent: [self keyNotFoundError: key]!

associationAt: key ifAbsent: aBlock 
	"Answer the association at key.  If key is not found, answer the
	result of evaluating aBlock."

	| index |
	index _ self findKey: key ifAbsent: [^aBlock value].
	^self basicAt: index!

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

	| index |
	index _ self findKey: key ifAbsent: [^aBlock value].
	^(self basicAt: index) value!

at: key ifAbsentRaise: aSignal
	"Answer the value at key.  If key is not found,
	raise aSignal with key as the parameter."

	| index |
	index _ self findKey: key ifAbsentRaise: aSignal.
	^(self basicAt: index) value!

at: key put: anObject 
	"Set the value at key to be anObject.  If key is not found, create a new
	entry for key and set is value to anObject. Answer anObject."

	| index element |
	index _ self findKeyOrNil: key.
	element _ self basicAt: index.
	element == nil
		ifTrue: [self atNewIndex: index put: (Association key: key value: anObject)]
		ifFalse: [element value: anObject].
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

!Dictionary methodsFor: 'testing'!

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

!Dictionary methodsFor: 'adding'!

add: anAssociation 
	"Include newObject as one of the receiver's elements.  Answer newObject."

	| index element |
	index _ self findKeyOrNil: anAssociation key.
	element _ self basicAt: index.
	element == nil
		ifTrue: [self atNewIndex: index put: anAssociation]
		ifFalse: [element value: anAssociation value].
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
	self basicSize > 10000 
		ifTrue: [newSelf _ IdentityGreatDictionary newForSize: self basicSize + self growSize]
		ifFalse: [newSelf _ self copyEmpty: self basicSize + self growSize].
	self associationsDo: [:each | newSelf noCheckAdd: each].
	self become: newSelf! !

!Dictionary methodsFor: 'removing'!

remove: anObject 
	"Provide an error notification that removing an element
	 from a Dictionary is not allowed."

	self shouldNotImplement!

remove: anObject ifAbsent: exceptionBlock 
	"Provide an error notification that Dictionaries can not respond to
	remove: messages."

	self shouldNotImplement! !

!Dictionary methodsFor: 'enumerating'!

collect: aBlock 
	"Evaluate aBlock with each of the values of the receiver as the  
	argument.  Collect the resulting values into a collection that is like 
	the receiver.  Answer the new collection."

	| newCollection |
	newCollection _ Bag new.
	self do: [:each | newCollection add: (aBlock value: each)].
	^newCollection!

do: aBlock 
	"Evaluate aBlock with each of the receiver's elements as the 
	argument. "

	super do: [:assoc | aBlock value: assoc value]!

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

!Dictionary methodsFor: 'converting'!

asSortedCollection
	"Answer a new instance of SortedCollection whose elements are the elements of
	the receiver.  The sort order is the default less than or equal ordering."

	| aSortedCollection |
	aSortedCollection _ SortedCollection new: self size.
	self associationsDo: [:association | aSortedCollection add: association].
	^aSortedCollection! !

!Dictionary methodsFor: 'printing'!

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
	aStream nextPutAll: '((', self class name, ' new)'.
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

!Dictionary methodsFor: 'dictionary testing'!

includesAssociation: anAssociation 
	"Answer whether the receiver has an element (association between a key and
	a value) that is equal to the argument, anAssociation."

	^super includes: anAssociation!

includesKey: key 
	"Answer whether the receiver has a key equal to the argument, key."

	| index |
	index _ self findKeyOrNil: key.
	^(self basicAt: index) ~~ nil! !

!Dictionary methodsFor: 'dictionary removing'!

removeAssociation: anAssociation 
	"Remove the key and value association, anAssociation, from the 
	receiver.  Answer anAssociation.  If the key is not in the receiver,
	then provide an error notification that it was not found."

	^self removeAssociation: anAssociation ifAbsent: [self notFoundError]!

removeAssociation: anAssociation ifAbsent: anExceptionBlock 
	"Remove the key and value association, anAssociation, from the 
	receiver.  If not found, answer the result of evaluating 
	anExceptionBlock, otherwise answer anAssociation."

	^super remove: anAssociation ifAbsent: anExceptionBlock!

removeKey: key 
	"Remove key from the receiver.  If key is not in the receiver, raise a signal.  Otherwise, answer the value associated with key."

	^self removeKey: key ifAbsent: [self keyNotFoundError: key]!

removeKey: key ifAbsent: aBlock 
	"Remove key from the receiver.  If key is not in the receiver, 
	answer the result of evaluating aBlock.  Otherwise, answer the value 
	associated with key."

	| index element |
	index _ self findKey: key ifAbsent: [^aBlock value].
	element _ self basicAt: index.
	self basicAt: index put: nil.
	tally _ tally - 1.
	self fixCollisionsFrom: index.
	^element value! !

!Dictionary methodsFor: 'dictionary enumerating'!

associationsDo: aBlock 
	"Evaluate aBlock for each of the receiver's key/value associations."

	super do: aBlock!

keysDo: aBlock 
	"Evaluate aBlock for each of the receiver's keys."

	self associationsDo: [:association | aBlock value: association key]!

{void} keyValuesDo: aBlock {BlockClosure of: Object with: Object}
	"Evaluate aBlock for each of the receiver's key/value associations, unboxed."

	self associationsDo: [:assoc {Association} |
		aBlock value: assoc key value: assoc value]! !

!Dictionary methodsFor: 'user interface'!

inspect
	"Create and schedule a DictionaryInspector in which the user can examine the
	receiver's variables."

	Cursor wait showWhile: [InspectorView open: (DictionaryInspector inspect: self)]! !

!Dictionary methodsFor: 'private: private'!

findKey: key ifAbsent: aBlock 
	"Look for the key in the receiver.  If it is found, answer
	the index of the association containing the key, otherwise
	answer the result of evaluating aBlock."
	
	| index |
	index _ self findKeyOrNil: key.
	(self basicAt: index) == nil ifTrue: [^aBlock value].
	^index!

findKey: key ifAbsentRaise: aSignal
	"Look for the key in the receiver.  If it is found, answer
	the index of the association containing the key, otherwise
	raise aSignal with key as the parameter."
	
	| index |
	index _ self findKeyOrNil: key.
	(self basicAt: index) == nil ifTrue: [aSignal raiseWith: key  "doesn't return"].
	^index!

findKeyOrNil: key  
	"Look for the key in the receiver.  If it is found, answer
	the index of the association containing the key, otherwise
	answer the index of the first unused slot."

	| location length probe pass |
	length _ self basicSize.
	pass _ 1.
	location _ key hash \\ length + 1.
	[(probe _ self basicAt: location) == nil or: [probe key = key]]
		whileFalse: 
			[(location _ location + 1) > length
				ifTrue: 
					[location _ 1.
					pass _ pass + 1.
					pass > 2 ifTrue: [^self grow findKeyOrNil: key]]].
	^location!

keyNotFoundError: key
	"Raise a signal indicating that the key was
	not found."

	^Dictionary keyNotFoundSignal raiseWith: key!

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

!Dictionary methodsFor: 'fileIn/Out'!

storeBinaryOn: stream

	stream storeRecordOfClass: self class.
	stream nextPut: self size.
	self associationsDo: [:assoc | stream nextPut: assoc]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Dictionary class
	instanceVariableNames: ''!


!Dictionary class methodsFor: 'class initialization'!

initialize
	"Initialize signals."

	| nfs |
	nfs _ Object notFoundSignal.
	KeyNotFoundSignal _ nfs newSignal 
		notifierString: 'Key not found: ';
		nameClass: self message: #keyNotFoundSignal.
	ValueNotFoundSignal _ nfs newSignal 
		notifierString: 'Value not found: ';
		nameClass: self message: #valueNotFoundSignal.! !

!Dictionary class methodsFor: 'Signal constants'!

keyNotFoundSignal

	^KeyNotFoundSignal!

valueNotFoundSignal

	^ValueNotFoundSignal! !

!Dictionary class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag
	"Answer object appearing next in stream."

	| size dict |
	size _ stream next.  "integer"
	dict _ self new: (size max: 1).
	stream register: dict id: tag.
	1 to: size do:
		[:i | dict add: stream next].
	^dict! !

!Dictionary class methodsFor: 'creation'!

fromPairs: array
	"Make a dictionary from and array of 2 element arrays.  This is very useful for generating Dictionaries from literal arrays."
	
	| result |
	result _ self new: array count * 2.
	array do: [:pair | result at: (pair at: 1) put: (pair at: 2)].
	^result! !

Dictionary initialize!
