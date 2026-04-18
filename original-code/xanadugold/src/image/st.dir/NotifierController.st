'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:08 pm'!

StandardSystemController subclass: #NotifierController
	instanceVariableNames: ''
	classVariableNames: 'RedIsYellow '
	poolDictionaries: ''
	category: 'Tools-Programming'!
NotifierController comment:
'A NotifierController is a kind of MouseMenuController that creates an operate button menu for proceeding an interrupted process or for creating and scheduling a debugger on the interrupted machine state.  It gives up control if a view button is pressed or if the cursor is not inside the view.

Class Variables:
	NotifierYellowButtonMenu	<PopUpMenu>	menu when operate button is pressed
	NotifierYellowButtonMessages <Array of: Symbols>	associated collection of messages
	RedIsYellow 	<Boolean>	true if select button should pop up operate button menu'!


!NotifierController methodsFor: 'initialize-release'! !

!NotifierController methodsFor: 'model access'!

yellowButtonMenu
	"Snother menu for bug notifier."
	"Intercept to possible enable spelling correction."

	model mayProceed ifFalse: 
		[^PopUpMenu fromArray: #(
			('debug'	debug		'') )].	"All are standard smalltalk."
		
	model interruptedContext selector == #doesNotUnderstand: ifTrue:
		[^PopUpMenu fromArray: #(
			('proceed'	proceed		'')
			('debug'	debug		'')
			-
			('correct'	correct		'') )].
			
	^PopUpMenu fromArray: #(
		('proceed'	proceed		'')	"All are standard smalltalk."
		('debug'	debug		'') )! !

!NotifierController methodsFor: 'private: private'! !

!NotifierController methodsFor: 'private: private-menu messages'!

correct
	"Attempt to correct the spelling of the not-understood message and resend."

	self controlTerminate.
	model correct: self.
	self controlInitialize!

debug
        "Open a Debugger on the receiver's model."

        self controlTerminate.
        view erase.
        Debugger openFullViewOn: model label: view label.
        self closeAndUnscheduleNoErase.
        Processor terminateActive!

proceed
	"Proceed execution of the receiver's model."
	self controlTerminate.
	model proceed.
	self controlInitialize!

redButtonActivity
	"If class variable is set, behave as a operate button, otherwise select."
	RedIsYellow ifTrue: [^self yellowButtonActivity].
	^super redButtonActivity! !

!NotifierController methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	"Menu for bug notifier."
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NotifierController class
	instanceVariableNames: ''!


!NotifierController class methodsFor: 'class initialization'!

initialize
	"Initialize the pop up menus for the receiver."

	RedIsYellow _ true.	"Default do not pop up menu on select button"

	"NotifierController initialize."! !

!NotifierController class methodsFor: 'accessing'!

redIsYellow
	"Answer whether select button will act as the operate button."

	^RedIsYellow!

redIsYellow: aBoolean
	"Set whether select button will act as the operate button."

	" NotifierController redIsYellow: true "

	RedIsYellow _ aBoolean! !

NotifierController initialize!
