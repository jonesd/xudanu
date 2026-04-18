'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:04 pm'!

Model subclass: #SequenceSelection
	instanceVariableNames: 'sequence nameAccessor selectionList currentSelectionIndex '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-List'!
SequenceSelection comment:
'An instance of SequenceSelection acts as a data structure for a structure that consists of any kind of objects as its elements.  It knows about
	making selections from a sequence and
	notifying dependents if a selection changes
The only protocol that an element of the sequence has to know is the one pre-stored in the nameAccessor.  In this sense, every element must respond to the same naming protocol.
Instance Variables:
	sequence		<SequenceableCollection>	some structure that is being manipulated or handled
	nameAccessor	<NameAccessor>			pathway for finding out the name of an element of the sequence
	selectionList	<Array>						a constructed view of the sequence
	currentSelectionIndex	<SmallInteger>		the index of the currently selected element of the sequence'!


!SequenceSelection methodsFor: 'accessing'!

currentSelection
	"Answer the currently selected element."

	^(currentSelectionIndex == 0 or: [currentSelectionIndex == nil])
		ifTrue: [nil]
		ifFalse: [sequence at: currentSelectionIndex]!

currentSelection: anObject
	"Set the receivers the currently selected element."

	| old |
	old := self currentSelectionState.
	currentSelectionIndex := self findIndexOf: anObject startingAt: self start.
	self changedCurrentSelectionWithOld: old!

nameAccessor
	"Answer the receivers nameAccessor."

	^nameAccessor!

nameAccessor: aNameAccessor
	"Set the receiver's nameAccessor to be aNameAccessor."

	nameAccessor := aNameAccessor!

resetItem: anObject 
	"Signal that a new list is necessary. Set the receiver's current 
	selection to be aChild."

	self resetList.
	self currentSelection: anObject!

resetList 
	"Signal that a new list is necessary."

	selectionList := nil.
	self changed: #list!

sequence
	"Answer the receiver's sequence."

	^sequence!

sequence: aSequencableCollection
	"Set the receiver's sequence to be aSequencableCollection."

	sequence := aSequencableCollection! !

!SequenceSelection methodsFor: 'list accessor'!

nameFor: anObject
	"Answer the name for anObject."

	^nameAccessor nameFor: anObject!

start
	"Answer the start element in list."

	^1! !

!SequenceSelection methodsFor: 'list messages'!

list
	"Answer the receiver's selection list."

	selectionList == nil ifTrue: [self buildList].
	^selectionList!

listIndex
	"Answer the receiver`s indented list index."

	^currentSelectionIndex == nil
		ifTrue: [0]
		ifFalse: [currentSelectionIndex]!

toggleListIndex: aNumber 
	"Change the receiver`s indented list index to be aNumber."

	| old |
	old := self currentSelectionState.
	currentSelectionIndex := aNumber.
	self changed: #currentSelection with: old! !

!SequenceSelection methodsFor: 'private: private'!

buildList
	"Build the receiver's selection list."

	selectionList := Array new: sequence size.
	1 to: sequence size do:
		[:index |
		selectionList at: index put: (self nameFor: (sequence at: index))]!

changedCurrentSelectionWithOld: oldSelectionState 
	"The current selection just changed. Do anything to respond including 
	telling dependents."

	self changed: #listIndex with: oldSelectionState.
	self changed: #currentSelection with: oldSelectionState!

currentSelectionState
	"Answer the receiver's current selection index."

	^currentSelectionIndex!

findIndexOf: anObject startingAt: startIndex
	startIndex to: sequence size do:
		[:index |
		(sequence at: index) == anObject
			ifTrue: [^index]].
	^0! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SequenceSelection class
	instanceVariableNames: ''!


!SequenceSelection class methodsFor: 'instance creation'!

on: aSequencableCollection
	"Create a new instance of the receiver on aSequencableCollection."

	^self new sequence: aSequencableCollection! !