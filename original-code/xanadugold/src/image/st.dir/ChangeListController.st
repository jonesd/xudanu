'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:23 pm'!

LockedListController subclass: #ChangeListController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Changes'!
ChangeListController comment:
'Class ChangeListController is the controller for ChangeListView, handling the list menu.

Class Variables:
	ChangeListYellowButtonMenu 		<PopUpMenu> menu that appears when the operate menu is pressed, operations on the list of changes
	ChangeListYellowButtonMessages  <PopUpMenu> messages associated with items in the ChangeListYellowButtonMenu'!


!ChangeListController methodsFor: 'initialize-release'! !

!ChangeListController methodsFor: 'scrolling'!

scrollView: anInteger
	| viewList maximumAmount minimumAmount amount |
	viewList _ view list.
	maximumAmount _
		viewList clippingRectangle top -
		viewList compositionRectangle top max: 0.
	minimumAmount _
		viewList clippingRectangle bottom -
		viewList compositionRectangle bottom min: 0.
	amount _
		(anInteger min: maximumAmount) max:
		minimumAmount.
	amount ~= 0
		ifTrue:
			[view deselect.
			viewList scrollBy: amount negated.
			view displaySelectionBox]! !

!ChangeListController methodsFor: 'private: private'!

changeLabel
	| superView |
	"This method accesses the label with a terrible kludge.  It would be better if the label were a view of its own, but there would still be problems."
	superView _ view superView.
	Display gray: superView labelDisplayBox.
	superView label: model listName.
	superView displayView!

changeModelSelection: anInteger 
	model toggleListIndex: anInteger!

getFile: aSymbol withPrompt: promptString do: actionBlock 
	"find out the file name"

	| fileName |
	fileName _ FillInTheBlank
		request: promptString
		initialAnswer: ''.
	fileName isEmpty
		ifFalse: 
			[Cursor wait showWhile:
				[actionBlock value: ((Filename named: fileName) perform: aSymbol)]]! !

!ChangeListController methodsFor: 'private: private-menu messages'!

browse
	"Create and schedule a list browser containing only the displayed items."
	self controlTerminate.
	model scheduleMessageBrowser.
	self controlInitialize!

check
	self controlTerminate.
	self checkWithSystem: false.
	self controlInitialize!

checkWithSystem
	self controlTerminate.
	self checkWithSystem: true.
	self controlInitialize!

copyView
	"Create and schedule a list browser containing only the displayed items that are not marked for removal.  Accessed by choosing the menu command clone."

	self controlTerminate.
	ChangeListView openOn: model filterCopy!

doAll
	self controlTerminate.
	self doFrom: 1.
	self controlInitialize!

doFrom: firstIndex
	"Reset selection each time through the loop, so that if an error occurs, the selection is left at the item which caused it."
	firstIndex to: model listSize do:
		[:index |
		(model hasRemoved: index)
			ifFalse:
				[model toggleListIndex: index.
				model doThis: index]]!

doThis
	self controlTerminate.
	model doThis.
	self controlInitialize!

forget
	self controlTerminate.
	Cursor execute showWhile: [model forget].
	self controlInitialize!

getChanges
	self controlTerminate.
	model addChangeSet: Smalltalk changes.
	self controlInitialize!

recover
	self controlTerminate.
	model recoverFile: (SourceFiles at: 2).
	self changeLabel.
	self controlInitialize!

removeAll
	self controlTerminate.
	view deselect.
	model removeAll.
	view displaySelectionBox.
	self controlInitialize!

restoreAll
	view deselect.
	model restoreAll.
	view displaySelectionBox!

restoreItem
	view deselect.
	model restoreCurrent.
	view displaySelectionBox! !

!ChangeListController methodsFor: 'menu messages'!

checkWithSystem: aBoolean 
	self
		getFile: #writeStream
		withPrompt: 'type name of file on which to write conflicts'
		do: 
			[:aFile | 
			[Cursor execute showWhile: [model checkWithSystem: aBoolean].
			Cursor write showWhile: [model reportConflictsOn: aFile]]
				valueNowOrOnUnwindDo: [aFile close]]!

doFrom: firstIndex to: lastIndex
	"Reset selection each time through the loop, so that if an error occurs, the selection is left at the item which caused it."
	firstIndex to: (model listSize min: lastIndex) do:
		[:index |
		(model hasRemoved: index)
			ifFalse:
				[model toggleListIndex: index.
				model doThis: index]]!

doPrevious
	self controlTerminate.
	self doFrom: 1 to: model listIndex - 1.
	self controlInitialize!

fileIn
	self controlTerminate.
	self
		getFile: #readStream
		withPrompt: 'type name of file for reading'
		do: 
			[:aFile | 
			[model scanFile: aFile]
				valueNowOrOnUnwindDo: [aFile close]].
	self controlInitialize!

fileOut
	self controlTerminate.
	self
		getFile: #writeStream
		withPrompt: 'type name of file for writing'
		do: 
			[:aFile | 
			[model fileOutOn: aFile]
				valueNowOrOnUnwindDo: [aFile close]].
	self controlInitialize!

removeItem
	view deselect.
	model removeCurrent.
	view displaySelectionBox!

removePrevious
	self controlTerminate.
	view deselect.
	model removePrevious.
	view displaySelectionBox.
	self controlInitialize!

restorePrevious
	view deselect.
	model restorePrevious.
	view displaySelectionBox! !

!ChangeListController methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	"Menu for ChangeListController (from system transcript).  Supports smalltalk version of change management, supplanted for Xanadu by homebrew."

	self passe! !

!ChangeListController methodsFor: 'private'!

yellowButtonMenu
	"Menu for ChangeListController (from system transcript).  Supports smalltalk version of change management, supplanted for Xanadu by homebrew."

	^PopUpMenu fromArray: #(
		('file in'					fileIn				'ST: ')	"All are standard smalltalk."
		('file out'				fileOut				'ST: ')
		('recover last changes'	recover				'ST: ')
		('display system changes'	getChanges		'ST: ')
		-
		('do all'					doAll				'ST: ')
		('remove all'			removeAll			'ST: ')
		('restore all'			restoreAll			'ST: ')
		('spawn all'				copyView			'ST: ')
		-
		('forget'				forget				'ST: ')
		-
		('do it'					doThis				'ST: ')
		('remove it'				removeItem			'ST: ')
		('restore it'				restoreItem			'ST: ')
		('spawn it'				browse				'ST: ')
		-
		('check conflicts'		check				'ST: ')
		('check with system'	checkWithSystem	 'ST: ') ).! !