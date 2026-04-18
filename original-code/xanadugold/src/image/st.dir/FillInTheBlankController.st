'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:55 pm'!

StringHolderController subclass: #FillInTheBlankController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Prompt/Confirm'!
FillInTheBlankController comment:
'Class FillinTheBlankController is a StringHolderController for a FillInTheBlankView.  The string is information that the user can type in and edit.  Upon issuing the accept command, this information is used by the model in the evaluation of an action block.'!


!FillInTheBlankController methodsFor: 'basic control sequence'!

controlTerminate
	| topController |
	super controlTerminate.
	model actionTaken ifFalse: [^self].
	topController _ view topView controller.
	(topController notNil & (topController isKindOf: StandardSystemController))
		ifTrue: [topController close].
	model selectAction! !

!FillInTheBlankController methodsFor: 'control defaults'!

isControlActive
	model actionTaken ifTrue: [^false].
	^super isControlActive!

isControlWanted
	model actionTaken ifTrue: [^false].
	^super isControlActive! !

!FillInTheBlankController methodsFor: 'menu messages'!

accept
	super accept.
	model setAction: true! !

!FillInTheBlankController methodsFor: 'initialize-release'!

resetState
	"intercept to force selection of entire text"

	super resetState.
	stopBlock stringIndex: paragraph text size + 1! !

!FillInTheBlankController methodsFor: 'marker adjustment'!

updateMarker
	"Do not redisplay marker"

	^self computeMarkerRegion! !

!FillInTheBlankController methodsFor: 'private: private'!

yellowButtonMenu
	"Menu for fillInTheBlank prompting box text editor."
	
	^PopUpMenu codeMenu: PopUpMenu tags, #(accept)! !

!FillInTheBlankController methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	"Menu for fillInTheBlank prompting box text editor."
	
	self passe! !