'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:02 pm'!

CollectionBrowser subclass: #ListBrowser
	instanceVariableNames: 'list listSelection '
	classVariableNames: 'PasteBuffer '
	poolDictionaries: ''
	category: 'Framework-List'!
ListBrowser comment:
'An instance of a ListBrowser is a CollectionBrowser for browsing and editing the structure of SequencableCollections.
A ListBrowser represents an application that consists of a simple linear list (like a rolodex).
Instance Variables:
	list				<OrderedCollection>
	listSelection	<SequenceSelection>
Class Variables:
	PasteBuffer		<Array>		collection element, index indicating whether to paste identity or a copy
	'!


!ListBrowser methodsFor: 'accessing'!

collection
	"Answer the list that the receiver is browsing."

	^list!

list: aList 
	"Set the receiver's list to be aList."

	list := aList.
	listSelection sequence: aList.
	self setValueEditorsValue: nil!

list: aList accessor: aNameAccessor
	"Set the receiver's list to be aList. Access the list with 
	aNameAccessor."

	listSelection := SequenceSelection new.
	listSelection nameAccessor: aNameAccessor.
	listSelection addDependent: self.
	self list: aList!

selectionHolder
	"Answer receiver's listSelection."

	^listSelection! !

!ListBrowser methodsFor: 'menu messages'!

addAfter
	"Prompt the user for adding a new item to the list. The item will 
	be added after the currently selected item."

	| newCategory |
	self changeRequest ifFalse: [^self].
	newCategory := FillInTheBlank request: 'New Item' initialAnswer: ''.
	newCategory = '' ifTrue: [^self].
	self insertAfter: (self newFor: newCategory)!

addBefore
	"Prompt the user for adding a new item to the outline. The item will 
	be added before the currently selected item at the same indent 
	level."

	| newCategory |
	self changeRequest ifFalse: [^self].
	newCategory := FillInTheBlank request: 'New Outline Item' initialAnswer: ''.
	newCategory = '' ifTrue: [^self].
	self insertBefore: (self newFor: newCategory)!

renameCategory
	"Prompt the user for a new name and rename the selected item."

	| newCategory current |
	self changeRequest ifFalse: [^self].
	current := self selected.
	newCategory := FillInTheBlank request: 'New item name' initialAnswer: current key.
	newCategory = '' ifTrue: [^self].
	newCategory = current key ifTrue: [^self].
	current key: newCategory.
	listSelection resetItem: current.
	self noteModification!

selectionListMenu
	"Menu for the environment browser, which is some smalltalkism not used at Xanadu (except in screenplay)."

	self selected == nil
		ifTrue: [^PopUpMenu fromArray: #(
			('add'		addAfter		'')	"All are standard smalltalk."
			('load'		load			'')
			('save'		save			'') )].
			
	^PopUpMenu fromArray: #(
		('add' (	
			('after'		addAfter		'') 
			('before'	addBefore		'') ))
		('paste' (
			('after'		pasteAfter		'')
			('before'	pasteBefore	'') ))
		-
		('copy'		copyCurrent		'')
		('cut'		cut					'')
		('rename'	renameCategory	'')
		-
		('load'		load			'')
		('save'		save			'') )! !

!ListBrowser methodsFor: 'cut-copy-paste'!

copyCurrent
	"Place a copy of the currently selected item into the paste buffer."

	| current |
	current := self selected.
	current == nil ifTrue: [^self].
	PasteBuffer := Array with: current with: 1!

cut
	"Remove the currently selected item and place it in the paste buffer."

	| current |
	current := self selected.
	current == nil ifTrue: [^self].
	self changeRequest ifFalse: [^self].
	PasteBuffer := Array with: current with: 0.
	list removeAtIndex: listSelection listIndex.
	listSelection resetItem: nil.
	self setValueEditorsValue: nil.
	self noteModification!

pasteAfter
	"Add the item in the paste buffer after the currently selected item."

	PasteBuffer == nil ifTrue: [^self].
	self checkPasteBuffer.
	self insertAfter: (PasteBuffer at: 1)!

pasteBefore
	"Add the item in the paste buffer before the currently selected item."

	PasteBuffer == nil ifTrue: [^self].
	self checkPasteBuffer.
	self insertBefore: (PasteBuffer at: 1)! !

!ListBrowser methodsFor: 'storing-loading'!

loadedNewCollection: aCollection
	"Additional structure has been retrieved. Insert it into the existing 
	structure after the current selection."

	list addAll: aCollection.
	listSelection resetItem: self selected.! !

!ListBrowser methodsFor: 'private:'!

checkPasteBuffer
	"Sent by the paste operations, this method makes certain that the 
	first time a paste is done, that the actual structure is used. 
	Thereafter, multiple pastes creates copies."

	| tmp |
	PasteBuffer == nil ifTrue: [^self].
	PasteBuffer at: 2 put: (tmp := (PasteBuffer at: 2) + 1).
	tmp = 2 ifTrue: [PasteBuffer at: 1 put: (PasteBuffer at: 1) copy]!

insert: newItem
	"Insert newItem at the end of the receiver's list"

	| selected |
	list addLast: newItem.
	selected := self selected.
	selected == nil
		ifTrue: [listSelection resetList]
		ifFalse: [listSelection resetItem: selected]
	self noteModification!

insertAfter: newItem 
	"Insert newValue in the receiver's list, after the currently selected 
	item."

	| selected selectionIndex |
	selected := self selected.
	selected == nil
		ifTrue: 
			[list addLast: newItem.
			listSelection resetList]
		ifFalse: 
			[selectionIndex := listSelection listIndex.
			selectionIndex = list size
				ifTrue: [list addLast: newItem]
				ifFalse: [list add: newItem beforeIndex: selectionIndex + 1].
			listSelection resetItem: selected].
	listSelection resetItem: selected.
	self noteModification!

insertBefore: newItem 
	"Insert newItem in the receiver's list, before the currently selected 
	item."

	| selected selectionIndex |
	selected := self selected.
	selected == nil
		ifTrue: 
			[list addFirst: newItem.
			listSelection resetList]
		ifFalse: 
			[selectionIndex := listSelection listIndex.
			list add: newItem beforeIndex: selectionIndex.
			listSelection resetItem: selected].
	self noteModification!

newItemWithKey: newCategory value: newValue 
	"Answer an Association with newCategory as the key and newValue 
	as the value."

	^Association key: newCategory value: newValue! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListBrowser class
	instanceVariableNames: ''!


!ListBrowser class methodsFor: 'examples'!

none
	"See EnvironmentEditor for an example of using the ListBrowser. A 
	ListBrowser without a value editor linked to it is not interesting. 
	EnvironmentEditor supports values that are Environments and 
	provides an appropriate editor."! !