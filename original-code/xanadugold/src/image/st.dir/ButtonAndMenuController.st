'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:02 pm'!

MouseMenuController subclass: #ButtonAndMenuController
	instanceVariableNames: '
		myButtonSelector {Symbol}
		myMenuSelector {Symbol}
		myMenuActionSelector {Symbol}
		wasRed {Boolean}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!



!ButtonAndMenuController methodsFor: 'accessing'!

button: button menu: menu action: action
	myButtonSelector _ button.
	myMenuSelector _ menu.
	myMenuActionSelector _ action.
	wasRed _ false! !

!ButtonAndMenuController methodsFor: 'menu messages'!

menuMessageReceiver
	"Answer the object that should be sent a message when a menu item is selected."
	^model!

redButtonActivity
	myButtonSelector ~~ nil ifTrue:
		[[Sensor redButtonPressed] whileTrue: [Processor yield. self idle].
		self viewHasCursor ifTrue:
			[model perform: myButtonSelector]]
	ifFalse:
		[myMenuSelector ~~ nil
			ifTrue: [self yellowButtonActivity]]!

yellowButtonActivity
	| index menu |
	(myMenuSelector == nil or: [(menu _ model perform: myMenuSelector) == nil]) ifTrue:
		[view flash.
		super controlActivity]
	ifFalse: 
		[index _ menu startUpYellowButton.
		index ~= 0  ifTrue:
			[model perform: myMenuActionSelector with: index]]! !

!ButtonAndMenuController methodsFor: 'control defaults'!

isControlActive
	^super isControlActive and: [Sensor blueButtonPressed not]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ButtonAndMenuController class
	instanceVariableNames: ''!



!ButtonAndMenuController class methodsFor: 'create'!

button: button menu: menu action: action
	^self new button: button menu: menu action: action!

on: model button: button
	^(self new button: button menu: nil action: nil) model: model; yourself!

on: model button: button menu: menu action: action
	^(self new button: button menu: menu action: action) model: model; yourself! !