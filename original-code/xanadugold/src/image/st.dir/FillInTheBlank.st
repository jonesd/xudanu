'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:55 pm'!

StringHolder subclass: #FillInTheBlank
	instanceVariableNames: 'actionBlock actionTaken '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Prompt/Confirm'!
FillInTheBlank comment:
'Class FillinTheBlank represents a request for information that will be applied as the argument of a block of actions.

Instance Variables:
	actionBlock	<BlockClosure>
	actionTaken <Boolean> whether the actionBlock has been evaluated at least once
'!


!FillInTheBlank methodsFor: 'initialize-release'!

initialize
	super initialize.
	actionTaken _ false! !

!FillInTheBlank methodsFor: 'accessing'!

action: aBlock
	"The argument, aBlock, will be evaluated when the receiver is sent the
	message selectAction."
	actionBlock _ aBlock!

actionTaken
	"Answer whether the action has been taken at least once."

	^actionTaken!

setAction: aBoolean
	"Set whether this receiver's action has been taken at least once to be aBoolean."

	actionTaken _ aBoolean! !

!FillInTheBlank methodsFor: 'menu messages'!

selectAction
	"Evaluate the receiver's assigned action block, if any, with the answer as the
	block argument."
	actionBlock notNil ifTrue: [actionBlock value: contents]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FillInTheBlank class
	instanceVariableNames: ''!


!FillInTheBlank class methodsFor: 'instance creation'!

action: aBlock initialAnswer: aString 
	"Answer an instance of the receiver whose action is aBlock and initial action argument is
	aString."
	| newBlank |
	newBlank _ self new initialize.
	newBlank action: aBlock.
	newBlank contents: aString.
	^newBlank!

message: messageString displayAt: aPoint centered: centered action: aBlock initialAnswer: aString 
	"Answer an instance of the receiver whose question is messageString.  Once the 
	user provides an answer, then evaluate aBlock. If centered, a Boolean, is 
	false, display the view of the instance at aPoint; otherwise display it with its center
	at aPoint. "

	| newBlank |
	newBlank _ self new initialize.
	newBlank action: aBlock.
	newBlank contents: aString.
	FillInTheBlankView
		openOn: newBlank
		message: messageString
		displayAt: aPoint
		centered: centered!

request: messageString
	"Create an instance of the receiver whose question is messageString.
	Display it centered around the cursor.
	Simply return whatever the user accepts."

	^self request: messageString initialAnswer: ''!

request: messageString displayAt: aPoint centered: centered action: aBlock initialAnswer: aString 
	"Answer an instance of the receiver whose question is messageString 
	and initial answer is aString. Once the user provides an answer, 
	then evaluate aBlock. If centered, a Boolean, is false, display the 
	view of the instance at aPoint; otherwise display it with its center 
	at aPoint."

	^self
		request: messageString
		displayAt: aPoint
		centered: centered
		action: aBlock
		initialAnswer: aString
		useCRController: true!

request: messageString displayAt: aPoint centered: centered action: aBlock initialAnswer: aString useCRController: useCRController 
	"Answer an instance of the receiver whose question is 
	messageString. Once the user provides an answer, then evaluate 
	aBlock. If centered, a Boolean, is false, display the view of the 
	instance at aPoint; otherwise display it with its center at aPoint."

	| newBlank fillInView savedArea |
	newBlank _ self new initialize.
	newBlank action: aBlock.
	newBlank contents: aString.
	fillInView _ FillInTheBlankView
				on: newBlank
				message: messageString
				displayAt: aPoint
				centered: centered
				useCRController: useCRController.
	savedArea _ Form fromDisplay: fillInView displayBox.
	fillInView display.
	fillInView controller centerCursorInView.
	fillInView controller startUp.
	fillInView release.
	savedArea displayOn: Display at: fillInView viewport topLeft!

request: messageString initialAnswer: aString 
	"Create an instance of the receiver whose question is messageString. 
	Display it centered around the cursor. Supply aString as an initial 
	answer. Simply return whatever the user accepts."

	| response |
	self
		request: messageString
		displayAt: Sensor cursorPoint
		centered: true
		action: [:resp | response _ resp]
		initialAnswer: aString.
	^response! !

!FillInTheBlank class methodsFor: 'examples'!

example1
	"Example waits for you to click select button somewhere on the screen. The
	view will show where you point.  Terminate by choosing menu command accept."

	FillInTheBlank
		message: 'What is your name?' 
		displayAt: Sensor waitButton 
		centered: true
		action: [:answer | Transcript cr; show: answer] 
		initialAnswer: ''

	"FillInTheBlank example1."!

example2
	"Example waits for you to click select button somewhere on the screen. The
	view will show where you point.  Terminate by choosing menu command accept or
	typing carriage return."

	FillInTheBlank
		request: 'What is your name?' 
		displayAt: Sensor waitButton 
		centered: true
		action: [:answer | Transcript cr; show: answer] 
		initialAnswer: ''

	"FillInTheBlank example2."!

example3
	"Try this example by choosing menu command print it"

	^Text fromUser

	"FillInTheBlank example3."! !