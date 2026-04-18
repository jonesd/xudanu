'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:01 pm'!

Model subclass: #TreeSelection
	instanceVariableNames: '
		tree {AssociationTree}
		treeAccessor {TreeAccessor}
		openedSet {IdentitySet}
		currentSelection {AssociationTree}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Tree'!
TreeSelection comment:
'An instance of TreeSelection that holds a tree with a child selected and a set of children that have been opened for traversal.
Instance Variables:
	tree			<anObject> 	that represents the root of a tree structure
	treeAccessor	<TreeAccessor>	that acts as a protocol translator between the receiver 
									and the elements that comprise the tree
	openedSet		<IdentitySet>	set of tree elements whose children are considered traversable
	currentSelection <anObject>	the tree child that is currently selected
'!



!TreeSelection methodsFor: 'accessing'!

currentSelection
	"Answer the currently selected tree element."

	^currentSelection!

currentSelection: aNode
	"Set the receivers the currently selected tree element."

	| old |
	old := self currentSelectionState.
	currentSelection := aNode.
	currentSelection == self root
		ifTrue: [currentSelection := nil].
	self changedCurrentSelectionWithOld: old!

tree
	"Answer the receivers tree."

	^ tree!

tree: aTree
	"Set the receiver's tree to be aTree."

	tree := aTree.
	openedSet := IdentitySet new.
	openedSet add: tree.
	currentSelection := nil.!

treeAccessor
	"Answer the receiver's treeAccessor."

	^treeAccessor!

treeAccessor: aTreeAccessor
	"Set the receiver's treeAccessor to be aTreeAccessor."

	treeAccessor := aTreeAccessor! !

!TreeSelection methodsFor: 'tree accessor'!

childrenFor: aNode
	"Answer the children for node aNode."

	^treeAccessor childrenFor: aNode!

isLeaf: aNode
	"Answer whether aNode is a leaf."

	^treeAccessor isLeaf: aNode!

nameFor: aNode
	"Answer the name for node aNode."

	^treeAccessor nameFor: aNode!

root
	"Answer the root of the tree."

	^tree! !

!TreeSelection methodsFor: 'opened set accessing'!

addToOpenedSet: aCollection 
	"Add aCollection of elements to the receiver's set of traversable 
	children.  Do not notify dependents."

	aCollection == nil ifFalse: [openedSet addAll: aCollection]!

close: aChild 
	"Close aChild causing all of its children to be 'inaccessible'."

	openedSet remove: aChild ifAbsent: [^self].
	self changedOpenedSet!

closeCurrent
	"Close the currently selected child causing all of its children to be 
	'inaccessible'."

	currentSelection == nil ifTrue: [^self].
	self close: currentSelection!

deepCloseCurrent
	"Close the current tree element and any of its children."

	| sel |
	sel := self currentSelection.
	sel == nil
		ifTrue: [(self childrenFor: tree) do:
					[:node | self deepClose: node]]
		ifFalse: [self deepClose: sel].
	self changedOpenedSet!

deepOpenCurrent
	"Open the current tree element and any of its children."

	| sel |
	sel := self currentSelection.
	self deepOpen: ((sel == nil) ifTrue: [tree] ifFalse: [sel]).
	self changedOpenedSet!

isOpen: aChild 
	"Open aChild. This causes all of its children to be 'accessible'."

	^(openedSet includes: aChild)!

open: aChild 
	"Open aChild. This causes all of its children to be 'accessible'."

	(self isLeaf: aChild)
		ifFalse: 
			[(openedSet includes: aChild)
				ifFalse: [openedSet add: aChild.
						self changedOpenedSet]]!

openCurrent
	"Open the currently selected node causing all of its childern to be 'accessible'"

	currentSelection == nil
		ifTrue: [^self].
	self open: currentSelection!

openSetFor: aChild 
	"Answer the intersection of the opened set with the set of element 
	descendent from aChild that are in the opened set."
	
	| set |
	set := IdentitySet new.
	^(self isLeaf: aChild)
		ifTrue: [set]
		ifFalse: 
			[aChild withChildrenDo: 
				[:n | (self isOpen: n) ifTrue: [set add: n]].
			set]!

removedChild: aChild from: aParent 
	"Remove aChild from the opened set and remove aParent if aParent 
	now has no children."

	(openedSet includes: aChild)
		ifTrue: [aChild withChildrenDo: [:c | openedSet remove: c ifAbsent: []]].
	((openedSet includes: aParent) and: [aParent ~~ self root])
		ifTrue: [(self childrenFor: aParent) size = 0 ifTrue: [openedSet remove: aParent]].
	self changedOpenedSet!

removeFromOpenedSet: aCollection
	"Remove aCollection of nodes from the receivers opened set.
	Does not notify dependents."

	aCollection == nil
		ifFalse: [aCollection do: [:each | openedSet remove: each ifAbsent: []]]! !

!TreeSelection methodsFor: 'private: private'!

changedCurrentSelectionWithOld: oldSelectionState 
	"The current selection just changed. Do anything to respond including 
	telling dependents."

	self changed: #currentSelection with: oldSelectionState!

changedOpenedSet
	self changed: #openedSet!

currentSelectionState
	"Answer the receivers current selection."

	^currentSelection!

deepClose: aNode
	"Remove aNode and all children from the opened set."

	openedSet remove: aNode ifAbsent: [].
	(self childrenFor: aNode) do: 
		[:child | 
		self deepClose: child]!

deepOpen: aNode
	"Add aNode and all children to the opened set."

	openedSet add: aNode.
	(self childrenFor: aNode) do: 
		[:child | 
		self deepOpen: child]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TreeSelection class
	instanceVariableNames: ''!



!TreeSelection class methodsFor: 'instance creation'!

on: aTree
	"Create a new instance of the receiver on aTree."

	^self new tree: aTree! !