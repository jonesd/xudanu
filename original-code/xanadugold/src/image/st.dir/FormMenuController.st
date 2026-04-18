'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:16 pm'!

Controller subclass: #FormMenuController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Form editing'!
FormMenuController comment:
'Class FormMenuController is a subclass of Controller that adds keyboard mapping to the menu selection.'!


!FormMenuController methodsFor: 'control defaults'!

controlActivity
	"Pass control to a subView corresponding to a pressed keyboard key or to a mouse
	button pressed, if any."

	sensor keyboardPressed
		ifTrue: [self processMenuKey]
		ifFalse: [self controlToNextLevel]!

idle
	"do nothing"!

isControlActive
	"Answer false if the blue mouse button is pressed and the cursor is outside of 
	the inset display box of the Controller's view;  answer true, otherwise."

	^sensor keyboardPressed |
		(view containsPoint: sensor cursorPoint) & sensor blueButtonPressed not!

isControlWanted
	"Answer true if the cursor is inside the inset display box (see 
	View|insetDisplayBox) of the receiver's view, and answer false, 
	otherwise. It is sent by Controller|controlNextLevel in order to determine 
	whether or not control should be passed to this receiver from the Controller of 
	the superView of this receiver's view."

	^sensor keyboardPressed | self viewHasCursor!

processMenuKey
	"The user typed a key on the keyboard.  Give control to the subView that
	is selected by this key."

	| aView |
	aView _ view subViewContainingCharacter: sensor keyboard.
	aView ~~ nil
		ifTrue: [aView controller sendMessage]! !