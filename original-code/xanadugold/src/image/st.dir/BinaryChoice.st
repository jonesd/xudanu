'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:54 pm'!

Model subclass: #BinaryChoice
	instanceVariableNames: 'trueAction falseAction actionTaken '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Prompt/Confirm'!
BinaryChoice comment:
'Class BinaryChoice represents a true/false (yes/no) choice.  Its instances have two possible actions they can take, depending on which choice is made.

Instance variables
	trueAction		<BlockClosure>	sequence of expression to do if positive choice is made
	falseAction		<BlockClosure>	sequence of expression to do if negative choice is made
	actionTaken	<Boolean> was the action, true or false, already taken
 '!


!BinaryChoice methodsFor: 'initialize-release'!

falseAction: aBlock
	"The argument, aBlock, will be evaluated if the receiver is sent the
	message selectFalse."
	falseAction _ aBlock!

initialize
	"Initialize the receiver so that it indicates no action has yet been taken."
	actionTaken _ false!

trueAction: aBlock
	"The argument, aBlock, will be evaluated if the receiver is sent the
	message selectTrue."
	trueAction _ aBlock! !

!BinaryChoice methodsFor: 'menu messages'!

selectFalse
	"Take the action, if one, associated with selecting no or false."	
	actionTaken _ true.
	falseAction notNil ifTrue: [falseAction value]!

selectTrue
	"Take the action, if one, associated with selecting yes or true."	
	actionTaken _ true.
	trueAction notNil ifTrue: [trueAction value]! !

!BinaryChoice methodsFor: 'accessing'!

actionTaken
	"Answer whether the receiver has carried out its actions yet."
	^actionTaken!

active
	"Answer whether the receiver is an active system view."
	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BinaryChoice class
	instanceVariableNames: ''!


!BinaryChoice class methodsFor: 'instance creation'!

message: messageString 
	"Answer an instance of the receiver whose question is messageString.  If the user
	answer is yes, then return true.  If the user answer is no, return false.  
	Display the view of the instance at the cursor location."
	| answer |
	self
		message: messageString
		displayAt: Sensor cursorPoint
		centered: true
		ifTrue: [answer _ true]
		ifFalse: [answer _ false].
	^answer!

message: messageString displayAt: aPoint centered: centered ifTrue: trueAlternative ifFalse: falseAlternative
	"Answer an instance of the receiver whose question is messageString.  If the user
	answer is yes, then evaluate trueAlternative.  If the user answer is no,
	evaluate falseAlternative. If centered, a Boolean, is false, display the view of the
	instance at aPoint; otherwise display it with its center at aPoint."

	| newChoice |
	newChoice _ self new initialize.
	newChoice trueAction: trueAlternative.
	newChoice falseAction: falseAlternative.
	BinaryChoiceView openOn: newChoice message: messageString displayAt: aPoint centered: centered!

message: messageString displayAt: originPoint ifFalse: falseAlternative 
	"Answer an instance of the receiver whose question is messageString.  If the user
	answer is yes, then do nothing.  If the user answer is no, evaluate falseAlternative. 
	Display the view of the instance at originPoint."

	^self
		message: messageString
		displayAt: originPoint
		centered: false
		ifTrue: nil
		ifFalse: falseAlternative!

message: messageString displayAt: originPoint ifTrue: trueAlternative 
	"Answer an instance of the receiver whose question is messageString.  If the user
	answer is yes, then evaluate trueAlternative.  If the user answer is no,
	do nothing.  Display the view of the instance at originPoint."

	^self
		message: messageString
		displayAt: originPoint
		centered: false
		ifTrue: trueAlternative
		ifFalse: nil!

message: messageString displayAt: originPoint ifTrue: trueAlternative ifFalse: falseAlternative 
	"Answer an instance of the receiver whose question is messageString.  If the user
	answer is yes, then evaluate trueAlternative.  If the user answer is no,
	evaluate falseAlternative.  Display the view of the instance at originPoint."

	^self
		message: messageString
		displayAt: originPoint
		centered: false
		ifTrue: trueAlternative
		ifFalse: falseAlternative! !

!BinaryChoice class methodsFor: 'examples'!

example
	"Shows an example of a binary choice.  Press any mouse
	button.  The binary choice view will appear at the cursor
	location."
	"BinaryChoice example."

	BinaryChoice
		message: 'Are you happy?' 
		displayAt: Sensor waitButton 
		centered: true
		ifTrue: [Transcript cr; show: 'happy'] 
		ifFalse: [Transcript cr; show: 'not happy']! !