'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:08 pm'!

StandardSystemView subclass: #NotifierView
	instanceVariableNames: 'contents '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Programming'!
NotifierView comment:
'A NotifierView is a view of interrupted machine state.  The interruption occurred in order to notify the user that some action to be taken is dangerous, perhaps because it is not recoverable. It contains one subView in which the notification information is displayed.  The default controller is NotifierController.

Instance Variables:
	contents	 <String> the notification information'!


!NotifierView methodsFor: 'initialize-release'!

initialize
	super initialize.
	self insideColor: Form white! !

!NotifierView methodsFor: 'accessing'!

contents
	"Answer the information displayed in the receiver."

	^contents!

contents: aString 
	"Set aString to be the information that is displayed in the receiver."

	contents _ aString asParagraph.
	self centerContents! !

!NotifierView methodsFor: 'controller access'!

defaultControllerClass
	^NotifierController! !

!NotifierView methodsFor: 'window access'!

defaultWindow
	(contents == nil or: [self isCollapsed])
		ifTrue: [^super defaultWindow]
		ifFalse: [^contents boundingBox expandBy: 6]!

window: aWindow 
	super window: aWindow.
	self centerContents! !

!NotifierView methodsFor: 'displaying'!

displayView

	self isCollapsed
		ifFalse: [contents
					displayOn: Display
					transformation: self displayTransformation
					clippingBox: self insetDisplayBox
					fixedPoint: contents boundingBox center].
	super displayView! !

!NotifierView methodsFor: 'private: private'!

centerContents
	contents ~~ nil
		ifTrue: 
			[contents
				align: contents boundingBox center
				with: self getWindow center]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NotifierView class
	instanceVariableNames: ''!


!NotifierView class methodsFor: 'instance creation'!

openContext: haltContext label: aString contents: contentsString proceedable: aBoolean
	"Create and schedule an instance of me viewing a Debugger on haltContext.
	The view will be labeled with aString, and shows a short sender stack."

	| displayPoint |
	ErrorRecursion
		ifTrue: 
			[ErrorRecursion _ false.
			self primitiveError: aString].
	ErrorRecursion _ true.
	"Make sure that controllers without views are removed"
	ScheduledControllers removeInvalidControllers.
	displayPoint _ 
		(ScheduledControllers activeControllerProcess ~~ Processor activeProcess
			or: [ScheduledControllers activeController == nil])
			ifTrue: [Display boundingBox center]
			ifFalse: [ScheduledControllers activeController view displayBox center].
	ScrollController haltScrollBar.
	ScheduledControllers saveActiveViewsBits.
	self openDebugger: (Debugger context: haltContext proceedable: aBoolean)
		contents: contentsString
		label: aString
		displayAt: displayPoint.
	ErrorRecursion _ false.
	thisContext unwindUpTo: haltContext.
	Processor activeProcess suspend!

openException: exception
	"Create and schedule an instance of me viewing a Debugger on haltContext.
	The view will be labeled with aString, and shows a short sender stack."

	| displayPoint isInterrupt |
	ErrorRecursion
		ifTrue: 
			[ErrorRecursion _ false.
			self primitiveError: exception errorString].
	ErrorRecursion _ true.
	"Make sure that controllers without views are removed"
	ScheduledControllers removeInvalidControllers.
	displayPoint _ 
		(ScheduledControllers activeControllerProcess ~~ Processor activeProcess
			or: [ScheduledControllers activeController == nil])
			ifTrue: [Display boundingBox center]
			ifFalse: [ScheduledControllers activeController view displayBox center].
	ScrollController haltScrollBar.
	ScheduledControllers saveActiveViewsBits.
	isInterrupt _ exception initialContext method homeMethod ==
					(ControlManager compiledMethodAt: #interruptName:).
	self openDebugger: (Debugger new
					process: Processor activeProcess
					context: exception parameter
					interrupted: isInterrupt
					proceedable: exception willProceed)
		contents: exception parameter shortStack
		label: exception errorString
		displayAt: displayPoint.
	ErrorRecursion _ false.
	thisContext unwindUpTo: exception parameter.
	Processor activeProcess suspend! !

!NotifierView class methodsFor: 'private: private'!

openDebugger: aDebugger contents: aString1 label: aString2 displayAt: aPoint   
	| notifierView |
	Cursor normal show.
	Cursor cursorLink: true.
	notifierView _ self new model: aDebugger. 
	notifierView contents: aString1.
	notifierView label: aString2. 
	notifierView borderWidth: 2.
	notifierView 
		minimumSize: notifierView defaultWindow width 
						@ notifierView defaultWindow height.
	notifierView controller openNoTerminateDisplayAt: aPoint.
	^notifierView! !