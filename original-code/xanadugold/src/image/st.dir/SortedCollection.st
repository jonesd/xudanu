'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:30 pm'!

OrderedCollection variableSubclass: #SortedCollection
	instanceVariableNames: 'sortBlock '
	classVariableNames: 'DefaultSortBlock '
	poolDictionaries: ''
	category: 'Collections-Sequenceable'!
SortedCollection comment:
'A SortedCollection is an ordered collection of elements, sorted via a function of two arguments.  It is a kind of OrderedCollection whose elements are internally ordered according to the rules of the function.

Instance Variables: *indexed*
	sortBlock	<BlockClosure>	The function for sorting the elements of the collection.

Class Variables:
	DefaultSortBlock	<BlockClosure> in particular [:x :y | x <= y]'!


!SortedCollection methodsFor: 'initialize-release'!

initialize
	"Set the initial value of the receiver's sorting algorithm to a default."

	sortBlock _ DefaultSortBlock! !

!SortedCollection methodsFor: 'comparing'!

= aSortedCollection 
	"Answer whether the species of the receiver and argument are the same,
	and if their blocks and elements are the same."

	self species = aSortedCollection species ifFalse: [^false].
	sortBlock = aSortedCollection sortBlock
		ifTrue: [^super = aSortedCollection]
		ifFalse: [^false]! !

!SortedCollection methodsFor: 'accessing'!

at: anInteger put: anObject 
	"Provide an error notification that storing into a SortedCollection 
	must be done using the message add:."

	self error: 'to add to a sorted collection, you must use add:'!

partialOrder
	"Sort the collection under the assumption that the given ordering is only a partial ordering (i.e. sortBlock value: a value: b = true implies that a must come before b, but = false does not imply b must come before a)"
	
	| di dj |
	firstIndex to: lastIndex - 1 do: [ :i |
		i + 1 to: lastIndex do: [ :j |
			di := self basicAt: i.
			dj := self basicAt: j.
			(sortBlock value: dj value: di) ifTrue:
				[self basicAt: i put: dj.
				self basicAt: j put: di]]]!

sortBlock
	"Answer the blockContext which is the criterion for sorting elements of
	the receiver."

	^sortBlock!

sortBlock: aBlock 
	"Make the argument, aBlock, be the criterion for ordering elements of the
	receiver."

	sortBlock _ aBlock.
	self size > 0 ifTrue: [self reSort]! !

!SortedCollection methodsFor: 'copying'!

copyEmpty: aSize
	"Answer a copy of the receiver that contains no elements.

	This method should be redefined in subclasses that add
	instance variables, so that the state of those variables
	is preserved"

	^(super copyEmpty: aSize) sortBlock: sortBlock! !

!SortedCollection methodsFor: 'adding'!

add: newObject 
	"Include newObject as one of the receiver's elements.  Answer newObject."

	| nextIndex |
	self isEmpty ifTrue: [^super addLast: newObject].
	nextIndex _ self indexForInserting: newObject.
	self insert: newObject before: nextIndex.
	^newObject!

addAll: aCollection 
	"Include each element of aCollection as one of the receiver's 
	elements. Answer aCollection."

	aCollection size > (self size // 3)
		ifTrue: 
			["Faster to add the new elements and resort"
			aCollection do: [:each | super addLast: each].
			self reSort]
		ifFalse: ["Faster to add the elements individually in their proper places"
			aCollection do: [:each | self add: each]].
	^aCollection! !

!SortedCollection methodsFor: 'enumerating'!

collect: aBlock 
	"Evaluate aBlock with each of my elements as the argument.  Collect the 
	resulting values into an OrderedCollection  Answer with the new collection. 
	Override superclass in order to produce OrderedCollection instead of 
	SortedCollection. "

	| newCollection |
	newCollection _ OrderedCollection new.
	self do: [:each | newCollection add: (aBlock value: each)].
	^newCollection!

reverse
	"Answer a new collection like the receiver with its elements in the 
	opposite order."

	"Override superclass in order to use add:, not at:put:."

	| newCollection |
	newCollection _ OrderedCollection new: self size.
	self reverseDo: [:each | newCollection add: each].
	^newCollection! !

!SortedCollection methodsFor: 'private: private'!

indexForInserting: newObject 
	| index low high |
	low _ firstIndex.
	high _ lastIndex.
	[index _ high + low // 2.
	low > high]
		whileFalse: 
			[(sortBlock value: (self basicAt: index) value: newObject)
				ifTrue: [low _ index + 1]
				ifFalse: [high _ index - 1]].
	^low!

reSort
	self sort: firstIndex to: lastIndex!

sort: i to: j 
	"Sort elements i through j of self to be nondescending according to sortBlock."

	| di dij dj tt ij k l n |
	"The prefix d means the data at that index."
	(n _ j + 1  - i) <= 1 ifTrue: [^self].	"Nothing to sort." 
	 "Sort di,dj."
	di _ self basicAt: i.
	dj _ self basicAt: j.
	(sortBlock value: di value: dj) "i.e., should di precede dj?"
		ifFalse: 
			[self swap: i with: j.
			 tt _ di.
			 di _ dj.
			 dj _ tt].
	n > 2
		ifTrue:  "More than two elements."
			[ij _ (i + j) // 2.  "ij is the midpoint of i and j."
			 dij _ self basicAt: ij.  "Sort di,dij,dj.  Make dij be their median."
			 (sortBlock value: di value: dij) "i.e. should di precede dij?"
			   ifTrue: 
				[(sortBlock value: dij value: dj) "i.e., should dij precede dj?"
				  ifFalse: 
					[self swap: j with: ij.
					 dij _ dj]]
			   ifFalse:  "i.e. di should come after dij"
				[self swap: i with: ij.
				 dij _ di].
			n > 3
			  ifTrue:  "More than three elements."
				["Find k>i and l<j such that dk,dij,dl are in reverse order.
				Swap k and l.  Repeat this procedure until k and l pass each other."
				 k _ i.
				 l _ j.
				 [[l _ l - 1.  k <= l and: [sortBlock value: dij value: (self basicAt: l)]]
				   whileTrue.  "i.e. while dl succeeds dij"
				  [k _ k + 1.  k <= l and: [sortBlock value: (self basicAt: k) value: dij]]
				   whileTrue.  "i.e. while dij succeeds dk"
				  k <= l]
				   whileTrue:
					[self swap: k with: l]. 
	"Now l<k (either 1 or 2 less), and di through dl are all less than or equal to dk
	through dj.  Sort those two segments."
				self sort: i to: l.
				self sort: k to: j]]!

swap: i with: j 
	| t |
	t _ self basicAt: i.
	self basicAt: i put: (self basicAt: j).
	self basicAt: j put: t! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SortedCollection class
	instanceVariableNames: ''!


!SortedCollection class methodsFor: 'class initialization'!

initialize
	"Create a default sort block"
	"SortedCollection initialize"

	DefaultSortBlock _ [:x :y | x <= y]! !

!SortedCollection class methodsFor: 'instance creation'!

new: anInteger 
	"Answer a new instance of SortedCollection.
	The default sorting function is a <= comparison on elements."

	^(super new: anInteger) initialize!

sortBlock: aBlock 
	"Answer a new instance of SortedCollection such that its elements 
	are sorted according to the criterion specified in aBlock."

	^(super new: 10)
		sortBlock: aBlock! !

SortedCollection initialize!
