'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:21 pm'!

Object subclass: #Collection
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Abstract'!
Collection comment:
'The abstract class Collection is at the top of the collection hierarchy.  Its subclasses are Bag, MappedCollection, SequenceableCollection, and Set.  Bag and Set are unordered and their elements are not accessible by an external key.  Duplicates are not allowed in a Set.  Elements of a SequenceableCollection are ordered and the ordering can be determined externally, as in an ArrayedCollection, or internally, as in an Interval.  MappedCollection represents an indirect access path to a collection whose elements are accessible via external keys.

Concrete subclasses must implement methods for 
	adding
		add:
	removing
		remove: ifAbsent:
	enumerating
		do:'!


!Collection methodsFor: 'accessing'!

size
	"Answer how many elements the receiver contains."

	| tally |
	tally _ 0.
	self do: [:each | tally _ tally + 1].
	^tally! !

!Collection methodsFor: 'testing'!

{Boolean} areAll: aBlock {BlockClosure of: Object with: Boolean}

	^self areAny: [:el {Object} |
		(aBlock value: el) not]!

{Boolean} areAny: aBlock {BlockClosure of: Object with: Boolean}

	self detect: aBlock ifNone: [^false].
	^true!

includes: anObject 
	"Answer whether anObject is one of the receiver's elements."

	self do: [:each | anObject = each ifTrue: [^true]].
	^false!

isEmpty
	"Answer whether the receiver contains any elements."

	^self size = 0!

occurrencesOf: anObject 
	"Answer how many of the receiver's elements are equal to anObject."

	| tally |
	tally _ 0.
	self do: [:each | anObject = each ifTrue: [tally _ tally + 1]].
	^tally! !

!Collection methodsFor: 'copying'!

copyEmpty: aSize
	"Answer a copy of the receiver that contains no elements.

	This method should be redefined in subclasses that add
	instance variables, so that the state of those variables
	is preserved"

	^self species new: aSize! !

!Collection methodsFor: 'adding'!

add: newObject 
	"Include newObject as one of the receiver's elements.  Answer newObject.
	This message should not be sent to instances of subclasses of ArrayedCollection."

	self subclassResponsibility!

addAll: aCollection 
	"Include all the elements of aCollection as the receiver's elements.  Answer
	aCollection."

	aCollection do: [:each | self add: each].	
	^aCollection!

addIfNonNil: newObject 
	"Include newObject as one of the receiver's elements.  Answer newObject.
	This message should not be sent to instances of subclasses of ArrayedCollection."

	newObject ~~ nil
		ifTrue: [self add: newObject]! !

!Collection methodsFor: 'removing'!

remove: oldObject 
	"Remove oldObject as one of the receiver's elements.  Answer 
	oldObject unless no element is equal to oldObject, in which case, 
	provide an error notification. "

	^self remove: oldObject ifAbsent: [self notFoundError]!

remove: oldObject ifAbsent: anExceptionBlock 
	"Remove oldObject as one of the receiver's elements.  If several of the
	elements are equal to oldObject, only one is removed. If no element is equal to
	oldObject, answer the result of evaluating anExceptionBlock.  Otherwise,
	answer the argument, oldObject.

	SequenceableCollections can not respond to this message."

	self subclassResponsibility!

removeAll: aCollection 
	"Remove each element of aCollection from the receiver.  If successful for each,
	answer aCollection."

	aCollection do: [:each | self remove: each].
	^aCollection!

wipe: oldObject 

	self remove: oldObject ifAbsent: [].
	^VOID!

wipeAll: aCollection 
	"Remove each element of aCollection from the receiver.  If successful for each,
	answer aCollection."

	aCollection do: [:each | self remove: each ifAbsent: []].
	^aCollection! !

!Collection methodsFor: 'enumerating'!

collect: aBlock  
	"Evaluate aBlock with each of the values of the receiver as the  
	argument.  Collect the resulting values into a collection that is like 
	the receiver.  Answer the new collection."

	| newCollection |
	newCollection _ self species new.
	self do: [:each | newCollection add: (aBlock value: each)].
	^newCollection!

detect: aBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument.
	Answer the first element for which aBlock evaluates to true."

	^self detect: aBlock ifNone: [self notFoundError]!

detect: aBlock ifNone: exceptionBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument.
	Answer the first element for which aBlock evaluates to true."

	self do: [:each | (aBlock value: each) ifTrue: [^each]].
	^exceptionBlock value!

do: aBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument."

	self subclassResponsibility!

do: aBlock andBetweenDo: betweenBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument."

	self asOrderedCollection do: aBlock andBetweenDo: betweenBlock!

{void} doAll: blocks {Collection of: (BlockClosure of: Object)}
	"Apply the first block to each of my elements, then the second block, etc.  While giving some minimal feedback on the Transcript"
	
	| mTotal {IntegerVar} 
	  mSoFar {IntegerVar} 
	  bTotal {IntegerVar} 
	  bSoFar {IntegerVar} |
	mTotal _ self size.
	mTotal <= 1
		ifTrue: [blocks do: [:aBlock {BlockClosure of: Object} |
					self do: aBlock].
				^VOID].
	bTotal _ blocks size.
	bSoFar _ 0.
	blocks do: [:aBlock {BlockClosure of: Object} |
		mSoFar _ 0.
		bSoFar _ bSoFar + 1.
		bTotal > 1
			ifTrue: [Transcript cr.
					Transcript << 'Phase ' << bSoFar << ' of ' << bTotal; endEntry].
		Transcript cr.
		Transcript << mTotal << ' '; endEntry.
		self do: [:obj {Object} |
			aBlock value: obj.
			mSoFar _ mSoFar + 1.
			Transcript << (mTotal - mSoFar) << ' '; endEntry]].
	Transcript cr; show: 'Done'; endEntry!

inject: thisValue into: binaryBlock 
	"Accumulate a running value associated with evaluating the argument,
	binaryBlock, with the current value and the receiver as block arguments. 
	The initial value is the value of the argument, thisValue."

	"For example, to sum a collection, use: 
		collection inject: 0 into: [:subTotal :next | subTotal + next]."

	| nextValue |
	nextValue _ thisValue.
	self do: [:each | nextValue _ binaryBlock value: nextValue value: each].
	^nextValue!

reject: aBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument. 
	Collect into a new collection like the receiver, only those elements for which
	aBlock evaluates to false.  Answer the new collection."

	^self select: [:element | (aBlock value: element) == false]!

select: aBlock 
	"Evaluate aBlock with each of the receiver's elements as the argument. 
	Collect into a new collection like the receiver, only those elements for which
	aBlock evaluates to true.  Answer the new collection."

	| newCollection |
	newCollection _ self species new.
	self do: [:each | (aBlock value: each) ifTrue: [newCollection add: each]].
	^newCollection! !

!Collection methodsFor: 'printing'!

printOn: aStream 
	"Append to the argument aStream a sequence of characters 
	that identifies the collection.  The general format for collections
	is
		Collection-name ( element element element )
	unless there are a large number in which case the listing is
	truncated with the words ...etc..."

	| tooMany |
	tooMany _ aStream position + self maxPrint.
	aStream nextPutAll: self class name, ' ('.
	self do: 
		[:element | 
		aStream position > tooMany ifTrue: [aStream nextPutAll: '...etc...)'. ^self].
		element printOn: aStream.
		aStream space].
	aStream nextPut: $)!

storeOn: aStream 
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates an collection similar to the receiver. The general format
	for collections is
		((class-name new) add: element; add: element; .... ; yourself)"

	| noneYet |
	aStream nextPutAll: '(('.
	aStream nextPutAll: self class name.
	aStream nextPutAll: ' new)'.
	noneYet _ true.
	self do: 
		[:each | 
		noneYet
			ifTrue: [noneYet _ false]
			ifFalse: [aStream nextPut: $;].
		aStream nextPutAll: ' add: '.
		aStream store: each].
	noneYet ifFalse: [aStream nextPutAll: '; yourself'].
	aStream nextPut: $)! !

!Collection methodsFor: 'converting'!

asBag
	"Answer a new instance of Bag whose elements are the elements of
	the receiver."

	| aBag |
	aBag _ Bag new.
	self do: [:each | aBag add: each].
	^aBag!

asIdentitySet
	"Answer a new instance of Set whose elements are the unique elements of
	the receiver."

	| aSet |
	aSet _ IdentitySet new: self size.
	self do: [:each | aSet add: each].
	^aSet!

asOrderedCollection
	"Answer a new instance of OrderedCollection whose elements are the elements of
	the receiver.  The order in which elements are added depends on the order in
	which the receiver enumerates its elements.  In the case of unordered collections,
	the ordering is not necessarily the same for multiple requests for the conversion."

	| anOrderedCollection |
	anOrderedCollection _ OrderedCollection new: self size.
	self do: [:each | anOrderedCollection addLast: each].
	^anOrderedCollection!

asSet
	"Answer a new instance of Set whose elements are the unique elements of
	the receiver."

	| aSet |
	aSet _ Set new: self size.
	self do: [:each | aSet add: each].
	^aSet!

asSortedCollection
	"Answer a new instance of SortedCollection whose elements are the elements of
	the receiver.  The sort order is the default less than or equal ordering."

	| aSortedCollection |
	aSortedCollection _ SortedCollection new: self size.
	aSortedCollection addAll: self.
	^aSortedCollection!

asSortedCollection: aBlock 
	"Answer a new instance of SortedCollection whose elements are the elements of
	the receiver.  The sort order is defined by the argument, aBlock."

	| aSortedCollection |
	aSortedCollection _ SortedCollection new: self size.
	aSortedCollection sortBlock: aBlock.
	aSortedCollection addAll: self.
	^aSortedCollection! !

!Collection methodsFor: 'private: private'!

emptyCheck
	"Provide an error notification if the collection is empty."

	self isEmpty ifTrue: [^self emptyCollectionError]!

emptyCollectionError
	"Answer an error notification because the collection is empty."

	self error: 'this collection is empty'!

growSize
	"Answer an amount by which the receiver should grow 
	to make room for more elements."

	^self basicSize max: 2!

maxPrint
	"Answer the maximum number of characters to print with printOn:."

	^5000!

noMatchError
	"Answer an error notification because the collection sizes do not match."

	self error: 'collection sizes do not match'!

notFoundError
	"Raise a signal indicating that an object is not in the collection."

	Object notFoundSignal raise!

notKeyedError
	"Answer an error notification because the collection 
	does not respond to keyed accessing messages."

	self error: self class name, 's do not respond to keyed accessing messages.'! !

!Collection methodsFor: 'cxx extensions'!

count
	^self size!

{Object} theOne

	self size ~= 1
		ifTrue: [self error: 'Must have exactly one element'].
	self do: [:el |
		^el]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Collection class
	instanceVariableNames: ''!


!Collection class methodsFor: 'instance creation'!

create
	^self new!

create: size
	^self new: size!

with: anObject 
	"Answer a new instance of a Collection containing anObject."

	| newCollection |
	newCollection _ self new.
	newCollection add: anObject.
	^newCollection!

with: firstObject with: secondObject 
	"Answer a new instance of a Collection containing 
	the two arguments as elements."

	| newCollection |
	newCollection _ self new.
	newCollection add: firstObject.
	newCollection add: secondObject.
	^newCollection!

with: firstObject with: secondObject with: thirdObject 
	"Answer with a new instance of a Collection containing 
	the three arguments as elements."

	| newCollection |
	newCollection _ self new.
	newCollection add: firstObject.
	newCollection add: secondObject.
	newCollection add: thirdObject.
	^newCollection!

with: firstObject with: secondObject with: thirdObject with: fourthObject 
	"Answer a new instance of a Collection containing the	
	four arguments as the elements."

	| newCollection |
	newCollection _ self new.
	newCollection add: firstObject.
	newCollection add: secondObject.
	newCollection add: thirdObject.
	newCollection add: fourthObject.
	^newCollection! !