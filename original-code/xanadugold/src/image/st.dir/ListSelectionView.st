'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:03 pm'!

ListView subclass: #ListSelectionView
	instanceVariableNames: 'menuChannel changeRequestChannel '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-List'!
ListSelectionView comment:
'An instance of ListSelectionView is a special type of ListView that knows the object from which it receives its menu.  It also knows an object that manages change requests.
Instance Variables:
	menuChannel			<Object>	any object that understands the messages value and receiver, 
										typically a kind of MessageSend
	changeRequestChannel	<Object>	any object that understands the message value, typically a
										BlockClosure
	'!


!ListSelectionView methodsFor: 'accessing'!

changeRequestChannel: anObject 
	"Set the receiver's change request channel to be anObject. Note, 
	anObject must understand the message value."

	changeRequestChannel := anObject!

menuChannel: anObject 
	"Set the receiver`s menu channel to be anObject. Note, anObject 
	must understand the message value and receiver."

	menuChannel := anObject! !

!ListSelectionView methodsFor: 'controller access'!

defaultControllerClass
	"Answer the default controller class for the receiver."

	^ListSelectionController! !

!ListSelectionView methodsFor: 'displaying'!

display
	"Display the list of items after making sure that the list has been 
	obtained from the receiver's model."

	list == nil
		ifTrue: 
			[self list: self getList.
			self moveSelectionBox: self getListIndex].
	super display! !

!ListSelectionView methodsFor: 'adaptor'!

channelChangeRequest
	"Answer true or false as to whether the change channel wishes to 
	changed."

	^changeRequestChannel == nil
		ifTrue: [false]
		ifFalse: [changeRequestChannel value]!

getList
	"Answer the list to be displayed."

	^model list!

getListIndex
	"Answer the list index to be selected."

	^model listIndex!

menuMessageReceiver
	"Answer the object that is to receive a menu message.
	This makes the assumption that the receiver of the selection is the 
	same as the object holding the menu."

	^menuChannel receiver!

yellowButtonMenu
	"Answer a PopUpMenu or nil."

	menuChannel == nil ifTrue: [^nil].
	^ menuChannel value! !

!ListSelectionView methodsFor: 'updating'!

update: aSymbol with: aParameter from: anObject 
	"Some aspect of the receiver's model has changed. Update lists or 
	selections."

	aSymbol == #list
		ifTrue: [self displaySafe: [self repairAfterListChange]].
	aSymbol == #listIndex
		ifTrue: [self displaySafe: [self repairAfterSelection]]! !

!ListSelectionView methodsFor: 'private: private'!

repairAfterListChange
	"The receiver's list is no longer valid,  redisplay it."

	| sel |
	self list: self getList	.
	sel := self getListIndex.
	0 = sel
		ifTrue: [^self displayView].
	selection := sel.
	self selectionVisible
		ifFalse: [list repositionAt: self computeCompositionOrigin
					clippingBox: self clippingBox].
	self displayView!

repairAfterSelection
	"The receiver's selection is no longer valid,  redisplay it."

	| sel |
	sel := self getListIndex.
	selection = sel
		ifTrue: [self selectionVisible ifTrue: [^self]]
		ifFalse: [self deselect].
	selection := sel.
	self selectionVisible
		ifFalse: [list repositionAt: self computeCompositionOrigin clippingBox: self clippingBox.
				self displayView]
		ifTrue: [self displaySelectionBox]!

selectionVisible
	"Answer true if the receiver's selection is visible otherwise answer false."

	^selection > 0 and: [self selectionBox intersects: self clippingBox]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ListSelectionView class
	instanceVariableNames: ''!


!ListSelectionView class methodsFor: 'instance creation'!

on: aModel menuChannel: menuChannel changeRequestChannel: changeRequestChannel 
	"Create an instance of the receiver for the object aModel. Get the 
	translation for the menu messages from menuChannel. Broadcasting 
	changes comes via changeRequestChannel. aModel has to 
	understand the message list."

	| lv |
	lv := self new model: aModel.
	lv menuChannel: menuChannel.
	lv changeRequestChannel: changeRequestChannel.
	^lv! !