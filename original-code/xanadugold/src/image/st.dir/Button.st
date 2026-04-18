'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:49 pm'!

Switch subclass: #Button
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
Button comment:
'A Button is a Switch that turns off automatically after being turned on, that is, it acts like a push-button switch.'!


!Button methodsFor: 'state'!

turnOff
	"Sets the state of the receiver to 'off'.  The off action of the receiver is not  
	executed."

	on _ false!

turnOn
	"The receiver remains in the 'off' state'."

	self doAction: onAction.
	self doAction: offAction! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Button class
	instanceVariableNames: ''!


!Button class methodsFor: 'instance creation'!

newOn
	self error: 'Buttons cannot be created in the on state'.
	^nil! !