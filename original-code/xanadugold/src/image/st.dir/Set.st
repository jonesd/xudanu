'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:27 pm'!

Collection variableSubclass: #Set
	instanceVariableNames: 'tally '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Unordered'!
Set comment:
'The class Set represents an unordered collection of elements that are not duplicated.

Instance Variables: *indexed*
	tally	<Integer>	a count of the number of elements in the Set'!


!Set methodsFor: 'accessing'!

at: anInteger
	"Provide an error notification that elements of a Set
	are not accessible by external keys."

	^self notKeyedError!

at: index put: anObject
	"Provide an error notification that elements of a Set can not be
	accessed by external keys."

	^self notKeyedError!

size
	"Answer how many elements the receiver contains."

	^tally! !

!Set methodsFor: 'testing'!

includes: anObject 
	"Answer whether anObject is one of the receiver's elements."

	^(self basicAt: (self findElementOrNil: anObject)) ~~ nil!

occurrencesOf: anObject 
	"Answer how many of the receiver's elements are equal to anObject."

	(self includes: anObject)
		ifTrue: [^1]
		ifFalse: [^0]! !

!Set methodsFor: 'adding'!

add: newObject 
	"Include newObject as one of the receiver's elements.  Answer newObject."

	| index |
	newObject == nil ifTrue: [^newObject].
	index _ self findElementOrNil: newObject.
	(self basicAt: index) == nil ifTrue: [self atNewIndex: index put: newObject].
	^newObject!

grow
	"The receiver becomes twice as large."

	"This is not a copy of the receiver, so all shared references survive."

	| newSelf |
	newSelf _ self copyEmpty: self basicSize + self growSize.
	self do: [:each | newSelf noCheckAdd: each].
	self become: newSelf! !

!Set methodsFor: 'cxx extensions'!

{BooleanVar} intersects: other {Set}
	"tell whether they have any points in common"

	"subclasses can override for efficiency"
	other isEmpty ifTrue: [ ^ false ].
	self count > other count
		ifTrue: [^other intersects: self].
	self do: [:mem {Object} |
		(other includes: mem) ifTrue: [^true]].
	^false!

{Set} unionWith: another {Set}
	
	| result {Set} |
	self size >= another size
		ifTrue: [result _ self copy.
				result addAll: another]
		ifFalse: [result _ another copy.
				result addAll: self].
	^result! !

!Set methodsFor: 'removing'!

- aSet
	"Answer those elements present in the receiver and absent from aSet."

	^self reject: [ :i | aSet includes: i ]!

remove: oldObject ifAbsent: anExceptionBlock   
	"Remove oldObject as one of the receiver's elements.  If several of the
	elements are equal to oldObject, only one is removed. If no element is equal to
	oldObject, answer the result of evaluating anExceptionBlock.  Otherwise,
	answer the argument, oldObject."

	| index |
	index _ self find: oldObject ifAbsent: [^anExceptionBlock value].
	self basicAt: index put: nil.
	tally _ tally - 1.
	self fixCollisionsFrom: index.
	^oldObject! !

!Set methodsFor: 'enumerating'!

collect: aBlock  
	"Evaluate aBlock with each of the values of the receiver as the  
	argument.  Collect the resulting values into a Set that is like 
	the receiver.  Answer the new Set."

	"Override the general method, so that we make a big enough set and avoid growing. "

	| newSet size index element |
	tally = 0 ifTrue: [^Set new: 2].
	newSet _ Set new: (size _ self basicSize).
	index _ 0.
	[(index _ index + 1) <= size] whileTrue:
		[(element _ self basicAt: index) == nil ifFalse:
			[newSet add: (aBlock value: element)]].
	^newSet!

do: aBlock   
	"Evaluate aBlock with each of the receiver's elements as the argument."

	tally = 0 ifTrue: [^self].
	1 to: self basicSize do: 
		[:index | 
		(self basicAt: index) == nil ifFalse: [aBlock value: (self basicAt: index)]]!

stepper
	^self asOrderedCollection stepper! !

!Set methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own copy of each instance variable."

	^super deepCopy rehash! !

!Set methodsFor: 'private: private'!

atNewIndex: index put: anObject 
	self basicAt: index put: anObject.
	tally _ tally + 1.
	self fullCheck!

find: anObject ifAbsent: aBlock 
	| index |
	index _ self findElementOrNil: anObject.
	(self basicAt: index) == nil
		ifTrue: [^aBlock value]
		ifFalse: [^index]!

findElementOrNil: anObject 
	"Answer the index of the argument anObject or answer nil."

	| index length probe pass |
	length _ self basicSize.
	pass _ 1.
	index _ anObject hash \\ length + 1.
	[(probe _ self basicAt: index) == nil or: [probe = anObject]]
		whileFalse: [(index _ index + 1) > length
				ifTrue: 
					[index _ 1.
					pass _ pass + 1.
					pass > 2 ifTrue: [^self grow findElementOrNil: anObject]]].
	^index!

fixCollisionsFrom: index 
	| myLength oldIndex nextIndex nextObject |
	oldIndex _ index.
	myLength _ self basicSize.
	[oldIndex _ oldIndex \\ myLength + 1.
	nextObject _ self basicAt: oldIndex.
	nextObject == nil]
		whileFalse: 
			[nextIndex _ self findElementOrNil: nextObject.
			nextIndex = oldIndex
				ifFalse: 
					[self basicAt: nextIndex put: nextObject.
					self basicAt: oldIndex put: nil]]!

fullCheck
	self basicSize - self size <= (self basicSize // 4) ifTrue: [self grow]!

growSize
	"Answer an amount by which the receiver should grow 
	to make room for more elements."

	^ (self basicSize * 2 - 1) max: 3.!

noCheckAdd: anObject 
	"Assume that the association is in the receiver and add it
	without checking to make sure."

	self basicAt: (self findElementOrNil: anObject)
		put: anObject.
	tally _ tally + 1!

rehash
	| newSelf |
	newSelf _ self species new: self basicSize.
	self do: [:each | newSelf noCheckAdd: each].
	self become: newSelf!

setTally
	"Initialize the number of elements to be 0."

	tally _ 0!

swap: oneElement with: otherElement 
	| save |
	save _ self basicAt: oneElement.
	self basicAt: oneElement put: (self basicAt: otherElement).
	self basicAt: otherElement put: save! !

!Set methodsFor: 'fileIn/Out'!

storeBinaryOn: stream

	stream storeRecordOfClass: self class.
	stream nextPut: self size.
	self do: [:value | stream nextPut: value]! !

!Set methodsFor: 'user interface'!

inspect
	"Create and schedule a SetInspector in which the user can examine the
	receiver's variables."

	Cursor wait showWhile: [InspectorView open: (SetInspector inspect: self)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Set class
	instanceVariableNames: ''!


!Set class methodsFor: 'instance creation'!

new
	"Create an instance of a Set."

	^self new: 2!

new: anInteger 
	"Create an instance of a Set."

	^(super new: (anInteger max: 1)) setTally! !

!Set class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag
	"Answer object appearing next in stream."

	| size set |
	size _ stream next.  "integer"
	set _ self new: (size max: 1).
	stream register: set id: tag.
	1 to: size do:
		[:i | set add: stream next].
	^set! !