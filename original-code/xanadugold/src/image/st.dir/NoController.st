'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:32 pm'!

Controller subclass: #NoController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Framework'!
NoController comment:
'Class NoController represents a controller that never wants control.  It is the controller for views that are non-interactive.'!


!NoController methodsFor: 'basic control sequence'!

startUp
	"I do nothing."
	^self! !

!NoController methodsFor: 'control defaults'!

isControlActive
	^false!

isControlWanted
	^false! !