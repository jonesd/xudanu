'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:44 pm'!

CodeView subclass: #OnlyWhenSelectedCodeView
	instanceVariableNames: 'selectionMsg '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
OnlyWhenSelectedCodeView comment:
'An OnlyWhenSelectedCodeView is a code view for an OnlyWhenSelectedCodeController.

Instance Variables:
	selectionMsg	<Symbol>'!


!OnlyWhenSelectedCodeView methodsFor: 'initialize-release'!

selectionMsg: selMsg
	"Set the message to be sent to get a new selection to be selMsg."

	selectionMsg _ selMsg! !

!OnlyWhenSelectedCodeView methodsFor: 'controller access'!

defaultControllerClass
	^OnlyWhenSelectedCodeController! !

!OnlyWhenSelectedCodeView methodsFor: 'control'!

isSelected
	^model perform: selectionMsg! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OnlyWhenSelectedCodeView class
	instanceVariableNames: ''!


!OnlyWhenSelectedCodeView class methodsFor: 'instance creation'!

on: anObject aspect: m1 change: m3 menu: m4 initialSelection: sel selection: selMsg
	"Create an instance viewing anObject.  See super method in TextView for full
	explanation.  initialSelection (if not nil) is a string which will be searched for,
	and then highlighted if found, whenever the viewed text changes."
	^(super on: anObject aspect: m1 change: m3 menu: m4) selectionMsg: selMsg! !