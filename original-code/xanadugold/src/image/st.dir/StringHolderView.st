'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:46 pm'!

View subclass: #StringHolderView
	instanceVariableNames: 'displayContents '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
StringHolderView comment:
'A StringHolderView represents a View of a String that is an aspect of a more structured object.  This String should not be changed by any editing unless the user issues the accept command.  Thus my instances provide a working copy of the String.  This copy is edited.  When the user issues the accept command, the String is copied from the working version;  or if the user issues the cancel command, the working version is restored from the String.  StringHolderController is the default controller.  It is initialized specially by passing the string viewed which is then converted to a Paragraph for editing.

Instance Variables:
	displayContents	<String> the working copy'!


!StringHolderView methodsFor: 'initialize-release'!

initialize
	super initialize.
	displayContents _ TextCompositor new.
	displayContents text: '' asText.
	self insideColor: Form white! !

!StringHolderView methodsFor: 'updating'!

update: aSymbol 
	self updateDisplayContents!

updateDisplayContents
	"Make the text that is displayed be the contents of the receiver's model."

	| contents |
	contents _ self getContents.
	displayContents string ~= contents
		ifTrue: 
			[self editString: contents.
			self displayView]!

updateRequest
	^ model isUnlocked or: 
			[(self confirm: 'Contents have not been saved.  Are you
certain that you want to close?')
				ifTrue: [model unlock. ^true]
				ifFalse: [^false]]! !

!StringHolderView methodsFor: 'controller access'!

defaultController
	"Answer the default controller for the receiver."

	^self defaultControllerClass newCompositor: displayContents!

defaultControllerClass
	"Answer the default controller class for the receiver."

	^StringHolderController!

displayContents
	"Answer the string contents of the receiver."

	^displayContents! !

!StringHolderView methodsFor: 'displaying'!

display
	"Show the contents of the receiver on the display screen."

	self isUnlocked
		ifTrue: [self positionDisplayContents].
	super display!

displayView
	self clearInside.
	(self controller isKindOf: TextEditor)
		ifTrue: [controller display]
		ifFalse: [displayContents display]!

positionDisplayContents
	"Presumably the text being displayed changed so that the wrapping box and clipping box should be reset."
	|displayBox translation|
	displayBox	_ self insetDisplayBox.
	displayBox extent = displayContents clippingRectangle extent
		ifTrue: [translation _  displayBox origin - displayContents clippingRectangle origin.
				displayContents clippingRectangle: displayBox.
				displayContents setCompositionRectangle: (displayContents compositionRectangle translateBy: translation)]
		ifFalse: [displayContents 
					recomposeIn: (displayBox insetBy: self paragraphInset)
					clippingBox: displayBox]! !

!StringHolderView methodsFor: 'model access'!

editString: aString 
	"The paragraph to be displayed is created from the characters in aString."

	displayContents _ TextCompositor
				withText: aString asText
				style: TextStyle default copy
				compositionRectangle: (self insetDisplayBox insetBy: self paragraphInset)
				clippingRectangle: self insetDisplayBox.
	(self controller isKindOf: TextEditor)
		ifTrue: [controller changeCompositor: displayContents]!

model: aLockedModel 
	super model: aLockedModel.
	self editString: self getContents! !

!StringHolderView methodsFor: 'deEmphasizing'!

deEmphasizeView
	(self controller isKindOf: TextEditor)
	 	ifTrue: [controller deselect]! !

!StringHolderView methodsFor: 'private: private'!

getContents
	^model contents!

paragraphInset
	"Answer the amount to inset the paragraph from the border"
	^6@0! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StringHolderView class
	instanceVariableNames: ''!


!StringHolderView class methodsFor: 'instance creation'!

container
	"Answer an instance of the receiver with a new instance of StringHolder as the model."
	^self container: StringHolder new!

container: aContainer 
	"Answer an instance of the receiver whose model is aContainer.  Give it a 2-dot border."

	| aCodeView |
	aCodeView _ self new model: aContainer.
	aCodeView borderWidth: 1.
	^aCodeView!

open
	"Create a scheduled view of a workspace on the screen."

	self open: StringHolder new label: 'Workspace'!

open: aStringHolder 
	"Create a scheduled view of the argument, aStringHolder, as viewed by an
	instance of me.  The view has label 'StringHolder'."

	self open: aStringHolder label: 'StringHolder'!

open: aStringHolder label: aString 
	"Create a StandardSystemView of the model, aStringHolder, as 
	viewed by an instance of the receiver. The label of the view is 
	aString."

	| aStringHolderView topView |
	aStringHolderView _ self container: aStringHolder.
	topView _ StandardSystemView new.
	topView borderWidth: 1.
	topView model: aStringHolderView model.
	topView addSubView: aStringHolderView.
	topView label: aString.
	topView minimumSize: 200 @ 150.
	topView icon: (Icon constantNamed: #default).
	topView controller open! !

!StringHolderView class methodsFor: 'workspace constants'!

openSystemWorkspace
	"Schedule a view of the system workspace."
	"StringHolderView openSystemWorkspace."

	self open: StringHolder workspace label: 'System Workspace'! !