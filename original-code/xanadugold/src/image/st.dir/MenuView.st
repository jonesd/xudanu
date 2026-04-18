'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:40 pm'!

View subclass: #MenuView
	instanceVariableNames: 'myMenu partMsg initialSelectionMsg changeMsg listMsg menuMsg '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Lists'!


!MenuView methodsFor: 'adaptor'!

changeModelSelection: anInteger
	"Reset the selected item/model to be the item at location anInteger in the list."

	"changeMsg ~~ nil ifTrue:
		[model perform: changeMsg with:
			(anInteger = 0 ifTrue: [nil] ifFalse: [itemList at: anInteger])]"
	self unimplemented!

getList 
	"Answer the list to be displayed."

	| item |
	oneItem ifTrue:
		[item _ self initialSelection.
		item == nil ifTrue: [^ nil].
		^ Array with: item].
	listMsg == nil ifTrue: [^nil].
	^ model perform: listMsg!

initialSelection
	"Set the initial item to be selected."

	initialSelectionMsg == nil ifTrue: [^ nil].
	^ model perform: initialSelectionMsg!

yellowButtonMenu
	"Answer the menu to display when the operate button menu is 
	pressed."

	menuMsg == nil ifTrue: [^nil].
	^model perform: menuMsg! !

!MenuView methodsFor: 'controller access'!

defaultControllerClass
	^ SelectionInListController! !

!MenuView methodsFor: 'updating'!

update: aSymbol 
	aSymbol == partMsg
		ifTrue: [self list: self getList.
			self topView isCollapsed ifFalse: [self displaySafe: [self displayView]]].
	aSymbol == #empty
		ifTrue: [self resetAndDisplayView]! !

!MenuView methodsFor: 'displaying'!

displayView
	self unimplemented.
	"isEmpty
		ifTrue: [self clearInside]
		ifFalse: [super displayView]"! !

!MenuView methodsFor: 'testing'!

isEmpty
	"Answer whether the receiver contains any elements."

	"^ isEmpty"
	self unimplemented.
	^ nil! !

!MenuView methodsFor: 'initialize-release'!

on: anObject aspect: m1 change: m3 list: m4 menu: m5 initialSelection: m6
	"Set the instance variables for the receiver."

	self model: anObject.
	partMsg _ m1.
	changeMsg _ m3.
	listMsg _ m4.
	menuMsg _ m5.
	initialSelectionMsg _ m6.
	self list: self getList! !

!MenuView methodsFor: 'list access'!

list: anArray 
	"Set the receiver's list to be anArray. "

	| item theList list selection |
	anArray == nil
		ifTrue:  
			[myMenu _ nil.
			^self changeModelSelection: 0].
	theList _ anArray collect: 
		[:each || strm |
		strm _ TextStream on: (String new: 20).
		strm print: each.
		strm contents].
	list _ TextList onList: theList.
	item _ self initialSelection.
	selection _ item == nil
				ifTrue: [0]
				ifFalse: [theList findFirst: [:x | x = item]].
	self positionList.
	self changeModelSelection: selection! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MenuView class
	instanceVariableNames: ''!


!MenuView class methodsFor: 'instance creation'!

on: anObject
	aspect: aspectMsg change: changeMsg list: listMsg menu: menuMsg initialSelection: sel
	"Create a 'pluggable' listView viewing anObject.
	aspectMsg is sent to read the value of the current selection.
		It is also used as the changed: parameter for this view.
	changeMsg is sent to inform anObject of a new selection.
	listMsg is sent to read the current list which should be displayed.
	menuMsg is sent to read the yellowButton menu for this view.
	initialSelection is sent to read a selection to be selected initailly as a default."

	^self new on: anObject 
		aspect: aspectMsg 
		change: changeMsg 
		list: listMsg 
		menu: menuMsg 
		initialSelection: sel! !