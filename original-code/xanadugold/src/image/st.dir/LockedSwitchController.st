'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:50 pm'!

SwitchController subclass: #LockedSwitchController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
LockedSwitchController comment:
'A LockedSwitchController is a SwitchController that will not take control if the model (a Switch) is locked.  As an indication, the view (a SwitchView) flashes.'!


!LockedSwitchController methodsFor: 'control defaults'!

isControlWanted
	model isLocked
		ifTrue: 
			[view flash.
			^false].
	^super isControlWanted! !