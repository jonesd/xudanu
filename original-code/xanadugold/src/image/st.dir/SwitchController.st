'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:53 pm'!

Controller subclass: #SwitchController
	instanceVariableNames: 'selector arguments cursor '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
SwitchController comment:
'A SwitchController coordinates the interaction of a Switch, a SwitchView, and input events (user actions, see class Sensor).  Instances own a message in the form of a selector and an array of arguments.  Whenever the Switch is selected, this message is sent to the Switch.

Instance Variables:
	selector	<Symbol>
	arguments	<Array>
	cursor	<Cursor> to be used when the cursor is inside the view of the receiver
'!


!SwitchController methodsFor: 'initialize-release'!

initialize
	super initialize.
	selector _ #switch.
	arguments _ Array new: 0! !

!SwitchController methodsFor: 'accessing'!

addArgument: aValue 
	"Add the argument, aValue, as one of the arguments of the message
	the receiver sends to its model."
	arguments _ arguments copyWith: aValue!

arguments
	"Answer the arguments the receiver sends in a message to its receiver."
	^arguments!

arguments: anArray
	"The argument, anArray, consists of the arguments of the message
	the receiver sends to its model."
	arguments _ anArray!

cursor: aCursor
	"Set aCursor to be the receiver's cursor."

	cursor _ aCursor!

selector
	"Answer the selector the receiver sends in a message to its receiver."
	^selector!

selector: aSymbol 
	"Set aSymbol to be the selector the receiver sends in a message to its model."
	selector _ aSymbol! !

!SwitchController methodsFor: 'basic control sequence'!

controlInitialize
	view indicatorReverse!

controlTerminate
	view indicatorReverse.
	self viewHasCursor ifTrue: [self sendMessage]!

idle
	"do nothing"!

sendMessage
	"The receiver consists of a selector and possibly of arguments that should be
	used to create a message to send to the receiver's model."
	arguments size = 0
		ifTrue: [model perform: selector]
		ifFalse: [model perform: selector withArguments: arguments]! !

!SwitchController methodsFor: 'control defaults'!

controlActivity
	^ self!

isControlActive
	^sensor anyButtonPressed & self viewHasCursor!

isControlWanted
	self viewHasCursor ifTrue: [cursor == nil ifFalse: [cursor show]].
	^self viewHasCursor & sensor redButtonPressed! !