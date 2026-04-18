'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:39 pm'!

PeekableStream subclass: #PositionableStream
	instanceVariableNames: 'collection position readLimit writeLimit '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Streams'!
PositionableStream comment:
'Class PositionableStream assumes that the contents of its instances is an indexable collection and that, in support of accessing the elements of the contents, it can reposition a pointer.  Class PositionableStream is abstract in that it does not implement the messages next and nextPut: which are inherited from the abstract superclass Stream.

Instance Variables:
	collection 	<SequenceableCollection>
	position 	<Integer> pointer to the current access position
	readLimit 	<Integer> size of the collection
	writeLimit	<Integer>  farthest that has been written into the collection'!


!PositionableStream methodsFor: 'accessing'!

<< anObject 
	anObject isString
		ifTrue: [self nextPutAll: anObject]
		ifFalse: [anObject isCharacter
				ifTrue: [self nextPut: anObject]
				ifFalse: [self print: anObject]].
	^self!

contents
	"Answer with a copy of the receiver's collection from 1 to readLimit."

	^collection copyFrom: 1 to: readLimit!

DOTput: character

	self nextPut: character!

next: anInteger
	"Answer the next anInteger elements of the receiver."

	| newCollection howManyRead increment |
	newCollection _ self contentsSpecies new: anInteger.
	anInteger = 0
		ifTrue: [^newCollection].
	self atEnd
		ifTrue:	[^Stream incompleteNextCountSignal
					raiseRequestWith: (self contentsSpecies new: 0)].
	newCollection at: 1 put: self next.
	howManyRead _ 1.
	[howManyRead < anInteger] whileTrue:
		[self atEnd
			ifTrue: [^Stream incompleteNextCountSignal
						raiseRequestWith: (newCollection copyFrom: 1 to: howManyRead)].
		increment _ (readLimit - position) min: (anInteger - howManyRead).
		newCollection
			replaceFrom: (howManyRead + 1)
			to: (howManyRead _ howManyRead + increment)
			with: collection
			startingAt: (position + 1).
		position _ position + increment].
	^newCollection!

nextPutAll: aCollection 
	"Append the elements of aCollection onto the receiver.  Answer aCollection."

	| newPosition collectionSize |
	((collectionSize _ aCollection size) > 1 and: [aCollection isSequenceable])
		ifFalse: [^super nextPutAll: aCollection].
	"Use nextPut: for the first write to make sure that we may write."
	self nextPut: (aCollection at: 1).

	newPosition _ position + collectionSize -1.
	newPosition > writeLimit
		ifTrue: [collection growToAtLeast: newPosition.
				writeLimit _ collection size].
	collection
		replaceFrom: position + 1
		to: newPosition
		with: aCollection
		startingAt: 2.
	position _ newPosition.
	^aCollection!

skipToAll: aCollection
	"Skip forward to the occurrence (if any, not inclusive) of aCollection.  If not there, answer nil.  Leaves positioned before aCollection."

	| nonMatch first length element |
	(length _ aCollection size) = 0 ifTrue: [^nil].
	first _ aCollection at: 1.
	[true] whileTrue:
		[[(element _ self next) == nil or: [element = first]] whileFalse: 
			[ ].
		element == nil ifTrue: [ ^nil ].
		nonMatch _ 2.
		[nonMatch <= length and: [self next = (aCollection at: nonMatch)]]
				whileTrue: [nonMatch _ nonMatch + 1].
		nonMatch > length
			ifTrue: [self skip: length negated.
					^self].							"success"
		self atEnd ifTrue: [^nil].
													"back up"
		self skip: 1 - nonMatch ]!

throughAll: aCollection
	"Answer a subcollection from position to the occurrence (if any, inclusive) of aCollection.  If not there, answer everything.  Leaves positioned after aCollection."

	| newStream nonMatch first element length|
	(length _ aCollection size) = 0 ifTrue: [^(self contentsSpecies new: 0)].
	first _ aCollection at: 1.
	newStream _ (self contentsSpecies new: 64) writeStream.
	[true] whileTrue:
			[[self atEnd  or: [(element _ self next) = first]]
				whileFalse: [newStream nextPut: element].
			self atEnd ifTrue: [^newStream contents].		"answer everything"
			nonMatch _ 2.
			[nonMatch <= length and: [self atEnd not and: [self next = (aCollection at: nonMatch)]]]
				whileTrue: [nonMatch _ nonMatch + 1].
			nonMatch > length 
				ifTrue: [newStream nextPutAll: aCollection.
						^newStream contents] "found it"
				ifFalse: [newStream nextPut: first]. " move on"
			self atEnd ifTrue: [nonMatch _ nonMatch - 1].
			self skip: 1 - nonMatch]							"back up"!

upToAll: aCollection
	"Answer a subcollection from position to the occurrence (if any, not inclusive) of aCollection.  If not there, answer everything.  Leaves positioned before aCollection."

	| newStream nonMatch first element length |
	(length _ aCollection size) = 0 ifTrue: [^(self contentsSpecies new: 0)].
	first _ aCollection first.
	newStream _ (self contentsSpecies new: 64) writeStream.
	[true] whileTrue:
		[[self atEnd or: [(element _ self next) = first]]
			whileFalse: [newStream nextPut: element].
		self atEnd ifTrue: [^newStream contents].			"answer everything"
		nonMatch _ 2.
		[nonMatch <= length and: [self atEnd not and: [self next = (aCollection at: nonMatch)]]]
				whileTrue: [nonMatch _ nonMatch + 1].
		nonMatch > length 
				ifTrue: [self skip: 1 - nonMatch.
						^newStream contents]. "found it"
		newStream nextPut: first.
		self atEnd
			ifTrue: [nonMatch _ nonMatch - 1].
		self skip: 1 - nonMatch]					"back up"! !

!PositionableStream methodsFor: 'testing'!

atEnd
	"Answer whether the position is greater than or equal to the limit.  
	Fail if either the receiver's position or readLimit is not a SmallInteger.  
	Optional. See Object documentation whatIsAPrimitive."

	<primitive: 67>
	^position >= readLimit!

isEmpty
	"Answer whether the receiver contains any elements."

	^position = 0! !

!PositionableStream methodsFor: 'positioning'!

position
	"Answer the current position of accessing the stream."

	^position!

position: anInteger 
	"Set position to anInteger as long as anInteger is within the bounds of the 
	receiver's contents.  If it is not, provide an error notification."

	(anInteger >= 0 and: [anInteger <= readLimit])
		ifTrue: [position _ anInteger]
		ifFalse: [^self positionOutOfBoundsError: anInteger]!

reset
	"Set the receiver's position to 0."

	position _ 0!

setToEnd
	"Set the position of the receiver to the end of its stream of elements."

	readLimit _ readLimit max: position.
	position _ readLimit!

skip: anInteger 
	"Set position to position+anInteger. A subclass might choose to be more 
	helpful and select the minimum of self size and position+anInteger or 
	maximum of 1 and position+anInteger for the repositioning."

	self position: position + anInteger! !

!PositionableStream methodsFor: 'private: private'!

contentsSpecies

	^collection species!

on: aCollection 
	collection _ aCollection.
	readLimit _ aCollection size.
	position _ 0.
	self reset!

positionOutOfBoundsError: aPosition
	"Raise a signal indicating that an object has attempted to set the
	position of the receiver out of bounds."

	"Since the receiver is not necessarily writable, it is up to the subclasses to override 
	position: if expanding the collection is preferrable to giving this error."

	^self class positionOutOfBoundsSignal 
							raiseWith: aPosition.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PositionableStream class
	instanceVariableNames: ''!


!PositionableStream class methodsFor: 'instance creation'!

on: aCollection 
	"Answer a new instance of the receiver, streaming over aCollection."

	^self basicNew on: aCollection!

on: aCollection from: firstIndex to: lastIndex 
	"Answer a new instance of the receiver, streaming over a copy of aCollection from
	firstIndex to lastIndex."

	^self basicNew on: (aCollection copyFrom: firstIndex to: lastIndex)! !