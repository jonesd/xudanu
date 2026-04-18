'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:47 pm'!

View subclass: #TextView
	instanceVariableNames: 'partMsg acceptMsg menuMsg '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
TextView comment:
'TextView is a "pluggable" view of text. The notion of pluggable views is an experiment in user interface design. The idea is to provide a view which can be plugged onto any object, rather than having to define a new subclass specific to every kind of object which needs to be viewed. The chief mechanism is a set of selectors, which can be thought of as an adaptor to convert the generic textView operations into model-specific operations (such as textMenu). See the protocol ''adaptor'' for use of the pluggable selectors. See the creation messages in the class for an explication of the various parameters. Browse senders of the creation messages in the class for examples in the system.'!


!TextView methodsFor: 'initialize-release'!

initialize
	super initialize.
	self insideColor: Form white!

newText: aText
	"Set aText to be the text model for the receiver."

	aText == nil ifTrue: [^ self newText: Text new].
	self controller paragraph text: aText.
	self controller paragraph lines at: 1 put: 1.
	self controller resetState! !

!TextView methodsFor: 'controller access'!

defaultControllerClass
	^ TextController! !

!TextView methodsFor: 'displaying'!

display
	"Show the text of the receiver on the display screen."

	self isUnlocked
		ifTrue: 
			[self controller
				wrappingBox: (self insetDisplayBox insetBy: 6 @ 0)
				clippingBox: self insetDisplayBox.
			(controller text isEmpty and: [controller textHasChanged not])
				ifTrue: [self newText: self getText]].
	super display!

displayView
	self clearInside.
	self controller display! !

!TextView methodsFor: 'updating'!

update: aSymbol
	| text |
	aSymbol == partMsg
		ifTrue:
			[text _ self getText.
			self controller text ~= text
				ifTrue: 
					[self newText: text.
					self displaySafe: [self displayView]]]!

updateRequest
	| cancel |
	self controller textHasChanged ifFalse: [^true].
	self topView isCollapsed
		ifFalse:
			[Display reverse: insetDisplayBox mask: Form gray.
	Display reverse: (insetDisplayBox insetBy: 4) mask: Form gray].
	cancel _ self confirm: 'The text showing has been altered.
Do you wish to discard those changes?'.
	self topView isCollapsed
		ifFalse:
			[Display reverse: insetDisplayBox mask: Form gray.
	Display reverse: (insetDisplayBox insetBy: 4) mask: Form gray].
	^ cancel! !

!TextView methodsFor: 'deEmphasizing'!

deEmphasizeView
	self controller deselect! !

!TextView methodsFor: 'emphasizing'!

emphasizeView
	self controller select! !

!TextView methodsFor: 'adaptor'!

accept: aText from: aController
	"Set new text of the receiver to be aText from the controller aController."

	acceptMsg == nil ifTrue: [self flash. ^ false].
	^ acceptMsg numArgs = 1
		ifTrue:  "one arg selectors get text only"
			[model perform: acceptMsg with: aText]
		ifFalse:  "two arg selectors get text and controller as well"
			[model perform: acceptMsg with: aText with: aController]!

getText
	"Answer the text model for the receiver."

	| text |
	partMsg == nil ifTrue: [^ Text new].
	text _ model perform: partMsg.
	text == nil ifTrue: [^ Text new].
	^ text!

yellowButtonMenu
	"Answer the menu to display when the operate button menu is 
	pressed."

	menuMsg == nil ifTrue: [^ nil].
	^ model perform: menuMsg! !

!TextView methodsFor: 'private: private'!

on: anObject aspect: m1 change: m3 menu: m4
	self model: anObject.
	partMsg _ m1.
	acceptMsg _ m3.
	menuMsg _ m4.
	self initialize!

paragraphInset
	"Answer the amount to inset the paragraph from the border"
	^6@0! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextView class
	instanceVariableNames: ''!


!TextView class methodsFor: 'instance creation'!

on: anObject aspect: aspectMsg change: changeMsg menu: menuMsg
	"Create a 'pluggable' (see class comment) textView viewing anObject.
	aspectMsg is sent to read the current text value in the model.
	It is also used as the changed: parameter for this view.
	changeMsg is sent to inform anObject of new text for the model.
	menuMsg is sent to read the operate button menu for this view."

	^ self new on: anObject aspect: aspectMsg change: changeMsg menu: menuMsg! !