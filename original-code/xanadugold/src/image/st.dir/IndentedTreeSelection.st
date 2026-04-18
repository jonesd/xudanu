'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:59 pm'!

TreeSelection subclass: #IndentedTreeSelection
	instanceVariableNames: '
		selectionList {OrderedCollection of: String | Text}
		currentSelectionIndex {Integer}
		nonTerminalBolding {Boolean}
		lastTime {Integer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Tree'!
IndentedTreeSelection comment:
'Instances of this class represent protocol converters for accessing the structure of tree-type elements as indented lists.  (Note that if the tree should be shown as a digraph, another class is needed.)
Instance Variables:
	selectionList		<OrderedCollection> 	that contains a collection of strings representing the 
												depth first order traversal of the instance
	currentSelectionIndex 	<Integer> 			representing the number (relative to the selectionList) 
												of the currently selected item
	nonTerminalBolding		<Boolean>			true if the instance has children, the children are not 
												displayed, and the selection should be shown emphasized
'!



!IndentedTreeSelection methodsFor: 'accessing'!

nonTerminalBolding: aBoolean
	"Set the receiver's non terminal bolding to true or false."

	nonTerminalBolding := aBoolean!

openAndSelect: aChild 
	"Signal that a new list is necessary. Set the receiver's current 
	selection to be aChild."

	self openAllTo: aChild.
	self resetChild: aChild.!

resetChild: aChild 
	"Signal that a new list is necessary. Set the receiver's current 
	selection to be aChild."

	selectionList := nil.
	self changed: #list.
	self currentSelection: aChild!

tree: aTree
	"Set the receiver's tree to be aTree."

	super tree: aTree.
	currentSelectionIndex := 0.
	selectionList := nil.
	nonTerminalBolding := true.
	lastTime _ 0.! !

!IndentedTreeSelection methodsFor: 'tree list messages'!

list
	"Answer the receiver's indented list."

	selectionList == nil ifTrue: [self buildIndentedList].
	^selectionList!

listIndex
	"Answer the receiver`s indented list index."

	^currentSelectionIndex!

toggleListIndex: aNumber 
	"Change the receiver`s indented list index to be aNumber."

	| old | 
	currentSelectionIndex = nil ifTrue: [^self].
	old := self currentSelectionState.
	currentSelectionIndex := aNumber.
	aNumber = 0
		ifTrue: [currentSelection := nil]
		ifFalse: [currentSelection := 
					self findChildForIndex: currentSelectionIndex
						currentIndex: 0
						child: self root].
	self changed: #currentSelection with: old! !

!IndentedTreeSelection methodsFor: 'private: private'!

addChild: aChild indentLevel: indentLevel 
	"Add aChild to the the receiver's indented list at indentLevel."

	aChild == self root 
		ifFalse: [selectionList add: (self nameFor: aChild indentLevel: indentLevel)].
	(self isOpen: aChild)
		ifTrue: [(self childrenFor: aChild)
					do: [:child | self addChild: child indentLevel: indentLevel + 1]]!

addOpenChild: anOpenNode indentlevel: indentLevel 
	"Add anOpenNode to the receiver's indented list at indentLevel."

	| openChildren |
	selectionList add: (self nameFor: anOpenNode indentLevel: indentLevel).
	openChildren := self openChildrenFor: anOpenNode.
	openChildren do: [:child | self addOpenChild: child indentlevel: indentLevel + 1]!

buildIndentedList
	"Build the receiver's indented list."

	selectionList := OrderedCollection new.
	currentSelectionIndex := 0.
	self addChild: self root indentLevel: -1.!

changedCurrentSelectionWithOld: oldSelectionState
	"The current selection just changed. Reset selection indexes and 
	tell dependents."

	currentSelection == nil 
		ifTrue: [currentSelectionIndex := 0]
		ifFalse: [currentSelectionIndex := 
					self findIndexForChild: currentSelection
						currentIndex: 0
						child: self root.
				(currentSelectionIndex isMemberOf: Array)
					ifTrue: [currentSelectionIndex := currentSelectionIndex at: 1]
					ifFalse: [currentSelectionIndex := 0]].
	self changed: #listIndex with: oldSelectionState.
	super changedCurrentSelectionWithOld: oldSelectionState!

changedOpenedSet
	"Build the receiver's indented list starting at the current selection."

	| tmpSelection |
	tmpSelection := currentSelectionIndex.
	self buildIndentedList.
	currentSelectionIndex := tmpSelection.
	self changed: #list.
	super changedOpenedSet!

currentSelectionState
	"Answer the receiver's current selection and current selection index 
	in an Array."

	^Array with: currentSelectionIndex with: currentSelection!

findChildForIndex: aNumber currentIndex: cIndex child: aChild 
	"Answer the child associate with aNumber in the indented list."

	| tmp |
	cIndex >= aNumber ifTrue: [^aChild].
	(self isOpen: aChild) ifFalse: [^cIndex].
	tmp := cIndex.
	(self childrenFor: aChild)
		do: [:baby | 
			tmp := tmp + 1.
			tmp := self findChildForIndex: aNumber
						currentIndex: tmp
						child: baby.
			(tmp isMemberOf: SmallInteger)
				ifFalse: [^tmp]].
	^tmp!

findIndexForChild: aChild currentIndex: cIndex child: cChild
	"Answer the index in the indented list associated with aChild."

	| tmp children |
	cChild == aChild ifTrue: [^Array with: cIndex].
	(self isOpen: cChild) ifFalse: [^cIndex].
	tmp := cIndex.
	children := (self childrenFor: cChild).
	1 to: children size do:
			[:i | | baby |
			baby := children at: i.
			tmp := tmp + 1.
			tmp := self findIndexForChild: aChild
						currentIndex: tmp
						child: baby.
			(tmp isMemberOf: Array) ifTrue: [^tmp]].
	^tmp!

nameFor: child indentLevel: num
	"Answer a string for child with the proper level of indenting."
	
	| aStream |
	aStream := TextStream on: (Text new: 25).
	num timesRepeat: [aStream nextPut: Character space; space; space; space].
	(nonTerminalBolding == true and: [((openedSet includes: child) not) and: [(self isLeaf: child) not]])
		ifTrue: [aStream emphasis: 13]
		ifFalse: [aStream emphasis: 1].
	aStream nextPutAll: (self nameFor: child).
	^ aStream contents!

{void} openAllTo: aChild 
	"Signal that a new list is necessary. Set the receiver's current 
	selection to be aChild."

	| parent |
	parent _ aChild parent.
	(parent == nil or: [self isOpen: parent])
		ifTrue: [^VOID].
	self openAllTo: parent.
	self open: parent.! !