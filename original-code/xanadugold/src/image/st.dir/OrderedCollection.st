'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:29 pm'!

SequenceableCollection variableSubclass: #OrderedCollection
	instanceVariableNames: 'firstIndex lastIndex '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Sequenceable'!
OrderedCollection comment:
'Class OrderedCollection represents a collection of elements explicitly ordered by the sequence in which objects are added and removed.  Elements are accessible by external keys that are indices.  OrderedCollections can act as stacks or queues.  A stack is a sequential list for which all additions and deletions are made at one end of the list;  a queue is a sequential list for which all additions are made at one end, but all deletions are made from the other end.

Instance Variables: *indexed*
	firstIndex	<Integer>	external key referring to the first element of the collection
	lastIndex	<Integer>	external key referring to the last element of the collection'!


!OrderedCollection methodsFor: 'accessing'!

after: oldObject 
	"Answer the element after oldObject.  If the receiver does not contain 
	oldObject or if the receiver contains no elements after oldObject, 
	provide an error notification."

	| index |
	index _ self find: oldObject.
	index = lastIndex
		ifTrue: [^self lastObjectError]
		ifFalse: [^self basicAt: index + 1]!

at: anInteger 
	"Answer the element at index anInteger.
	at: is used by a knowledgeable client to access an existing element"

	anInteger isInteger ifFalse: [^self nonIntegerIndexError: anInteger].
	(anInteger < 1 or: [anInteger + firstIndex - 1 > lastIndex])
		ifTrue: [^self subscriptBoundsError: anInteger]
		ifFalse: [^super at: anInteger + firstIndex - 1]!

at: anInteger put: anObject 
	"Put anObject at element index anInteger.  
	at:put: can not be used to append, front or back, to an ordered  
	collection;  it is used by a knowledgeable client to replace an 
	element."

	anInteger isInteger ifFalse: [^self nonIntegerIndexError: anInteger].
	(anInteger < 1 or: [anInteger + firstIndex - 1 > lastIndex])
		ifTrue: [^self subscriptBoundsError: anInteger]
		ifFalse: [^super at: anInteger + firstIndex - 1 put: anObject]!

before: oldObject 
	"Answer the element before oldObject.  If the receiver does not  
	contain oldObject or if the receiver contains no elements before 
	oldObject, provide an error notification."

	| index |
	index _ self find: oldObject.
	index = firstIndex
		ifTrue: [^self firstObjectError]
		ifFalse: [^self basicAt: index - 1]!

first
	"Answer the first element.  If the receiver is empty, provide an error 
	notification."

	"This is a little faster than the implementation in the superclass."

	self emptyCheck.
	^self basicAt: firstIndex!

last
	"Answer the last element.  If the receiver is empty, create an error notification."

	"This is a little faster than the implementation in the superclass"

	self emptyCheck.
	^self basicAt: lastIndex!

size
	"Answer how many elements the receiver contains."

	^lastIndex - firstIndex + 1! !

!OrderedCollection methodsFor: 'copying'!

copyEmpty
	"Answer a copy of the receiver that contains no elements."

	^self copyEmpty: 10!

copyFrom: startIndex to: endIndex 
	"Answer a copy of the receiver that contains elements from 
	position startIndex to endIndex."

	| targetCollection |
	endIndex < startIndex ifTrue: [^self copyEmpty].
	(startIndex < 1 or: [endIndex > self size])
		ifTrue: [^self notFoundError].
	targetCollection _ self copyEmpty: endIndex-startIndex+1.
	startIndex + firstIndex - 1 to: endIndex + firstIndex - 1
		do: [:index | targetCollection add: (self basicAt: index)].
	^targetCollection!

copyReplaceFrom: start to: stop with: replacementCollection 
	"Answer a copy of the receiver with replacementCollection's elements
	in place of the receiver's start'th to stop'th elements.
	This does not expect a 1-1 map from replacementCollection to the 
	start to stop elements, so it will do an insert or append."

	| newOrderedCollection delta startIndex stopIndex |
	"if start is less than 1, ignore stop and assume this is inserting at the front. 
	if start greater than self size, ignore stop and assume this is appending. 
	otherwise, it is replacing part of me and start and stop have to be within my 
	bounds. "
	delta _ 0.
	startIndex _ start.
	stopIndex _ stop.
	start < 1
		ifTrue: [startIndex _ stopIndex _ 0]
		ifFalse: [startIndex > self size
				ifTrue: [startIndex _ stopIndex _ self size + 1]
				ifFalse: 
					[(stopIndex < (startIndex - 1) or: [stopIndex > self size])
						ifTrue: [self errorOutOfBounds].
					delta _ stopIndex - startIndex + 1]].
	newOrderedCollection _ 
		self copyEmpty: self size + replacementCollection size - delta.
	1 to: startIndex - 1 do: [:index | newOrderedCollection add: (self at: index)].
	1 to: replacementCollection size do: 
		[:index | newOrderedCollection add: (replacementCollection at: index)].
	stopIndex + 1 to: self size do: [:index | newOrderedCollection add: (self at: index)].
	^newOrderedCollection!

copyWith: newElement 
	"Answer a copy of the receiver that is 1 bigger than the receiver and 
	includes the argument, newElement, at the end."

	| newCollection |
	newCollection _ self copy.
	newCollection add: newElement.
	^newCollection!

copyWithout: oldElement 
	"Answer a copy of the receiver that does not contain any elements equal
	to oldElement."

	| newCollection |
	newCollection _ self copyEmpty: self size.
	self do: [:each | oldElement = each ifFalse: [newCollection add: each]].
	^newCollection! !

!OrderedCollection methodsFor: 'adding'!

add: newObject 
	"Include newObject as one of the receiver's elements.  Answer newObject."

	^self addLast: newObject!

add: newObject after: oldObject 
	"Add the argument, newObject, as an element of the receiver.  Put it
	in the position just succeeding oldObject.  Answer newObject."
	
	| index |
	index _ self find: oldObject.
	self insert: newObject before: index + 1.
	^newObject!

add: newObject before: oldObject 
	"Add the argument, newObject, as an element of the receiver.  Put it
	in the position just preceding oldObject.  Answer newObject."
	
	| index |
	index _ self find: oldObject.
	self insert: newObject before: index.
	^newObject!

add: anObject beforeIndex: spot 
	"Add the argument, newObject, as an element of the receiver.  Put it
	in the position just preceding the indexed position spot.  Answer newObject."

	self insert: anObject before: spot + firstIndex - 1!

addAll: anOrderedCollection 
	"Add each element of anOrderedCollection at my end.  Answer 
	anOrderedCollection. "

	^self addAllLast: anOrderedCollection!

addAllFirst: anOrderedCollection 
	"Add each element of anOrderedCollection at the beginning of the receiver.	
	Answer anOrderedCollection."

	anOrderedCollection reverseDo: [:each | self addFirst: each].
	^anOrderedCollection!

addAllLast: anOrderedCollection 
	"Add each element of anOrderedCollection at the end of the receiver.  Answer
	anOrderedCollection."

	anOrderedCollection do: [:each | self addLast: each].
	^anOrderedCollection!

addFirst: newObject 
	"Add newObject to the beginning of the receiver.  Add newObject."

	firstIndex = 1 ifTrue: [self makeRoomAtFirst].
	firstIndex _ firstIndex - 1.
	self basicAt: firstIndex put: newObject.
	^newObject!

addLast: newObject 
	"Add newObject to the end of the receiver.  Answer newObject."

	lastIndex = self basicSize ifTrue: [self makeRoomAtLast].
	lastIndex _ lastIndex + 1.
	self basicAt: lastIndex put: newObject.
	^newObject!

grow
	"Increase the number of elements of the collection."

	| newSelf |
	newSelf _ self copyEmpty: self size + self growSize.
	newSelf setIndicesFrom: self growSize // 2 + 1.
	firstIndex to: lastIndex do:
		[ :index |	newSelf addLastNoCheck: (self basicAt: index)].
	self become: newSelf! !

!OrderedCollection methodsFor: 'removing'!

remove: oldObject ifAbsent: anExceptionBlock  
	"Remove oldObject as one of the receiver's elements.  If several of the
	elements are equal to oldObject, only one is removed. If no element is equal to
	oldObject, answer the result of evaluating anExceptionBlock.  Otherwise,
	answer the argument, oldObject."

	| index |
	index _ firstIndex.
	[index <= lastIndex]
		whileTrue: 
			[oldObject = (self basicAt: index)
				ifTrue: 
					[self removeIndex: index.
					^oldObject]
				ifFalse: [index _ index + 1]].
	^anExceptionBlock value!

removeAllSuchThat: aBlock 
	"Evaluate aBlock for each element of the receiver.  Remove each element for
	which aBlock evaluates to true.  "

	| element newCollection index |
	newCollection _ self copyEmpty.
	index _ firstIndex.
	[index <= lastIndex]
		whileTrue:
			[element _ self basicAt: index.
			(aBlock value: element)
				ifTrue: 
					[newCollection add: element.
					self removeIndex: index]
				ifFalse:
					[index _ index + 1]].
	^newCollection!

removeAtIndex: anIndex
	"Remove the element of the collection at position anIndex.  Answer the object removed."

	| obj |
	obj _ self at: anIndex.
	self removeIndex: anIndex + firstIndex - 1.
	^obj!

removeFirst
	"Remove the first element of the receiver.  If the receiver is empty, 
	provide an error notification."

	| firstObject |
	self emptyCheck.
	firstObject _ self basicAt: firstIndex.
	self basicAt: firstIndex put: nil.
	firstIndex _ firstIndex + 1.
	^firstObject!

removeFirst: numElements
	"Remove the first numElements elements of the receiver,
	and answer an Array of them.  If the receiver has fewer
	than numElements elements, create an error
	message."

	| result |
	numElements > self size ifTrue: [^self notEnoughElementsError].
	result _ Array new: numElements.
	1 to: numElements do:
		[:index |
		result at: index put: (self basicAt: firstIndex).
		self basicAt: firstIndex put: nil.
		firstIndex _ firstIndex + 1].
	^result!

removeLast
	"Remove the last element of the receiver.  If the receiver is empty, 
	provide an error notification."

	| lastObject |
	self emptyCheck.
	lastObject _ self basicAt: lastIndex.
	self basicAt: lastIndex put: nil.
	lastIndex _ lastIndex - 1.
	^lastObject!

removeLast: numElements
	"Remove the last numElements elements of the receiver,
	and answer an Array of them.  If the receiver has fewer
	than numElements elements, create an error
	message."

	| result |
	numElements > self size ifTrue: [^self notEnoughElementsError].
	result _ Array new: numElements.
	1 to: numElements do:
		[:index |
		result at: numElements + 1 - index put: (self basicAt: lastIndex).
		self basicAt: lastIndex put: nil.
		lastIndex _ lastIndex - 1].
	^result! !

!OrderedCollection methodsFor: 'enumerating'!

collect: aBlock 
	"Evaluate aBlock with each of the values of the receiver as the  
	argument.  Collect the resulting values into a collection that is like 
	the receiver.  Answer the new collection."

 	"Override superclass in order to use add:, not at:put:."

	| newCollection |
	newCollection _ self copyEmpty: self size.
	self do: [:each | newCollection add: (aBlock value: each)].
	^newCollection!

do: aBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument."

	firstIndex to: lastIndex do:
		[ :index |	aBlock value: (self basicAt: index)	].!

reverse
	"Answer a new collection like the receiver with its elements in the 
	opposite order."

	"Override superclass in order to use add:, not at:put:."

	| newCollection |
	newCollection _ self copyEmpty: self size.
	self reverseDo: [:each | newCollection add: each].
	^newCollection!

reverseDo: aBlock
	"Evaluate aBlock with each of the receiver's elements as the argument, starting
	with the last element and taking each in sequence up to the first."

	"Override the superclass for performance"

	lastIndex to: firstIndex by: -1 do:
		[ :index |	aBlock value: (self basicAt: index)	].!

select: aBlock 
	"Evaluate aBlock with each of my elements as the argument.  Collect into a new 
	collection like me, only those elements for which aBlock evaluates to true. 
	Override superclass in order to use add:, not at:put:."

	| newCollection |
	newCollection _ self copyEmpty.
	self do: [:each | (aBlock value: each) ifTrue: [newCollection add: each]].
	^newCollection! !

!OrderedCollection methodsFor: 'user interface'!

inspect
	"Create and schedule a OrderedCollectionInspector in which the user 
	can examine the receiver's variables."

	InspectorView open: (OrderedCollectionInspector inspect: self)! !

!OrderedCollection methodsFor: 'private: private'!

addLastNoCheck: newObject 
	"Add newObject to the end of the receiver."

	lastIndex _ lastIndex + 1.
	self basicAt: lastIndex put: newObject.
	^newObject!

find: oldObject 
	| index |
	index _ firstIndex.
	[index <= lastIndex and: [oldObject ~= (self basicAt: index)]]
		whileTrue: [index _ index + 1].
	index <= lastIndex
		ifTrue: [^index]
		ifFalse: [^self notFoundError]!

firstObjectError
	self error: 'specified object is first object'!

insert: anObject before: spot 
	| index delta spotIndex |
	(spot + spot < (firstIndex + lastIndex) or: [lastIndex = self basicSize])
		ifTrue:
			[" Insert by moving previous elements down. "
			spotIndex _ spot - 1.
			firstIndex = 1
				ifTrue: 
					[delta _ spotIndex - firstIndex.
					self makeRoomAtFirst.
					spotIndex _ firstIndex + delta].
			index _ firstIndex _ firstIndex - 1.
			[index < spotIndex]
				whileTrue: 
					[self basicAt: index put: (self basicAt: index + 1).
					index _ index + 1]]
		ifFalse:
			[" Insert by moving subsequent elements up. "
			spotIndex _ spot.
			index _ lastIndex _ lastIndex + 1.
			[index > spotIndex]
				whileTrue: 
					[self basicAt: index put: (self basicAt: index - 1).
					index _ index - 1]].
	self basicAt: index put: anObject.
	^anObject!

lastObjectError
	self error: 'specified object is last object'!

makeRoomAtFirst
	| delta |
	delta _ self basicSize - lastIndex.
	delta = 0
		ifTrue:
			[" Since makeRoomAtFirst is only called if
			firstIndex = 1, delta = 0 means there is no room left.
			Assume that grow leaves room at first. "
					^self grow].
	lastIndex to: firstIndex by: -1
		do: [:i | self basicAt: i + delta put: (self basicAt: i)].
	firstIndex to: firstIndex + delta - 1
		do: [:i | self basicAt: i put: nil].
	firstIndex _ firstIndex + delta.
	lastIndex _ self basicSize!

makeRoomAtLast
	| delta |
	delta _ 1 - firstIndex.
	delta = 0
		ifTrue:
			[" Since makeRoomAtLast is only called if
			lastIndex = self basicSize,
			delta = 0 means there is no room left.
			Assume that grow leaves room at last. "
			^self grow].
	firstIndex to: lastIndex
		do: [ :i |	self basicAt: i + delta put: (self basicAt: i)	].
	lastIndex + delta + 1 to: lastIndex
		do: [ :i |	self basicAt: i put: nil	].
	firstIndex _ 1.
	lastIndex _ lastIndex + delta!

noSuchElementError
	self error: 'attempt to index non-existent element in an ordered collection'!

notEnoughElementsError
	self error: 'attempt to remove more elements than are in the collection'!

notFoundError
	"Raise a signal indicating that an object is not in the collection."

	Object notFoundSignal raise!

removeIndex: removedIndex 
	"Remove the element of the collection at position anIndex."

	| index |
	index _ removedIndex.
	[index < lastIndex]
		whileTrue: 
			[self basicAt: index put: (self basicAt: index + 1).
			index _ index + 1].
	self basicAt: lastIndex put: nil.
	lastIndex _ lastIndex - 1!

setIndices
	firstIndex _ self basicSize // 2 + 1.
	lastIndex _ firstIndex - 1!

setIndicesFrom: initialIndex
	firstIndex _ initialIndex max: 1.
	lastIndex _ firstIndex -1! !

!OrderedCollection methodsFor: 'testing'!

isEmpty
	"Reimplement this for speed."
	^firstIndex > lastIndex! !

!OrderedCollection methodsFor: 'fileIn/Out'!

storeBinaryOn: stream

	stream storeRecordOfClass: self class.
	stream nextPut: self size.
	self do: [:val | stream nextPut: val]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OrderedCollection class
	instanceVariableNames: ''!


!OrderedCollection class methodsFor: 'instance creation'!

new
	"Answer a new empty instance of OrderedCollection."

	^self new: 10!

new: anInteger 
	"Answer a new empty instance of OrderedCollection.

	The size of an OrderedCollection is determined by the actual number of
	stored elements.  Creating an instance using new: results in an empty
	collection, regardless of the size declared."
	
	"If a subclass adds fields, then it is necessary for that subclass to reimplement 
	new: "

	^(super new: anInteger) setIndices! !

!OrderedCollection class methodsFor: 'fileIn/Out'!

readBinaryFrom: stream tag: tag
	"Answer object appearing next in stream."
	| size oc |
	size _ stream next.  "integer"
	oc _ self new: (size max: 1).
	stream register: oc id: tag.
	1 to: size do:
		[:i | oc add: stream next].
	^oc! !