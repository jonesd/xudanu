'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:58 pm'!

Association subclass: #AssociationTree
	instanceVariableNames: 'children '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Tree'!
AssociationTree comment:
'Instances of this class represent the basic notion of tree nodes.  Each tree node has a key (or name), a value, and a collection of children.
Instance Variables:
		children		<OrderedCollection> 		the receiver''s children'!


!AssociationTree methodsFor: 'accessing'!

at: anIndex 
	"Answer the child of the receiver identified by anIndex."

	^children at: anIndex!

children
	"Answer the receiver's OrderedCollection of children."

	children == nil ifTrue: [^OrderedCollection new].
	^children!

findIndexOfChild: someObject
	"Answer the index of someObject, that is, its position as one of the 
	children of the receiver. Answer nil if someObject is not a child of the 
	receiver."

	children == nil ifTrue: [^nil].
	1 to: children size 
		do: [:i | (children at: i) == someObject ifTrue: [^i]].
	^nil!

isLeaf
	"Answer whether or not the receiver is a leaf, i.e., whether the 
	receiver has children."

	^children == nil or: [children size = 0]!

name
	"Answer the name (key) of the receiver."

	^key!

size
	"Answer the number of children of the receiver."

	^children == nil
		ifTrue: [0]
		ifFalse: [children size]! !

!AssociationTree methodsFor: 'copying'!

copy
	"Answer another instance just like the receiver, but with a copy of 
	the receiver's value and a copy of each of the receiver's children."

	| cpy tmpChildren |
	tmpChildren := children.
	children := nil.
	cpy := self shallowCopy.
	cpy value: value copy.
	tmpChildren isNil
		ifFalse: [tmpChildren do: [:child | cpy addChild: child copy]].
	children := tmpChildren.
	^cpy!

copyAndReplaceInSet: aSet
	"Answer a copy of the receiver with all references to it in aSet 
	updated as well."

	| cpy tmpChildren |
	tmpChildren := children.
	children := nil.
	cpy := self shallowCopy.
	cpy value: value copy.
	(aSet includes: self)
		ifTrue: [aSet remove: self.
				aSet add: cpy].
	tmpChildren isNil
		ifFalse: [tmpChildren do:
					[:child |
					cpy addChild: (child copyAndReplaceInSet: aSet)]].
	children := tmpChildren.
	^cpy!

deepCopy
	"Answer a copy of the receiver with its own deepCopy of each instance variable."

	| tmpChildren cpy |
	tmpChildren := children.
	children := nil.
	cpy := super deepCopy.
	tmpChildren isNil
		ifFalse: [tmpChildren do:
					[:child |
					cpy addChild: child deepCopy]].
	children := tmpChildren.
	^cpy! !

!AssociationTree methodsFor: 'adding'!

addChild: anObject 
	"Add anObject as a child of the receiver."

	children == nil ifTrue: [children := OrderedCollection new].
	children addLast: anObject.!

addChild: anObject after: someObject 
	"Add anObject to the receiver's list of children after someObject."

	| index |
	index := self findIndexOfChild: someObject.
	index == nil
		ifTrue: [self error: 'object not found'].
	index = children size
		ifTrue: [^self addChild: anObject].
	self children add: anObject beforeIndex: index+1.!

addChild: anObject before: someObject 
	"Add anObject to the receiver's list of children before someObject."

	| index |
	index := self findIndexOfChild: someObject.
	index == nil
		ifTrue: [self error: 'object not found'].
	self children add: anObject beforeIndex: index.! !

!AssociationTree methodsFor: 'removing'!

removeChild: anObject 
	"Remove the anObject from the receiver's list of children."

	self children remove: anObject.
	self children isEmpty ifTrue: [children := nil]! !

!AssociationTree methodsFor: 'searching'!

childNamed: aKey 
	"Search just the receiver's children to find the child named aKey. 
	Answer the child if it exists, otherwise answer nil."

	^self children detect: [:each | each key = aKey]
		ifNone: [nil]!

childrenNames
	"Answer the names of children in the receiver's list of children."

	^self children collect: [:each | each key]!

find: aKey
	"Recursively (depth-first) search the receiver's children to find the child named aKey. 
	Answer the child if it exists, otherwise return nil."

	| result |
	aKey = key
		ifTrue: [^self]
		ifFalse: [self isLeaf
					ifTrue: [^nil]
					ifFalse: [children do:
								[:child |
								result := child find: aKey.
								result == nil ifFalse: [^result]].
							^nil]]! !

!AssociationTree methodsFor: 'enumeration'!

childrenDo: aBlock 
	"For each of the receiver's children, execute aBlock with each child 
	as an argument."

	self children do: 
		[:m | 
		aBlock value: m.
		m childrenDo: aBlock]!

withChildrenDo: aBlock
	"For the receiver and each of its children, execute aBlock with each 
	as an argument."

	aBlock value: self.
	self children do: [:m | m withChildrenDo: aBlock]!

withChildrenDo: aBlock level: level {Integer}
	"For the receiver and each of its children, execute aBlock with each 
	as an argument."

	aBlock value: self value: level.
	self children do: [:m | m withChildrenDo: aBlock level: level + 1]! !