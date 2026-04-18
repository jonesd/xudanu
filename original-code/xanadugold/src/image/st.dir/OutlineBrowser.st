'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:57 pm'!

CollectionBrowser subclass: #OutlineBrowser
	instanceVariableNames: 'tree treeSelection '
	classVariableNames: 'PasteBuffer '
	poolDictionaries: ''
	category: 'Interface-Structures'!
OutlineBrowser comment:
'An instance of a OutlineBrowser is a CollectionBrowser for browsing and editing the structure of HierarchialCollections.
An OutlineBrowser represents an application that consists of a sophisticated hierarchical outline (like the table of contents of a book).
Instance Variables:
	tree			<Object>			any object for which a TreeAccessor can provide translation 
	treeSelection	<TreeSelection>		an object that remembers a current selection for the tree-like object
Class Variables:
	PasteBuffer		<Array>				collection element, index indicating whether to paste identity or a copy'!


!OutlineBrowser methodsFor: 'accessing'!

collection
	"Answer the tree that the receiver is browsing."

	^tree!

selectedValue
	"Answer the value of the receiver's current selection or nil if nothing 
	is selected."

	| selection |
	selection := self selected.
	^selection == nil
		ifTrue: [tree value]
		ifFalse: [selection value]!

selectionHolder
	"Answer receiver's treeSelection."

	^treeSelection!

tree: aTree 
	"Set the receiver's tree to be aTree."

	tree := aTree.
	treeSelection tree: aTree!

tree: aTree accessor: aTreeAccessor
	"Set the receiver's tree to be aTree. Access the tree with 
	aTreeAccessor."

	treeSelection := IndentedTreeSelection new.
	treeSelection treeAccessor: aTreeAccessor.
	treeSelection addDependent: self.
	self tree: aTree! !

!OutlineBrowser methodsFor: 'open set accessing'!

closeCurrent
	"Close the receiver's current selection."

	treeSelection closeCurrent!

deepCloseCurrent
	"Close the receivers current selection and all of its children."

	treeSelection deepCloseCurrent!

deepOpenCurrent
	"Open the receiver's current selection and all of its children."

	treeSelection deepOpenCurrent!

openCurrent
	"Open the receiver's current selection."

	treeSelection openCurrent! !

!OutlineBrowser methodsFor: 'changing'!

newLabel: aString
	"Sent by the user interface.  Change the key of the receiver's tree."

	tree key: aString.
	self noteModification! !

!OutlineBrowser methodsFor: 'menu messages'!

addAfter
	"Prompt the user for adding a new item to the outline. The item will 
	be added after the currently selected item at the same indent level."

	| newCategory |
	self changeRequest ifFalse: [^self].
	newCategory := FillInTheBlank request: 'New Outline Item' initialAnswer: ''.
	newCategory = '' ifTrue: [^self].
	self insertChildAfter:
		(self newFor: newCategory )
		withOpenedSet: nil!

addBefore
	"Prompt the user for adding a new item to the outline. The item will 
	be added before the currently selected item at the same indent level."

	|newCategory|
	self changeRequest ifFalse: [^self].
	newCategory := FillInTheBlank request: 'New Outline Item' initialAnswer: (''). 
	newCategory = '' ifTrue: [^self].
	self insertChildBefore:
		(self newFor: newCategory)
		withOpenedSet: nil!

addCategory
	"Prompt the user for adding a new item to the outline. The item will 
	be added at the end of the outline."

	| newCategory |
	self changeRequest ifFalse: [^self].
	newCategory := FillInTheBlank request: 'New Outline Item' initialAnswer: ''.
	newCategory = '' ifTrue: [^self].
	self insertCategory: newCategory!

addIndented
	"Prompt the user for adding a new item to the outline. The item will 
	be added before the currently selected item at the next indent level."

	|newCategory|
	self changeRequest ifFalse: [^self].
	newCategory := FillInTheBlank request: 'New Outline Item' initialAnswer: (''). 
	newCategory = '' ifTrue: [^self].
	self insertChild: (self newFor: newCategory )
		withOpenedSet: nil
.!

downLevel
	"Shift the indention of the currently selected item down one level in 
	the outline. This makes the item a subitem of the preceding item of 
	the outline."

	| current parent newParent index |
	current := self selectedChild.
	parent := self selectedChildParent.
	index := parent findIndexOfChild: current.
	index = 1 ifTrue: [^self].
	newParent := parent at: index - 1.
	parent removeChild: current.
	newParent addChild: current.
	treeSelection addToOpenedSet: (Array with: newParent).
	treeSelection resetChild: current.
	self noteModification!

renameCategory
	"Prompt the user for a new name and rename the selected item."

	| newCategory currentChild |
	self changeRequest ifFalse: [^self].
	currentChild := self selectedChild.
	newCategory := FillInTheBlank request: 'New item name' initialAnswer: currentChild name.
	newCategory = '' ifTrue: [^self].
	newCategory = currentChild name ifTrue: [^self].
	currentChild key: newCategory.
	treeSelection resetChild: currentChild.
	self noteModification!

selectionListMenu
	"Menu to use in manipulating an outline."
	"This is the standard smalltalk outline browser."

	self selected == nil
		ifTrue: [^PopUpMenu fromArray: #(
			('add'		addAfter		'')	"All are standard smalltalk.  -  See cxx outline browser for defs."
			('load'		load			'')
			('save'		save			'') )].
					
	^PopUpMenu fromArray: #(
		('add' (	
			('after'		addAfter		'')
			('before'	addBefore		'')
			('indented'	addIndented	'') ))
		(' paste' (
			('after'		pasteAfter		'')
			('before'	pasteBefore	'')
			('indented'	pasteIndented	'') ))
		-
		('expand'	openCurrent	'')
		('contract'	closeCurrent	'')
		-
		('level' (
			('up'		upLevel			'')
			('down'		downLevel		'') ))
		-
		('copy'		copyCurrent	'')
		('cut'		cut				'')
		('rename'	renameCategory '')
		-
		('load '		load			'')
		('save'		save			'') )!

upLevel
	"Shift the indention of the currently selected item up one level in 
	the outline (unless the item is already at the top). If this item is a 
	subitem, it basically is removed and inserted after the parent item, 
	at the same level as the parent."

	| current parent parentParent |
	current := self selectedChild.
	parent := self selectedChildParent.
	(current == tree or: [parent == tree])
		ifTrue: [^self].
	parentParent := self parentForChild: parent. 
	parent removeChild: current.
	parentParent addChild: current after: parent.
	parent isLeaf ifTrue: [treeSelection removeFromOpenedSet: (Array with: parent)].
	treeSelection resetChild: current.
	self noteModification.! !

!OutlineBrowser methodsFor: 'cut-copy-paste'!

copyCurrent
	"Place a copy of the currently selected item into the paste buffer."

	| current |
	current := self selectedChild.
	PasteBuffer := Array
					with: current
					with: (treeSelection openSetFor: current)
					with: 1!

cut
	"Remove the currently selected item and place it in the paste buffer."

	| current parent |
	self changeRequest ifFalse: [^self].
	current := self selectedChild.
	parent := self selectedChildParent.
	PasteBuffer := Array with: current with: (treeSelection openSetFor: current) with: 0.
	current == tree
		ifTrue: 
			[self tree: (self newFor: 'unnamed')]
		ifFalse: 
			[parent removeChild: self selectedChild.
			treeSelection removedChild: current from: parent.
			self currentChild: tree].
	self setValueEditorsValue: tree value.
	self noteModification!

pasteAfter
	"Add the item in the paste buffer after the currently selected item 
	at the same indent level."

	PasteBuffer == nil ifTrue: [^self].
	self checkPasteBuffer.
	self insertChildAfter: (PasteBuffer at: 1)
		withOpenedSet: (PasteBuffer at: 2)!

pasteBefore
	"Add the item in the paste buffer before the currently selected item 
	at the same indent level."

	PasteBuffer == nil ifTrue: [^self].
	self checkPasteBuffer.
	self insertChildBefore: (PasteBuffer at: 1)
		withOpenedSet: (PasteBuffer at: 2)!

pasteIndented
	"Add the item in the paste buffer after the currently selected item 
	at the next indent level."

	PasteBuffer == nil ifTrue: [^self].
	self checkPasteBuffer.
	self insertChild: (PasteBuffer at: 1)
		withOpenedSet: (PasteBuffer at: 2)! !

!OutlineBrowser methodsFor: 'storing-loading'!

loadedNewCollection: aCollection 
	"Additional structure has been retrieved. Insert it into the existing 
	structure after the current selection."

	self insertChildAfter: aCollection withOpenedSet: nil! !

!OutlineBrowser methodsFor: 'private: private'!

checkPasteBuffer
	"Sent by the paste operations, this method makes certain that the 
	first time a paste is done, that the actual structure is used. 
	Thereafter, multiple pastes creates copies."

	| tmp |
	PasteBuffer == nil ifTrue: [^self].
	PasteBuffer at: 3 put: (tmp := (PasteBuffer at: 3) + 1).
	tmp = 2 ifTrue: [PasteBuffer at: 1 put: ((PasteBuffer at: 1)
												copyAndReplaceInSet: (PasteBuffer at: 2))]!

currentChild: aChild
	"Set the receiver's currently selected child to be aChild."

	^treeSelection currentSelection: aChild!

insertChild: aChild withOpenedSet: aSet
	"Insert aChild in the receiver's outline."

	| selected |
	aChild == nil ifTrue: [^self].
	selected := self selectedChild.
	selected addChild: aChild.
	aSet isNil
		ifFalse: [treeSelection addToOpenedSet: aSet].
	(treeSelection isOpen: selected)
		ifFalse: [treeSelection openCurrent.
				self currentChild: selected.]
		ifTrue: [treeSelection resetChild: selected].
	self noteModification!

insertChildAfter: aChild withOpenedSet: aSet 
	"Insert aChild in the receiver's outline, after the currently 
	selected item."

	| selected parent|
Sensor leftShiftDown ifTrue: [self halt].
	aChild == nil ifTrue: [^self].
	selected := self selectedChild.
	parent := self selectedChildParent.
	selected == tree
		ifTrue: [selected addChild: aChild]
		ifFalse: [parent addChild: aChild after: selected].
	aSet isNil
		ifFalse: [treeSelection addToOpenedSet: aSet].
	treeSelection resetChild: selected.
	self noteModification!

insertChildBefore: aChild withOpenedSet: aSet
	"Insert aChild in the receiver's outline, before the currently 
	selected item."

	| selected parent |
	aChild == nil ifTrue: [^self].
	selected := self selectedChild.
	parent := self selectedChildParent.
	parent addChild: aChild before: selected.
	aSet isNil
		ifFalse: [treeSelection addToOpenedSet: aSet].
	treeSelection resetChild: selected.
	self noteModification!

newItemWithKey: newCategory value: newValue 
	"Answer an item with newCategory as the key and newValue 
	as the value."
	
	^AssociationTreeWithParent key: newCategory value: newValue!

parentForChild: aChild
	"Answer the parent of aChild."

	^aChild parent!

selectedChild
	"Answer the currently selected outline item--a subtree. If no item is 
	selected, answer the root of the outline."

	| aChild |
	aChild := self selected.
	^aChild == nil
		ifTrue: [tree]
		ifFalse: [aChild]!

selectedChildParent
	"Answer the currently selected outline item's parent--a subtree."

	^self selectedChild parent! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OutlineBrowser class
	instanceVariableNames: ''!


!OutlineBrowser class methodsFor: 'examples'!

none
	"See EnvironmentEditor for an example of using the ListBrowser. A 
	OutlineBrowser without a value editor linked to it is not interesting. 
	EnvironmentEditor supports values that are Environments and 
	provides an appropriate editor."! !

!OutlineBrowser class methodsFor: 'cleanup'!

cleanupGarbage
	"OutlineBrowser cleanupGarbage"

	PasteBuffer _ nil! !