'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:35 pm'!

MouseMenuController subclass: #IconController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Support'!
IconController comment:
'Class IconController represents the default controller for an IconView.

Class Variables:
	IconYellowButtonMenu	<PopUpMenu>
	IconYellowButtonMessages <Array of: Symbols>'!


!IconController methodsFor: 'initialize-release'!

yellowButtonMenu
	"Menu for yellow button on anything collapsed to an icon."

	^PopUpMenu fromArray: #(
		('expand'	expand		'') )! !

!IconController methodsFor: 'control defaults'!

isControlActive
	"Return whether I still want control."

	^super isControlActive and: [self mouseDetect and: [sensor blueButtonPressed not and: [ view topView ~~ view ]]]!

isControlWanted
	"Return whether I want control."

	^super isControlWanted and: [self mouseDetect]!

redButtonActivity
	"Red button click in the icon expands."

	view topView controller expand! !

!IconController methodsFor: 'menu messages'!

expand
	"Have the real controller restore."

	view topView controller expand! !

!IconController methodsFor: 'private: private'!

mouseDetect
	"Return true if the cursorPoint intersects the icons shape."
	
	| icon |
	icon _ model form.
	^icon class == OpaqueForm
					ifTrue: [(model form shape
								valueAt: (sensor cursorPoint - view insetDisplayBox origin)) = 1]
					ifFalse: [view insetDisplayBox containsPoint: sensor cursorPoint]! !

!IconController methodsFor: 'basic control sequence'!

idle
	"do nothing"! !

!IconController methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	"Menu for yellow button on anything collapsed to an icon."

	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IconController class
	instanceVariableNames: ''!


!IconController class methodsFor: 'class initialization'!

initialize
	"IconController initialize"

	self allInstances do: [:controller | controller initialize]! !

IconController initialize!
