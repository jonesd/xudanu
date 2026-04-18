'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:36 pm'!

Controller subclass: #MouseMenuController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Support'!
MouseMenuController comment:
'A MouseMenuController is a Controller that modifies the scheduling of user activities so that the three mouse buttons can be used to make selections or display menus.  The menu items are unary messages to the value of sending an instance of class MouseMenuController the message menuMessageReceiver.'!



!MouseMenuController methodsFor: 'control defaults'!

controlActivity 
	sensor redButtonPressed & self viewHasCursor 
		ifTrue: [^self redButtonActivity].
	sensor yellowButtonPressed & self viewHasCursor 
		ifTrue: [^self yellowButtonActivity].
	sensor blueButtonPressed & self viewHasCursor 
		ifTrue: [^self blueButtonActivity].
	super controlActivity!

isControlActive
	^view containsPoint: sensor cursorPoint! !

!MouseMenuController methodsFor: 'menu messages'!

blueButtonActivity
	"Determine which item in the view button pop-up menu is selected.
	If one is selected, then send the corresponding message to the object
	designated as the menu message receiver."

	| index |
	self blueButtonMenu ~~ nil
		ifTrue: 
			[index _ self blueButtonMenu startUpBlueButton.
			(index ~= 0 and: [index ~~ nil]) ifTrue: 
				[self menuMessageReceiver perform: index]]
		ifFalse: [super controlActivity]!

{PopUpMenu} blueButtonMenu
	 
	^nil!

menuMessageReceiver
	"Answer the object that should be sent a message when a menu item is selected."
	^ self!

redButtonActivity
	"Determine which item in the select button menu is selected.
	If one is selected, then send the corresponding message to the object
	designated as the menu message receiver."

	super controlActivity!

yellowButtonActivity
	"Determine which item in the operate button menu is selected.
	If one is selected, then send the corresponding message to the object
	designated as the menu message receiver."

	| index |
	self yellowButtonMenu ~~ nil
		ifTrue: 
			[index _ self yellowButtonMenu startUpYellowButton.
			(index ~= 0 and: [index ~~ nil]) ifTrue: 
				[self menuMessageReceiver perform: index]]
		ifFalse: [super controlActivity]!

{PopUpMenu} yellowButtonMenu
	 
	^nil! !

!MouseMenuController methodsFor: 'smalltalk: passe'!

blueButtonMenu: aSystemMenu 
	"Initialize the pop-up menu that should appear when the user presses
	the select mouse button to be aSystemMenu."

	self passe!

redButtonMenu: aSystemMenu
	"Initialize the pop-up menu that should appear when the user presses
	the select mouse button to be aSystemMenu."

	self passe!

yellowButtonMenu: aSystemMenu 
	"Initialize the pop-up menu that should appear when the user presses
	the operate mouse button to be aSystemMenu."

	self passe! !

!MouseMenuController methodsFor: 'obsolete:'!

reset
	"Eliminate references to all mouse button menus."

	self hack. "doesn't do anything"! !