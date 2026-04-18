'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:46 pm'!

TextEditor subclass: #StringHolderController
	instanceVariableNames: 'isLockingOn '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
StringHolderController comment:
'An instance of StringHolderController represents a ParagraphEditor for a single paragraph of text, omitting alignment commands.  It provides items in the operate button menu so that the text selection can be evaluated and so that the contents of the model can be stored or restored.
	doIt -- evaluate the text selection as an expression
	printIt -- same as doIt but insert a description of the result after the selection
	accept -- store the contents of the StringHolder into the model
	cancel -- store the contents of the model into the StringHolder

Instance Variables:
	isLockingOn		<Boolean> true if the view has been editted so that it should not
					be closed without warning the user. 

Class Variables:
	CodeYellowButtonMenu 	<PopUpMenu>
	CodeYellowButtonMessages <Array of: Symbols>'!


!StringHolderController methodsFor: 'initialize-release'!

initialize
	super initialize.
	isLockingOn _ true! !

!StringHolderController methodsFor: 'lock access'!

isLockingOff
	"Answer whether no unsaved modifications have been carried out using
	the receiver."
	^isLockingOn not!

isLockingOn
	"Answer whether unsaved modifications have been carried out using the receiver."
	^isLockingOn!

lockModel
	"If the receiver is lock, do so to the receiver's model."
	isLockingOn ifTrue: [model lock]!

turnLockingOff
	"Turn off the receiver's indication that it is locked."
	isLockingOn _ false!

turnLockingOn
	"Turn on the receiver's indication that it is locked."
	isLockingOn _ true!

unlockModel
	"If the receiver is locked, then the model probably is, but should not be, so
	unlock the model."
	isLockingOn ifTrue: [model unlock]! !

!StringHolderController methodsFor: 'menu messages'!

accept
	super accept.
	model contents: paragraph text.
	self unlockModel!

{NO_RETURN} auditionIt
	"Treat the current text selection as an expression; evaluate it"

	| result |
	self controlTerminate.
	result _ 
		model doItReceiver class evaluatorClass new
				evaluate: self selectionAsStream
				in: model doItContext
				to: model doItReceiver
				notifying: self
				ifFail: 
					[self controlInitialize.
					^#failedDoit].
	ChangeLog logDoItChanges: '
"---DOIT---"
' , self selection string.
	result audition: self selection string.!

browseIt
	"Treat the current text selection as an expression; evaluate it"

	| result |
	self controlTerminate.
	result _ 
		model doItReceiver class evaluatorClass new
				evaluate: self selectionAsStream
				in: model doItContext
				to: model doItReceiver
				notifying: self
				ifFail: 
					[self controlInitialize.
					^#failedDoit].
	ChangeLog logDoItChanges: '
"---DOIT---"
' , self selection string.
	result browseHierarchy!

cancel
	super cancel.
	self unlockModel!

doIt
	"Treat the current text selection as an expression; evaluate it"

	| result |
	self controlTerminate.
	result _ 
		model doItReceiver class evaluatorClass new
				evaluate: self selectionAsStream
				in: model doItContext
				to: model doItReceiver
				notifying: self
				ifFail: 
					[self controlInitialize.
					^#failedDoit].
	ChangeLog logDoItChanges: '
"---DOIT---"
' , self selection string.
	self controlInitialize.
	^result!

forkIt
	"Treat the current text selection as an expression; evaluate it in another 
	process."

	| receiver context sel |
	self controlTerminate.
	receiver _ model doItReceiver.
	context _ model doItContext.
	sel _ self selectionAsStream.
	Cursor execute show.
	Controller startBackgroundProcess.
	[receiver class evaluatorClass new
		evaluate: sel
		in: context
		receiver: receiver
		notifying: nil
		ifFail: [nil].
	Cursor normal show.
	Controller stopBackgroundProcess]
		forkAt: Processor userBackgroundPriority.
	ChangeLog logDoItChanges: '
"---DOIT---"
' , self selection string.
	self controlInitialize.
	^#forked!

inspectIt
	"Treat the current text selection as an expression; evaluate it"

	| result |
	self controlTerminate.
	result _ 
		model doItReceiver class evaluatorClass new
				evaluate: self selectionAsStream
				in: model doItContext
				to: model doItReceiver
				notifying: self
				ifFail: 
					[self controlInitialize.
					^#failedDoit].
	ChangeLog logDoItChanges: '
"---DOIT---"
' , self selection string.
	result inspect!

printIt
	"Treat the current text selection as an expression; evaluate it. Insert 
	the description of the result of evaluation after the selection and then make 
	this 
	description the new text selection."

	| result strm |
	result _ self doIt.
	result ~~ #failedDoit
		ifTrue: 
			[strm _ TextStream on: String new.
			strm space; print: result.
			self insertAndSelect: strm contents at: stopBlock stringIndex]! !

!StringHolderController methodsFor: 'model access'!

model: aModel
	super model: aModel.
	view displayContents == nil
		ifFalse: [self changeCompositor: view displayContents]! !

!StringHolderController methodsFor: 'editing'!

insertAndSelect: aString at: anInteger 
	self selectAt: anInteger. 
	self deselect.
	self replaceSelectionWith: ' ' asText , aString asText.
	self selectAndScroll! !

!StringHolderController methodsFor: 'private: private'!

afterSelectionInsertAndSelect: aString 
	self insertAndSelect: aString at: stopBlock stringIndex!

replaceSelectionWith: aText 
	super replaceSelectionWith: aText.
	self lockModel!

yellowButtonMenu
	^PopUpMenu standardTextMenu! !

!StringHolderController methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	self passe! !