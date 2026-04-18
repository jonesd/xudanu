'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:36 pm'!

View subclass: #IconView
	instanceVariableNames: 'iconText isReversed '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Support'!
IconView comment:
'Class IconView represents the view displayed when a StandardSystemView is collapsed.

Instance Variables:
	iconText	<Paragraph>
	isReversed 	<Boolean> true if the instance is highlighted'!


!IconView methodsFor: 'initialize-release'!

initialize

	super initialize.
	isReversed _ false.! !

!IconView methodsFor: 'text access'!

iconText
	"Answer the receiver's icon text or nil if none."

	^iconText!

text
	"Answer the receiver's icon text."

	iconText == nil
		ifTrue: [^ Text new]
		ifFalse: [^ iconText text]!

text: aStringOrText
	"Set the receiver's icon text to be aStringOrText."

	| textRect style|
	(aStringOrText isNil or: [aStringOrText string isEmpty])
		ifTrue: [^ iconText _ nil].
	iconText isNil
		ifTrue:
			[textRect _ model textRect.
			textRect == nil ifTrue: [^self].
			style _  TextStyle styleNamed: #icon ifAbsent: [nil].
			style == nil ifTrue: [style _ TextStyle default].
			iconText _ Paragraph withText: aStringOrText asText
				style: style
				compositionRectangle: textRect
				clippingRectangle: textRect]
		ifFalse:
			[iconText text: aStringOrText asText]! !

!IconView methodsFor: 'controller access'!

defaultControllerClass

	^IconController! !

!IconView methodsFor: 'window access'!

defaultWindow
	"Return my default window based on my icons extent."

	^(Rectangle origin: 0 @ 0 extent: model extent)
		expandBy: self borderWidth! !

!IconView methodsFor: 'displaying'!

deEmphasizeView
	"Emphasize the receiver's image on the screen."

	isReversed
		ifTrue:
			[self reverseImageOn: Display.
			isReversed _ false]!

displayView
	"Display the receiver's icon and icon text."

	| textBox |
	model form
		displayOn: Display
		at: self insetDisplayBox origin.
	(iconText notNil and: [model textRect notNil]) ifTrue:
		[textBox _ (textBox _ self insetDisplayBox) 
					intersect: (model textRect translateBy: textBox origin).
	iconText asForm displayOn: Display
			at: textBox origin
			clippingBox: textBox
			rule: Form over mask: nil].
	isReversed _ false.!

emphasizeView
	"Emphasize the receiver's image on the screen."

	isReversed
		ifFalse:
			[self reverseImageOn: Display.
			isReversed _ true]!

image
	"Answer a copy of the receiver's visual representation."

	|image|
	image _ model form deepCopy.
	(iconText notNil and: [model textRect notNil]) ifTrue:
		[iconText asForm
				displayOn: image figure
				at: model textRect origin
				clippingBox: model textRect
				rule: Form over mask: nil].
	^image!

reverseImageOn: aMedium
	"Reverse the receiver's image on the screen."

	model form class == OpaqueForm
		ifTrue:
			[model form shape
				displayOn: aMedium
				at: self displayBox origin
				clippingBox: self insetDisplayBox
				rule: Form reverse mask: nil]
		ifFalse:
			[model form
				displayOn: aMedium
				at: self displayBox origin
				clippingBox: self insetDisplayBox
				rule: 10 mask: nil]		"Reverse destination always"! !

!IconView methodsFor: 'private: private'!

isFromLabel
	"This allows the system to distinguish between pictorial 
	icons and those that are generated automatically from label text."

	| form |
	form _ self model form.
	^form class == Form!

newIcon
	"The receiver's model is being changed to a new icon.  If there is display location state on the receiver, it must be updated."

	| width height |
	insetDisplayBox isNil
		ifFalse: 
			[width _ self model form width.
			height _ self model form height.
			window _ Rectangle origin: 0 @ 0 corner: width @ height.
			viewport _ window deepCopy.
			insetDisplayBox corner: insetDisplayBox origin + (width @ height)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IconView class
	instanceVariableNames: ''!


!IconView class methodsFor: 'instance creation'!

on: anIcon
	"Answer an instance of the receiver with anIcon as its model."

	| view |
	view _ self new model: anIcon.
	^view! !

!IconView class methodsFor: 'examples'!

iconSampler
	"This example creates the simplest view to demonstrate the use of
	instances of class Icon as images for collapsed views.  When you
	evaluate this example, a view will appear.  Press the select button to
	place the view on the screen.  Try the collapse message in the view
	button menu."

	"IconView iconSampler"

	| topView |
	topView _ StandardSystemView new.
	topView label: 'Default'.
	topView insideColor: Form white.
	topView borderWidth: 2.
	topView minimumSize: 300.
	topView maximumSize: 300.
	topView icon: (Icon constantNamed: #default).
	topView controller open! !