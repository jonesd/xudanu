'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:53 pm'!

View subclass: #SwitchView
	instanceVariableNames: 'complemented label selector keyCharacter highlightForm arguments emphasisOn '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
SwitchView comment:
'A SwitchView is a view of a Switch.  Its instances have labels and display modes (set to "normal" or "complemented").  When one of the instances is displayed in complemented mode, its inside color is reversed.  The value of the display mode corresponds to the value of the model so that, for example, when a Switch is off, its SwitchView is displayed with black text (for the label) on a white background, and when the Switch is off, its SwitchView is displayed with white text on a black background.  Instances have a key character that can be used for switching on or off.  Highlighting can be done specially using a stored form, rather than simply changing all black bits to white and vice versa.  The default controller is SwitchController.

Instance Variables:
		complemented		<Boolean> true if the model is on
		label				<DisplayObject>, for example, a DisplayText or a Form
		selector			<Symbol>
		keyCharacter		<Character>
		highlightForm		<Form>
		arguments			<Array>
		emphasisOn			<Boolean> true if the view is active
'!


!SwitchView methodsFor: 'initialize-release'!

initialize
	super initialize.
	insideColor _ Form white.
	complemented _ false.
	label _ nil.
	selector _ #isOn.
	arguments _ #().
	emphasisOn _ true!

release
	super release.
	label release! !

!SwitchView methodsFor: 'accessing'!

arguments
	"Answer the arguments the receiver sends in a message to its receiver."
	^arguments!

arguments: anArray
	"The argument, anArray, consists of the arguments of the message
	the receiver sends to its model."
	arguments _ anArray!

highlightForm: aForm 
	"The argument is the form to be used to highlight the receiver."

	highlightForm _ aForm!

key: aCharacter 
	"Set the receiver to be selected by the argument, aCharacter."
	keyCharacter _ aCharacter! !

!SwitchView methodsFor: 'testing'!

containsKey: aCharacter 
	"Answer whether the receiver can be selected by the argument, aCharacter."
	^keyCharacter = aCharacter! !

!SwitchView methodsFor: 'controller access'!

defaultControllerClass
	^SwitchController! !

!SwitchView methodsFor: 'window access'!

defaultWindow
	"Returns the frame of the SwitchView's label's frame (slightly enlarged) 
	if the label exists, and returns the standard View default window (see 
	View|defaultWindow), otherwise."

	label == nil
		ifTrue: [^super defaultWindow]
		ifFalse: [^label boundingBox expandBy: 6]!

window: aWindow 
	super window: aWindow.
	self centerLabel! !

!SwitchView methodsFor: 'displaying'!

displayComplemented
	"Complement the receiver if its mode is 'normal'."

	complemented
		ifFalse: 
			[complemented _ true.
			self highlight]!

displayNormal
	"Complement the receiver if its mode is 'complemented'."

	complemented
		ifTrue: 
			[complemented _ false.
			self highlight]!

displaySpecial
	"If mode is 'complemented' display the highlight form.  If there is a label,
	then display that label in the receiver's display box."

	complemented
		ifTrue: [self displaySpecialComplemented].
	label == nil 
		ifFalse: [label
					displayOn: Display
					transformation: self displayTransformation
					clippingBox: self insetDisplayBox
					align: label boundingBox center
					with: label boundingBox center
					rule: Form under
					mask: Form black]!

displaySpecialComplemented	
	"Show the highlight form rather than the normal form for the receiver."

	highlightForm
		displayOn: Display
		transformation: self displayTransformation
		clippingBox: self insetDisplayBox
		fixedPoint: label boundingBox center!

displayView
	"Do the standard View actions and, in addition, display the 
	receiver's label based on the current display transformation and 
	inset display box. "

	| center |
	self clearInside.
	label == nil
		ifFalse: 
			[center _ label boundingBox center.
			label displayOn: Display
				at: (label offset + (self displayTransformation applyTo: center) - center) rounded
				clippingBox: self insetDisplayBox].
	complemented _ self interrogateModel.
	complemented ifTrue: [self highlight]!

highlight
	"Cause the inset display box (the display box excluding the border, 
	see  
	View|insetDisplayBox) of the receiver to complement."

	highlightForm == nil ifFalse: [^highlightForm
			displayOn: Display
			at: self displayBox topLeft
			clippingBox: self insetDisplayBox
			rule: Form reverse
			mask: nil].
	emphasisOn
		ifTrue: [Display reverse: (self insetDisplayBox insetBy: 1)]
		ifFalse: 
			[Display reverse: (self insetDisplayBox insetBy: 1).
			Display reverse: (self insetDisplayBox insetBy: 2)]! !

!SwitchView methodsFor: 'updating'!

update: aParameter 
	highlightForm == nil
		ifTrue: [self interrogateModel 
					ifTrue: [self displayComplemented]
					ifFalse: [self displayNormal]]
		ifFalse: [self display]! !

!SwitchView methodsFor: 'label access'!

centerLabel
	"Align the center of the frame of the label with the center of the receiver's window."

	label == nil 
		ifFalse: 
			[label 
				align: label boundingBox center 
				with: self getWindow center]!

label
	"Answer the label, a display object, that is the receiver's screen image."
	^label!

label: aDisplayObject 
	"Set aDisplayObject to be the label that is the receiver's screen image."

	label release.
	label _ aDisplayObject.
	self centerLabel! !

!SwitchView methodsFor: 'indicating'!

indicatorOnDuring: aBlockContext 
	"Indicate the receiver during the execution of aBlockContext by 
	complementing the label (or a portion of the display box if no label is 
	defined). "

	self indicatorReverse.
	self highlight. 
	aBlockContext value.
	self highlight.
	self indicatorReverse!

indicatorReverse
	"Complement the label (or a portion of the displayBox if no label is defined)."

	Display reverse: self insetDisplayBox mask: Form gray.
	Display reverse: (self insetDisplayBox insetBy: 2) mask: Form gray! !

!SwitchView methodsFor: 'selector'!

interrogateModel
	"Answer the result of sending the receiver's model the message
	created from the receiver's selector and arguments."
	arguments size = 0
		ifTrue: [^model perform: selector]
		ifFalse: [^model perform: selector withArguments: arguments]!

selector
	"Answer the selector the receiver sends in a message to its receiver."
	^selector!

selector: aSymbol 
	"Set aSymbol to be the selector the receiver sends in a message to its model."
	selector _ aSymbol! !

!SwitchView methodsFor: 'deEmphasizing'!

deEmphasizeView
	complemented ifFalse: [^ self].
	emphasisOn ifTrue:
		[self highlight.
		emphasisOn _ false.
		self highlight]!

emphasizeView
	complemented ifFalse: [^ self].
	emphasisOn ifFalse:
		[self highlight.
		emphasisOn _ true.
		self highlight]! !