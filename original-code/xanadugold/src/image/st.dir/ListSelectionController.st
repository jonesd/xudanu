'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:03 pm'!

ListController subclass: #ListSelectionController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-List'!
ListSelectionController comment:
'An Instance of ListSelectionController is a kind of ListController that has special channels for determining change requests and menu operations.'!


!ListSelectionController methodsFor: 'menu messages'!

menuMessageReceiver
	"Answer the object that should be sent a message when a menu item 
	is selected."

	^view menuMessageReceiver!

redButtonActivity
	"Determine which item in the list is selected. Send a message to the 
	model indicating the number of the selected item."

	| selectionMovement oldSelection trialSelection nextSelection |
	selectionMovement := false.
	oldSelection := view selection.
	[sensor redButtonPressed]
		whileTrue: 
			[trialSelection := view findSelection: sensor cursorPoint.
			trialSelection ~~ nil
				ifTrue: 
					[nextSelection := trialSelection.
					view moveSelectionBox: nextSelection.
					nextSelection ~= oldSelection ifTrue: [selectionMovement := true]]].
	nextSelection == nil ifTrue: [^self].
	nextSelection = oldSelection
		ifTrue: 
			[selectionMovement ifTrue: [^self].
			nextSelection := 0.
			view moveSelectionBox: nextSelection].
	view channelChangeRequest
		ifFalse: 
			[view moveSelectionBox: oldSelection.
			^view flash].
	self changeModelSelection: nextSelection!

yellowButtonActivity
	"Determine which item in the yellow button pop-up menu is selected.
	If one is selected, then send the corresponding message to the object
	designated as the menu message receiver."

	| index menu |
	menu := view yellowButtonMenu.
	menu == nil
		ifTrue:
			[view flash.
			super controlActivity]
		ifFalse: 
			[index := menu startUpYellowButton.
			index ~= 0 
				ifTrue:
					[self controlTerminate.
					self menuMessageReceiver perform: (menu selectorAt: index).
					self controlInitialize]]! !