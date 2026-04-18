'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:26 pm'!

Dictionary variableSubclass: #IdentityDictionary
	instanceVariableNames: 'valueArray '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Unordered'!
IdentityDictionary comment:
'The class IdentityDictionary is a subclass of Dictionary in which the lookup is done using == rather than =.   It is represented as two parallel ordered collections of keys and values, rather than as a single collection of associations.

Instance Variables: *indexed*
	valueArray		<Array of: Objects>	  of values stored in the dictionary'!


!IdentityDictionary methodsFor: 'accessing'!

associationAt: key ifAbsent: aBlock 
	"Answer an Association consisting of key and the value of
	the receiver at that key.  If key is not found, evaluate aBlock."

	| index |
	index _ self findKey: key ifAbsent: [^aBlock value].
	^Association 
		key: (self basicAt: index)
		value: (valueArray at: index)!

at: key ifAbsent: aBlock 
	"Answer the value at key.  If key is not found, evaluate aBlock."

	| index |
	index _ self findKey: key ifAbsent: [^aBlock value].
	^valueArray at: index!

at: key put: value
	"Set the value at key to be value."
 
	| index |
	index _ self findKeyOrNil: key.
	(self basicAt: index) == nil
		ifTrue: 
			[tally _ tally + 1.
			self basicAt: index put: key].
	valueArray at: index put: value.
	self fullCheck.
	^value!

keyAtValue: value ifAbsent: exceptionBlock
	"Answer the key whose value equals the argument, value.  If there is none, 
	answer the result of evaluating exceptionBlock."

	| theKey |
	1 to: self basicSize do:
		[:index |
		value == (valueArray at: index)
			ifTrue:
				[(theKey _ self basicAt: index) == nil
					ifFalse: [^theKey]]].
	^exceptionBlock value!

keys
	"Answer a set containing the receiver's keys."

	| aSet |
	aSet _ IdentitySet new: self size.
	self keysDo: [:key | aSet add: key].
	^aSet! !

!IdentityDictionary methodsFor: 'adding'!

add: anAssociation 
	"Include newObject as one of the receiver's elements.  Answer newObject."

	self at: anAssociation key put: anAssociation value! !

!IdentityDictionary methodsFor: 'copying'!

copy
	"Answer another instance just like the receiver."

	| v copy |
	v _ valueArray.
	valueArray _ valueArray shallowCopy.
	copy _ super shallowCopy.
	valueArray _ v.
	^copy! !

!IdentityDictionary methodsFor: 'enumerating'!

do: aBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument."

	1 to: self basicSize do: 
		[:index | 
		(self basicAt: index) == nil ifFalse: [aBlock value: (valueArray at: index)]]! !

!IdentityDictionary methodsFor: 'dictionary removing'!

removeKey: key ifAbsent: aBlock
	"Remove key from the receiver.  If key is not in the receiver, 
	answer the result of evaluating aBlock.  Otherwise, answer the value 
	associated with key."

	| value |
	value _ self at: key ifAbsent: [^aBlock value].
	self removeDangerouslyKey: key ifAbsent: [].
	^value! !

!IdentityDictionary methodsFor: 'dictionary enumerating'!

associationsDo: aBlock 
	"Evaluate aBlock for associations consisting of the receiver's keys and 
	their values."

	1 to: self basicSize do: 
		[:index | 
		(self basicAt: index) == nil 
			ifFalse: [aBlock value: (Association 
										key: (self basicAt: index)
										value: (valueArray at: index))]]!

keysDo: aBlock 
	"Evaluate aBlock for each of the receiver's keys."

	1 to: self basicSize do: 
		[:index | 
		(self basicAt: index) == nil 
			ifFalse: [aBlock value: (self basicAt: index)]]!

{void} keyValuesDo: aBlock {BlockClosure of: Object with: Object}
	"Evaluate aBlock for each of the receiver's key/value associations, unboxed."

	1 to: self basicSize do: 
		[:index | 
		(self basicAt: index) == nil 
			ifFalse: [aBlock 	
						value: (self basicAt: index)
						value: (valueArray at: index)]]! !

!IdentityDictionary methodsFor: 'private: private'!

findKeyOrNil: key  
	"Look for the key in the receiver.  If it is found, answer
	the index of the association containting the key, otherwise
	answer the index of the first unused slot."

	| index length probe pass |
	length _ self basicSize.
	pass _ 1.
	index _ key identityHash \\ length + 1.
	[(probe _ self basicAt: index) == nil or: [probe == key]]
		whileFalse: [(index _ index + 1) > length
				ifTrue: 
					[index _ 1.
					pass _ pass + 1.
					pass > 2 ifTrue: [^self grow findKeyOrNil: key]]].
	^index!

noCheckAdd: anAssociation 
	"Assume that the association is in the receiver and add it
	without checking to make sure."

	^self noCheckAdd: anAssociation key with: anAssociation value!

noCheckAdd: key with: value 
	"Assume that the key is already in the receiver and store the value
	without checking to make sure."

	| index |
	index _ self findKeyOrNil: key.
	self basicAt: index put: key.
	tally _ tally + 1.
	^valueArray at: index put: value!

removeAndCleanUpAtIndex: index
	"Remove the key at the given index,
	relocating any following entries as needed."

	| location oldKey length |
	self basicAt: index put: nil.
	valueArray at: index put: nil.
	tally _ tally - 1.
	length _ self basicSize.
	location _ index.
	[location _ 
		location = length
			ifTrue: [1]
			ifFalse: [location + 1].
	(self basicAt: location) == nil]
		whileFalse: 
			[oldKey _ self findKeyOrNil: (self basicAt: location).
			location = oldKey ifFalse: [self swap: location with: oldKey]]!

removeDangerouslyKey: key ifAbsent: errorBlock
	"Assume that the key is in the receiver and go fetch its value.
	If the value is nil, answer the result of evaluating the errorBlock.
	Otherwise, remove the key from the receiver."

	| location |
	location _ self findKeyOrNil: key.
	(self basicAt: location) == nil ifTrue: [^errorBlock value].
	self removeAndCleanUpAtIndex: location!

setTally
	"Initialize talley and other instance variables."

	super setTally.
	valueArray _ Array new: self basicSize!

swap: oneElement with: otherElement 
	"Store otherElement in the position for oneElement, and
	vice versa."

	super swap: oneElement with: otherElement.
	valueArray swap: oneElement with: otherElement! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IdentityDictionary class
	instanceVariableNames: ''!


!IdentityDictionary class methodsFor: 'instance creation'!

new: size 
	"Answer a new instance of IdentifyDictionary, whose initial capacity is size.
	Size is rounded up to a power of 2 if needed."

	size >= 1 ifFalse: [self error: 'size must be >= 1'].
	^super new: (1 bitShift: (size - 1) highBit)! !