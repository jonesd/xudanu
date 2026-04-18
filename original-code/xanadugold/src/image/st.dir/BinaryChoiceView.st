'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:48 pm'!

View subclass: #BinaryChoiceView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
BinaryChoiceView comment:
'A BinaryChoiceView is a view of a BinaryChoice.  It displays a question and two switches, yes and no, indicating choices the user can make.'!


!BinaryChoiceView methodsFor: 'controller access'!

defaultControllerClass
	^BinaryChoiceController! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BinaryChoiceView class
	instanceVariableNames: ''!


!BinaryChoiceView class methodsFor: 'instance creation'!

openOn: aBinaryChoice message: messageString displayAt: originPoint centered: centered
	"Answer an instance of me that displays aBinaryChoice asking the question
	messageString.  If the argument centered, a Boolean, is false, display the instance
	with top left corner at originPoint;  otherwise, display it with its center at
	originPoint.  If necessary, translate so the view is completely on the screen.
	Do not schedule, rather take control immediately and insist that the user respond."

	| topView messageView switchView savedArea |
	messageView _ DisplayTextView new editParagraph: messageString asParagraph.
	messageView insideColor: Form white.
	messageView controller: NoController new.
	messageView centered.
	switchView _ 
		self buildSwitchesFor: aBinaryChoice width: messageView window width.
	topView _ self new model: aBinaryChoice.
	topView addSubView: messageView.
	topView addSubView: switchView below: messageView.
	topView
		align: (centered
				ifTrue: [switchView viewport center]
				ifFalse: [topView viewport topLeft])
		with: originPoint.
	topView borderWidth: 2.
	topView translateBy:
		(topView displayBox amountToTranslateWithin: Display boundingBox).
	topView insideColor: Form white.
	savedArea _ Form fromDisplay: topView displayBox.
	topView display.
	topView controller startUp.
	topView release.
	savedArea displayOn: Display at: topView viewport topLeft! !

!BinaryChoiceView class methodsFor: 'private: private'!

buildSwitchesFor: aBinaryChoice	width: anInteger
	|switchView yesSwitchView noSwitchView|
	switchView _ View new model: aBinaryChoice.
	switchView controller: BinaryChoiceController new.
	yesSwitchView _ SwitchView new model: aBinaryChoice.
	yesSwitchView borderWidthLeft: 0 right: 2 top: 0 bottom: 0.
	yesSwitchView selector: #active.
	yesSwitchView controller selector: #selectTrue.
	yesSwitchView controller cursor: Cursor thumbsUp.
	yesSwitchView label: 'yes' asParagraph.
	yesSwitchView window: (0@0 extent: anInteger//2 @ yesSwitchView window height).
	noSwitchView _ SwitchView new model: aBinaryChoice.
	noSwitchView selector: #active.
	noSwitchView controller selector: #selectFalse.
	noSwitchView controller cursor: Cursor thumbsDown.
	noSwitchView label: 'no' asParagraph.
	noSwitchView window: (0@0 extent: anInteger//2 @ noSwitchView window height).
	switchView addSubView: yesSwitchView.
	switchView addSubView: noSwitchView toRightOf: yesSwitchView.
	switchView borderWidthLeft: 0 right: 0 top: 2 bottom: 0.
	^switchView! !