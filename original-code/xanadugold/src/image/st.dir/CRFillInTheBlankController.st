'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:55 pm'!

FillInTheBlankController subclass: #CRFillInTheBlankController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Prompt/Confirm'!
CRFillInTheBlankController comment:
'Class CRFillinTheBlankController is a FillInTheBlankController that causes termination on a carriage return.'!


!CRFillInTheBlankController methodsFor: 'basic control sequence'!

controlInitialize
	startBlock _ paragraph characterBlockForIndex: startBlock stringIndex.
	stopBlock _ paragraph characterBlockForIndex: stopBlock stringIndex.
	self initializeSelection.
	beginTypeInBlock _ nil! !

!CRFillInTheBlankController methodsFor: 'stop conditions'!

cr: characterStream key: aChar
	"The carriage return was typed by the user.  This designates that the receiver should give up control."

	characterStream isEmpty ifFalse:
		[self replaceSelectionWith:
			(Text string: characterStream contents emphasis: emphasisHere)].
	self accept.
	^true!

indentedCR: characterStream key: aChar
	"The carriage return was typed by the user.  This designates that the receiver should give up control."

	characterStream isEmpty ifFalse:
		[self replaceSelectionWith:
			(Text string: characterStream contents emphasis: emphasisHere)].
	self accept.
	^true! !