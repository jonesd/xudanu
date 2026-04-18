'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:22 pm'!

Collection subclass: #SequenceableCollection
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Abstract'!
SequenceableCollection comment:
'Abstract superclass for collections that have a well-defined order associated with their elements.  All SequenceableCollections are accessible through keys that are integer indices.  Subclasses are distinguished by how the ordering is created and whether or not the elements are restricted kinds of objects.  

Subclasses are 

  ordered determined externally
	OrderedCollection   elements ordered by user adding and removing 
	LinkedList			uses a chain of elements that must be links
	ArrayedCollection	elements accessible by integers as external keys.

  ordered determined internally
	Interval				elements must be numbers

Concrete subclasses must implement methods for 
	adding
		add:
	accessing
		size

Subclasses should not implement methods for
	removing
		remove: ifAbsent:'!


!SequenceableCollection methodsFor: 'comparing'!

= otherCollection 
	"Answer whether the species of the receiver is the same as otherCollection's species,
	and the receiver's size is the same as otherCollection's size, and each of the receiver's
	elements equal the corresponding element of otherCollection."

	| size index |
	(size _ self size) = otherCollection size ifFalse: [^false].
	self species == otherCollection species ifFalse: [^false].
	index _ 0.
	[(index _ index + 1) <= size]
		whileTrue: [(self at: index) = (otherCollection at: index) ifFalse: [^false]].
	^true!

hash
	"Answer a SmallInteger unique to the receiver."

	self size = 0 ifTrue: [^17171].
	^(self at: 1) hash + (self at: self size) hash! !

!SequenceableCollection methodsFor: 'accessing'!

atAll: anInterval put: anObject 
	"Put anObject at every index specified by the integer elements of anInterval."

	anInterval do: [:index | self at: index put: anObject]!

atAllPut: anObject 
	"Put anObject at every one of the receiver's indices."

	| index size |
	index _ 0.
	size _ self size.
	[(index _ index + 1) <= size]
		whileTrue: [self at: index put: anObject]!

first
	"Answer the first element of the receiver.  Provide an error 
	notification if the receiver contains no elements."

	self emptyCheck.
	^self at: 1!

identityIndexOf: anElement 
	"Answer the identity index of anElement within the receiver.  If the receiver does
	not contain anElement, answer 0."

	^self identityIndexOf: anElement ifAbsent: [0]!

identityIndexOf: anElement ifAbsent: exceptionBlock 
	"Answer the identity index of anElement within the receiver.  If the receiver does
	not contain anElement, answer the result of evaluating the exceptionBlock."

	1 to: self size
		do: [:i | (self at: i) == anElement ifTrue: [^i]].
	^exceptionBlock value!

indexOf: anElement 
	"Answer the index of anElement within the receiver.  If the receiver does
	not contain anElement, answer 0."

	^self indexOf: anElement ifAbsent: [0]!

indexOf: anElement ifAbsent: exceptionBlock 
	"Answer the index of anElement within the receiver.  If the receiver does
	not contain anElement, answer the result of evaluating the exceptionBlock."

	1 to: self size
		do: [:i | (self at: i) = anElement ifTrue: [^i]].
	^exceptionBlock value!

indexOfSubCollection: aSubCollection startingAt: anIndex
	"Answer the index of the receiver's first element, such that that 
	element equals the first element of aSubCollection, and the next 
	elements equal the rest of the elements of aSubCollection.  Begin the 
	search at element anIndex of the receiver.  If no such match is 
	found, answer 0."

	| subSize firstElement index matchIndex len|
	subSize _ aSubCollection size.
	subSize = 0 ifTrue: [^0].
	firstElement _ aSubCollection at: 1.
	subSize = 1
		ifTrue: [index _ anIndex.
				len _ self size.
				[index <= len] whileTrue:
					[(self at: index) = firstElement
						ifTrue: [^index].
					index _ index + 1].
				^0].
	matchIndex _ anIndex.
	len _ self size - subSize + 1.
	[matchIndex <= len] whileTrue:
		[(self at: matchIndex) = firstElement
			ifTrue:
				[index _ 2.
				[(self at: matchIndex + index - 1) = (aSubCollection at: index)]
					whileTrue:
						[index = subSize ifTrue: [^matchIndex].
						index _ index + 1]].
		matchIndex _ matchIndex + 1].
	^0!

indexOfSubCollection: aSubCollection startingAt: anIndex ifAbsent: exceptionBlock 
	"Answer the index of the receiver's first element, such that that 
	element equals the first element of aSubCollection, and the next 
	elements equal the rest of the elements of aSubCollection.  Begin the 
	search at element anIndex of the receiver.  If no such match is found, 
	answer the result of evaluating exceptionBlock."

	| matchIndex |
	matchIndex _ self indexOfSubCollection: aSubCollection startingAt: anIndex.
	^matchIndex = 0
		ifTrue: [exceptionBlock value]
		ifFalse: [matchIndex]!

last
	"Answer the last element of the receiver.  Provide an error 
	notification if the receiver contains no elements."

	self emptyCheck.
	^self at: self size!

nextIndexOf: anElement from: startIndex to: stopIndex
	"Answer the next index of anElement within the receiver between startIndex and stopIndex.
	 If the receiver does not contain anElement, answer nil"

	startIndex to: stopIndex do:
		[:i |
		(self at: i) = anElement
			ifTrue: [^i]].
	^nil!

prevIndexOf: anElement from: startIndex to: stopIndex
	"Answer the previous index of anElement within the receiver between startIndex and stopIndex
	 working backwards through the receiver.  If the receiver does not contain anElement, answer nil"

	startIndex to: stopIndex by: -1 do:
		[:i |
		(self at: i) = anElement
			ifTrue: [^i]].
	^nil!

replaceAll: sourceElement with: destElement
	"Replace all occurances of sourceElement with destElement within the receiver"

	^self replaceAll: sourceElement with: destElement from: 1 to: self size!

replaceAll: sourceElement with: destElement from: startIndex to: stopIndex
	"Replace all occurances of sourceElement with destElement within the
	given range."

	| index |
	index _ startIndex -1 .
	[(index _ self
			nextIndexOf: sourceElement
			from: index + 1
			to: stopIndex) == nil] whileFalse:
		[self at: index put: destElement]!

replaceFrom: start to: stop with: replacement 
	"This destructively replaces elements from start to stop in the receiver.  
	Answer the receiver itself. Use copyReplaceFrom:to:with: for 
	insertion/deletion which may alter the size of the result."

	replacement size = (stop - start + 1)
		ifFalse: [self error: 'Size of replacement doesn''t match'].
	^self replaceFrom: start to: stop with: replacement startingAt: 1!

replaceFrom: start to: stop with: replacement startingAt: repStart 
	"This destructively replaces elements from start to stop in the 
	receiver starting at index, repStart, in the collection, replacement. 
	Answer the receiver. No range checks are performed, but 
	overlapping replacements are handled correctly."

	| repOff |
	repOff _ repStart - start.
	(self == replacement and: [repStart < start])
		ifTrue: ["Replacement would be overwritten, copy in reverse order."
				stop to: start by: -1
					do: [:index | self at: index put: (replacement at: repOff + index)]]
		ifFalse: [start to: stop
					do: [:index | self at: index put: (replacement at: repOff + index)]]!

size
	"Answer how many elements the receiver contains."

	self subclassResponsibility! !

!SequenceableCollection methodsFor: 'testing'!

isSequenceable
	"Answers true."

	^true!

occurrencesOf: anObject 
	"Answer how many of the receiver's elements are equal to anObject."

	| tally len |
	tally _ 0.
	1 to: self size do:
		[ :index |
		anObject = (self at: index) ifTrue: [tally _ tally + 1]].
	^tally! !

!SequenceableCollection methodsFor: 'adding'!

grow
	"The receiver becomes larger."
	
	"This is not a copy of the receiver, so all shared references survive."

	| newArray |
	newArray _ self copyEmpty: self size + self growSize.
	newArray
		replaceFrom: 1
		to: self size
		with: self.
	self become: newArray!

growToAtLeast: anInteger
	"The receiver becomes at least as large as anInteger."
	
	"This is not a copy of the receiver, so all shared references survive."

	| newArray |
	anInteger <= self size
		ifTrue: [^self].
	newArray _ self copyEmpty: anInteger + self growSize.
	newArray
		replaceFrom: 1
		to: self size
		with: self.
	self become: newArray! !

!SequenceableCollection methodsFor: 'removing'!

remove: oldObject ifAbsent: anExceptionBlock 
	"Provide an error notification that SequencableCollections cannot 
	implement removing."

	self shouldNotImplement! !

!SequenceableCollection methodsFor: 'copying'!

, aSequenceableCollection 
	"Answer a copy of the receiver concatenated with the argument,
	a SequencableCollection."
	
	^self copyReplaceFrom: self size + 1
		  to: self size
		  with: aSequenceableCollection!

copyFrom: start
	"Anser a copy of the receiver, starting from start and going till the end."

	^self copyFrom: start to: self size!

copyFrom: start to: stop 
	"Answer a copy of a subset of the receiver, starting from element at index start 
	until element at index stop."

	| newSize |
	newSize _ stop - start + 1.
	^(self species new: newSize)
		replaceFrom: 1
		to: newSize
		with: self
		startingAt: start!

copyReplaceAll: oldSubCollection with: newSubCollection 
	"Answer a copy of the receiver in which all occurrences of 
	oldSubCollection have been replaced by newSubCollection.  If there 
	are no such occurrences, answer the receiver."

	| startSearch matchIndex matchIndices newCollection oldIndex newIndex newPlace |
	"If there are no matches, answer the receiver."
	(matchIndex _ self indexOfSubCollection: oldSubCollection startingAt: 1) > 0 ifFalse: [^self].
	matchIndices _ OrderedCollection with: matchIndex.
	[(matchIndex _ self indexOfSubCollection: oldSubCollection startingAt: matchIndex + oldSubCollection size) > 0]
		whileTrue: [matchIndices addLast: matchIndex].
	"Copy the collection, replacing all the occurrences."
	newCollection _ self species new: self size + ((newSubCollection size - oldSubCollection size) * matchIndices size).
	oldIndex _ 1.
	newIndex _ 1.
	[matchIndices isEmpty]
		whileFalse: 
			[matchIndex _ matchIndices removeFirst.
			"Copy the subcollection up to the match."
			newPlace _ newIndex + matchIndex - oldIndex.
			newCollection
				replaceFrom: newIndex
				to: newPlace - 1
				with: self
				startingAt: oldIndex.
			oldIndex _ matchIndex + oldSubCollection size.
			"Insert the new subcollection."
			newIndex _ newPlace + newSubCollection size.
			newCollection
				replaceFrom: newPlace
				to: newIndex - 1
				with: newSubCollection
				startingAt: 1].
	"Copy the collection beyond the last match."
	newCollection
		replaceFrom: newIndex
		to: newCollection size
		with: self
		startingAt: oldIndex.
	^newCollection

	"'How noww brown cowow?' copyReplaceAll: 'ow' with: 'ello'"!

copyReplaceAt: index with: newElement 
	"Make a copy just replacing a single element."
	| result |
	result _ self copy.
	result at: index put: newElement.
	^result!

copyReplaceFrom: start to: stop with: replacementCollection 
	"Answer a copy of the receiver satisfying the following conditions:

	If stop is less than start, then this is an insertion;  
		stop should be exactly start-1,  
		start = 1 means insert before the first character,  
		start = size+1 means append after last character.  
	Otherwise, this is a replacement;  
		start and stop have to be within the receiver's bounds."

	| newSequenceableCollection newSize endReplacement |
	newSize _ self size - (stop - start + 1) + replacementCollection size.
	endReplacement _ start - 1 + replacementCollection size.
	newSequenceableCollection _ self species new: newSize.
	newSequenceableCollection
		replaceFrom: 1
		to: start - 1
		with: self
		startingAt: 1.
	newSequenceableCollection
		replaceFrom: start
		to: endReplacement
		with: replacementCollection
		startingAt: 1.
	newSequenceableCollection
		replaceFrom: endReplacement + 1
		to: newSize
		with: self
		startingAt: stop + 1.
	^newSequenceableCollection!

copyWith: newElement 
	"Answer a copy of the receiver that is 1 bigger than the receiver and has 
	newElement at the last element."

	| newIC |
	newIC _ self species new: self size + 1.
	newIC 
		replaceFrom: 1
		to: self size
		with: self
		startingAt: 1.
	newIC at: newIC size put: newElement.
	^newIC!

copyWithout: oldElement 
	"Answer a copy of the receiver in which all occurrences of oldElement
	have been left out."

	| aStream |
	aStream _ WriteStream on: (self species new: self size).
	self do: [:each | oldElement = each ifFalse: [aStream nextPut: each]].
	^aStream contents! !

!SequenceableCollection methodsFor: 'enumerating'!

collect: aBlock 
	"Evaluate aBlock with each of the values of the receiver as the  
	argument.  Collect the resulting values into a collection that is like 
	the receiver.  Answer the new collection."

	| aStream index length |
	aStream _ WriteStream on: (self species new: self size).
	index _ 0.
	length _ self size.
	[(index _ index + 1) <= length]
		whileTrue: [aStream nextPut: (aBlock value: (self at: index))].
	^aStream contents!

do: aBlock  
	"Evaluate aBlock with each of the receiver's elements as the argument."

	| index length |
	index _ 0.
	length _ self size.
	[(index _ index + 1) <= length]
		whileTrue: [aBlock value: (self at: index)]!

do: aBlock andBetweenDo: betweenBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument."

	| index length |
	index _ 0.
	length _ self size.
	[(index _ index + 1) <= length]
		whileTrue: 
			[aBlock value: (self at: index).
			index = length ifFalse: [betweenBlock value]]!

findFirst: aBlock
	"Answer the index of the first element of the receiver
	for which aBlock evaluates as true."

	| index |
	index _ 0.
	[(index _ index + 1) <= self size] whileTrue:
		[(aBlock value: (self at: index)) ifTrue: [^index]].
	^ 0!

findLast: aBlock
	"Answer the index of the last element of the receiver
	for which aBlock evaluates as true."

	| index |
	index _ self size + 1.
	[(index _ index - 1) >= 1] whileTrue:
		[(aBlock value: (self at: index)) ifTrue: [^index]].
	^ 0!

reverse
	"Answer with a new sequenceable collection with its elements in the 
	opposite order."

	| aStream index |
	aStream _ WriteStream on: (self species new: self size).
	index _ self size + 1.
	[(index _ index - 1) > 0]
		whileTrue: [aStream nextPut: (self at: index)].
	^aStream contents!

reverseDo: aBlock
	"Evaluate aBlock with each of the receiver's elements as the argument, starting
	with the last element and taking each in sequence up to the first.  For
	SequenceableCollections, this is the reverse of the enumeration in do:."

	self size to: 1 by: -1 do: [:index | aBlock value: (self at: index)]!

select: aBlock  
	"Evaluate aBlock with each of the receiver's elements as the argument. 
	Collect into a new sequenceable collection only those elements for which
	aBlock evaluates to true.  Answer the new collection."

	| aStream index length |
	aStream _ WriteStream on: (self species new: self size).
	index _ 0.
	length _ self size.
	[(index _ index + 1) <= length]
		whileTrue: 
			[(aBlock value: (self at: index)) ifTrue: [aStream nextPut: (self at: index)]].
	^aStream contents!

stepper
	^ SequenceableCollectionStepper make: self!

with: aSequenceableCollection do: aBlock 
	"Evaluate aBlock with each of the receiver's elements along with the corresponding
	element from aSequencableCollection."

	| otherCollection |
	self size ~= aSequenceableCollection size ifTrue: [^self noMatchError].
	otherCollection _ ReadStream on: aSequenceableCollection.
	self do: [:each | aBlock value: each value: otherCollection next]! !

!SequenceableCollection methodsFor: 'converting'!

asArray
	"Answer a new instance of Array whose elements are the elements of
	the receiver, in the same order."

	| newArray |
	newArray _ Array new: self size.
	1 to: self size do: [:index | newArray at: index put: (self at: index)].
	^newArray!

mappedBy: aSequenceableCollection 
	"Answer a new instance of MappedCollection whose contents is the
	receiver and whose map is the argument, aSequencableCollection."

	^(MappedCollection collection: self map: aSequenceableCollection) contents!

readStream
	"Answer a readStream on the receiver.  Subclasses can provide their own kinds of Stream here."

	^ReadStream on: self!

writeStream
	"Answer a writeStream on the receiver.  Subclasses can provide their own kinds of Stream here."

	^WriteStream on: self! !

!SequenceableCollection methodsFor: 'private: private'!

errorOutOfBounds
	"Provide an error notification that an attempt was made to 
	access a position that is out of the bounds of the receiver."

	self error: 'indices are out of bounds'!

swap: oneIndex with: anotherIndex 
	"Move the element at oneIndex to anotherIndex, and vice-versa."

	| element |
	element _ self at: oneIndex.
	self at: oneIndex put: (self at: anotherIndex).
	self at: anotherIndex put: element! !