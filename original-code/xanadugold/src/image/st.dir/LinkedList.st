'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:28 pm'!

SequenceableCollection subclass: #LinkedList
	instanceVariableNames: 'firstLink lastLink '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Sequenceable'!
LinkedList comment:
'The class LinkedList implements ordered collections using a chain of elements.  Elements of a LinkedList are ordered by the sequence in which objects are added and removed;  the elements can be referred to by external keys that are indices.  Each element of a LinkedList must be an instance of class Link or of one of its subclasses.

A new instance of LinkedList can be initialized using
	LinkedList with: Link new

Instance Variables:
	firstLink		<Link>
	lastLink		<Link>'!


!LinkedList methodsFor: 'accessing'!

at: anInteger 
	"Answer the element at index anInteger. 
	at: is used by a knowledgeable client to access an existing element"

	| aLink count |
	aLink _ firstLink.
	count _ 1.
	[aLink == nil or: [count = anInteger]]
		whileFalse: 
			[count _ count + 1.
			aLink _ aLink nextLink].
	aLink == nil
		ifTrue: [^self subscriptBoundsError: anInteger]
		ifFalse: [^aLink]!

at: anIndex put: aLink
	"Put anObject at element index anInteger.
	 This message is used by a knowledgeable client to replace an element."
	
	self error: 'Do not store into a LinkedList using at:put: '!

first
	"Answer the first link;  provide an error notification if the receiver is 
	empty. "

	self emptyCheck.
	^firstLink!

last
	"Answer the last link;  provide an error notification
	if the receiver is empty."

	self emptyCheck.
	^lastLink!

size
	"Answer how many elements the receiver contains."

	| tally |
	tally _ 0.
	self do: [:each | tally _ tally + 1].
	^tally! !

!LinkedList methodsFor: 'testing'!

isEmpty
	"Answer whether the receiver contains any elements."

	^firstLink == nil! !

!LinkedList methodsFor: 'adding'!

add: aLink 
	"Add aLink to the end of the receiver's list."

	^self addLast: aLink!

addFirst: aLink 
	"Add aLink to the beginning of the receiver's list."

	self isEmpty ifTrue: [lastLink _ aLink].
	aLink nextLink: firstLink.
	firstLink _ aLink.
	^aLink!

addLast: aLink 
	"Add aLink to the end of the receiver's list."

	self isEmpty
		ifTrue: [firstLink _ aLink]
		ifFalse: [lastLink nextLink: aLink].
	lastLink _ aLink.
	^aLink! !

!LinkedList methodsFor: 'removing'!

remove: aLink ifAbsent: exceptionBlock  
	"Remove aLink from the receiver.  If it is not there, answer the result of
	evaluating exceptionBlock."

	| tempLink |
	aLink == firstLink
		ifTrue: [firstLink _ aLink nextLink.
				aLink == lastLink
					ifTrue: [lastLink _ nil]]
		ifFalse: [tempLink _ firstLink.
				[tempLink == nil ifTrue: [^exceptionBlock value].
				 tempLink nextLink == aLink]
					whileFalse: [tempLink _ tempLink nextLink].
				tempLink nextLink: aLink nextLink.
				aLink == lastLink
					ifTrue: [lastLink _ tempLink]].
	aLink nextLink: nil.
	^aLink!

removeFirst
	"Remove the first element.  If the receiver is empty, cause an error;
	otherwise answer the removed element.  Using the sequence addFirst:/removeFirst
	causes the receiver to behave as a stack; using addLast:/removeFirst causes the
	receiver to behave as a queue."

	| oldLink |
	self emptyCheck.
	oldLink _ firstLink.
	firstLink == lastLink
		ifTrue: [firstLink _ nil. lastLink _ nil]
		ifFalse: [firstLink _ oldLink nextLink].
	oldLink nextLink: nil.
	^oldLink!

removeLast
	"Remove the receiver's last element.  If the receiver is empty, cause an error;
	otherwise answer the removed element.  Using addLast:/removeLast causes the
	receiver to behave as a stack; using addFirst:/removeLast causes the receiver to
	behave as a queue."

	| oldLink aLink |
	self emptyCheck.
	oldLink _ lastLink.
	firstLink == lastLink
		ifTrue: [firstLink _ nil. lastLink _ nil]
		ifFalse: [aLink _ firstLink.
				[aLink nextLink == oldLink] whileFalse:
					[aLink _ aLink nextLink].
				 aLink nextLink: nil.
				 lastLink _ aLink].
	oldLink nextLink: nil.
	^oldLink! !

!LinkedList methodsFor: 'enumerating'!

do: aBlock
	"Evaluate aBlock with each of the receiver's elements as the argument."

	| aLink |
	aLink _ firstLink.
	[aLink == nil] whileFalse:
		[aBlock value: aLink.
		 aLink _ aLink nextLink]! !