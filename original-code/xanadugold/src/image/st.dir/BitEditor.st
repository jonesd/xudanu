'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:14 pm'!

MouseMenuController subclass: #BitEditor
	instanceVariableNames: 'scale squareForm color '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Form editing'!
BitEditor comment:
'A BitEditor is a bit-magnifying tool for editing small Forms directly on the display screen.

Instance Variables: 
	scale	<Point>
	squareForm	<Form>
	color	<Symbol> denoting the color for marking a bit

Class Variables:
	YellowButtonMenu		<PopUpMenu> to be displayed when the operate button is pressed, operations on remembering the contents
	YellowButtonMessages	<Array of: Symbols> of message names, one associated with each item in the YellowButtonMenu'!


!BitEditor methodsFor: 'initialize-release'!

release
	super release.
	squareForm release.
	squareForm _ nil! !

!BitEditor methodsFor: 'view access'!

view: aView
	super view: aView.
	scale _ aView transformation scale.	
	scale _ scale x rounded @ scale y rounded.
	squareForm _ Form new extent: scale.
	squareForm black! !

!BitEditor methodsFor: 'basic control sequence'!

controlInitialize
	super controlInitialize.
	Cursor crossHair show!

controlTerminate
	Cursor normal show! !

!BitEditor methodsFor: 'control defaults'!

controlActivity 
	| absoluteScreenPoint formPoint displayPoint |
	super controlActivity.
	[sensor redButtonPressed]
	  whileTrue: 
		[absoluteScreenPoint _ sensor cursorPoint.	
		formPoint _ (view inverseDisplayTransform: absoluteScreenPoint - (scale//2)) rounded.
		displayPoint _ view displayTransform: formPoint.
		squareForm 
			displayOn: Display
			at: displayPoint 
			clippingBox: view insetDisplayBox 
			rule: Form over
			mask: (Form perform: color).
		view changeValueAt: formPoint put:
			(#(white black gray) indexOf: color)-1].!

isControlActive
	^super isControlActive & sensor blueButtonPressed not 
		& sensor keyboardPressed not! !

!BitEditor methodsFor: 'private: private-menu messages'!

accept
	"The edited information should now be accepted by the view."
	view accept!

cancel
	"The edited informatin should be forgotten by the view."
	view cancel!

setColor: aSymbol
	color _ aSymbol! !

!BitEditor methodsFor: 'private: private'!

yellowButtonMenu
	"Menu for the bit editor."
	
	^(PopUpMenu fromArray: #(
		('accept'	accept	'')	"All are standard smalltalk."
		('cancel'	cancel	'') )).! !

!BitEditor methodsFor: 'smalltalk: passe'!

initializeYellowButtonMenu
	"Menu for the bit editor."
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BitEditor class
	instanceVariableNames: ''!


!BitEditor class methodsFor: 'class initialization'! !

!BitEditor class methodsFor: 'instance creation'!

openOnForm: aForm
	"Create and schedule a BitEditor on the form aForm."

	| scaleFactor |
	scaleFactor _ 8 @ 8.
	^ self openOnForm: aForm
		at: (self locateMagnifiedView: aForm scale: scaleFactor) topLeft
		scale: scaleFactor!

openOnForm: aForm at: aPoint
	"Create and schedule a BitEditor on the form aForm with origin point at aPoint."

	^ self openOnForm: aForm
		at: aPoint
		scale: 8 @ 8!

openOnForm: aForm at: magnifiedLocation scale: scaleFactor 
	"Create and schedule a BitEditor on the form aForm.  Show the small and 
	magnified view of aForm."

	| aScheduledView |
	aScheduledView _ self
				bitEdit: aForm
				at: magnifiedLocation
				scale: scaleFactor
				remoteView: nil.
	aScheduledView controller openDisplayAt:
		aScheduledView displayBox topLeft + (aScheduledView displayBox extent / 2)!

openScreenViewOnForm: aForm 
	at: formLocation 
	magnifiedAt: magnifiedLocation 
	scale: scaleFactor 
	"Create and schedule a BitEditor on the form aForm. Show the magnified 
	view of aForm in a scheduled window."

	| smallFormView bitEditor savedForm |
	smallFormView _ FormView new model: aForm.
	smallFormView align: smallFormView viewport topLeft with: formLocation.
	bitEditor _ self
				bitEdit: aForm
				at: magnifiedLocation
				scale: scaleFactor
				remoteView: smallFormView.
	savedForm _ Form fromDisplay: bitEditor displayBox.
	bitEditor controller startUp.
	savedForm displayOn: Display at: bitEditor displayBox topLeft.
	bitEditor release.
	smallFormView release! !

!BitEditor class methodsFor: 'examples'!

magnifyOnScreen
	"Bit editing of an area of the display screen. User designates a 
	rectangular area that is magnified by 8 to allow individual screens dots to be 
	modified.  Editor is not scheduled in a view.  Original screen location is 
	updated immediately.  This is the same as FormEditor magnify."

	"BitEditor magnifyOnScreen."

	| smallRect smallForm scaleFactor tempRect |
	scaleFactor _ 8 @ 8.
	smallRect _ Rectangle fromUser.
	smallRect isNil ifTrue: [^self].
	smallForm _ Form fromDisplay: smallRect.
	tempRect _ self locateMagnifiedView: smallForm scale: scaleFactor.
	"show magnified form size until mouse is depressed"
	BitEditor
		openScreenViewOnForm: smallForm 
		at: smallRect topLeft 
		magnifiedAt: tempRect topLeft 
		scale: scaleFactor!

magnifyWithSmall
	"Bit editing of an area of the Form. User designates a rectangular area 
	that is magnified by 8 to allow individual screens dots to be modified.  
	Editor is scheduled in a view, showing the magnified view only."

	"BitEditor magnifyWithSmall."

	| smallRect smallForm  |
	smallRect _ Rectangle fromUser.
	smallRect isNil ifTrue: [^self].
	smallForm _ Form fromDisplay: smallRect.
	BitEditor openOnForm: smallForm! !

!BitEditor class methodsFor: 'private: private'!

bitEdit: aForm at: magnifiedFormLocation scale: scaleFactor remoteView: remoteView
	"Creates a BitEditor on aForm. That is, aForm is a small image that will 
	change as a result of the BitEditor changing a second and magnified 
	view of me. magnifiedFormLocation is where the magnified form is to be 
	located on the screen. scaleFactor is the amount of magnification. This 
	method implements a scheduled view containing both a small and 
	magnified view of aForm. Upon accept, aForm is updated."

	| aFormView scaledFormView bitEditor topView extent menuView lowerRightExtent |
	scaledFormView _ FormHolderView new model: aForm.
	scaledFormView scaleBy: scaleFactor.
	bitEditor _ self new.
	bitEditor setColor: #black.
	scaledFormView controller: bitEditor.
	topView _ StandardSystemView new.
	remoteView == nil ifTrue: [topView label: 'Bit Editor'].
	topView borderWidth: 2.
	topView insideColor: Form white.

	topView addSubView: scaledFormView.
	remoteView == nil
		ifTrue:  "If no remote view, then provide a local view of the form"
			[aFormView _ FormView new model: scaledFormView workingForm.
			aFormView controller: NoController new.
			(aForm isMemberOf: OpaqueForm) ifTrue:
				[scaledFormView insideColor: Form gray.
				aFormView insideColor: Form white].
			aForm height < 50
				ifTrue: [aFormView borderWidthLeft: 0 right: 2 top: 2 bottom: 2]
				ifFalse: [aFormView borderWidthLeft: 0 right: 2 top: 2 bottom: 0].
			topView addSubView: aFormView below: scaledFormView]
		 ifFalse:  "Otherwise, the remote one should view the same form"
			[remoteView model: scaledFormView workingForm].
	lowerRightExtent _ remoteView == nil
			ifTrue:
				[(scaledFormView viewport width - aFormView viewport width) @
					(aFormView viewport height max: 50)]
			ifFalse:
				[scaledFormView viewport width @ 50].
	menuView _ self buildColorMenu: lowerRightExtent
		colorCount: ((aForm isMemberOf: OpaqueForm) ifTrue: [3] ifFalse: [2]).
	menuView model: bitEditor.
	menuView borderWidthLeft: 0 right: 0 top: 2 bottom: 0.
	topView
		addSubView: menuView
		align: menuView viewport topRight
		with: scaledFormView viewport bottomRight.
	extent _ scaledFormView viewport extent + (0 @ lowerRightExtent y)
			+ (4 @ 4).  "+4 for borders"
	topView minimumSize: extent.
	topView maximumSize: extent.
	topView translateBy: magnifiedFormLocation.
	^topView!

buildColorMenu: extent colorCount: nColors  "BitEditor magnifyWithSmall."
	| menuView form aSwitchView connector
	  button formExtent highlightForm color leftOffset |
	connector _ Object new.
	menuView _ FormMenuView new.
	menuView window: (0@0 corner: extent).
	formExtent _ 30@30 min: extent//(nColors*2+1@2).  "compute this better"
	leftOffset _ extent x-(nColors*2-1*formExtent x)//2.
	highlightForm _ Form extent: formExtent.
	highlightForm borderWidth: 4 mask: Form black.
	1 to: nColors do:
		[:index | 
		color _ (nColors=2
			ifTrue: [#(white black)]
			ifFalse: [#(white gray black)]) at: index.
		form _ Form extent: formExtent.
		form fill: form boundingBox mask: (Form perform: color).
		form borderWidth: 5 mask: Form black.
		color = #black ifTrue: [form borderWidth: 5 mask: Form white].
		form borderWidth: 4 mask: Form white.
		button _ color = #black
			ifTrue: [OneOnSwitch newOn]
			ifFalse: [OneOnSwitch newOff].
		button onAction: [menuView model setColor: color].
		button connection: connector.

		aSwitchView _ SwitchView new model: button.
		aSwitchView key: ((nColors=3 ifTrue: ['xvn'] ifFalse: ['xn']) at: index).
		aSwitchView label: form.
		aSwitchView window: (0@0 extent: form extent).
		aSwitchView translateBy: (index-1*2*form width+leftOffset) @ (form height//2).
		aSwitchView insideColor: Form white.
		aSwitchView highlightForm: highlightForm.
	
		aSwitchView borderWidth: 1.
		aSwitchView controller selector: #turnOn.
		menuView addSubView: aSwitchView].
	^menuView!

locateMagnifiedView: aForm scale: scaleFactor 
	"Answers with a rectangle at the location where the scaled view of 
	the form aForm 
	should be displayed."

	| tempExtent tempRect |
	tempExtent _ aForm extent * scaleFactor + (0 @ 50).
	tempRect _ Sensor cursorPoint extent: tempExtent.
	"show magnified form size until mouse is depressed"
	Cursor origin showWhile:
		[tempRect _ Display
				outline: [Sensor cursorPoint extent: tempExtent]
				while: [Sensor anyButtonPressed not]
				width: 2
				halftone: Form gray].
	^tempRect! !