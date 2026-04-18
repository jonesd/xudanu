'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:35 pm'!

View subclass: #FormView
	instanceVariableNames: 'rule mask '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Support'!
FormView comment:
'Instances of class FormView have as their model a Form.  It is used mainly to allow display of Forms on the display screen in the model-view-controller metaphor.

Instance Variables:
	rule		<SmallInteger> from 0 to 15 that indicates which of the sixteen display rules (logical function of two Boolean values) is to be used when copying the receiver''s model (a Form) onto the display screen

	mask	<Form>  used when displaying the receiver''s mode on the display screen'!


!FormView methodsFor: 'accessing'!

mask
	"Answer an instance of class Form that is the mask used when displaying 
	the receiver's model (a Form) on the display screen."

	mask == nil
		ifTrue: [^self defaultMask]
		ifFalse: [^mask]!

mask: aForm 
	"Set the display mask for displaying the receiver's model."

	mask _ aForm!

rule
	"Answer a number from 0 to 15 that indicates which of the sixteen display rules
	(logical function of two boolean values) is to be used when copying the receiver's
	model (a Form) onto the display screen."

	rule == nil
		ifTrue: [^self defaultRule]
		ifFalse: [^rule]!

rule: anInteger 
	"Set the display rule for the receiver."

	rule _ anInteger! !

!FormView methodsFor: 'controller access'!

defaultControllerClass
	"Answer the default class of the receiver."

	^FormEditor! !

!FormView methodsFor: 'model access'!

changeValueAt: location put: anInteger
	"The receiver's model is a Form which has an array of bits.  Change
	the bit at index location to be anInteger (either 1 or 0).  Inform all
	objects that depend on the model that it has changed."

	model valueAt: location put: anInteger.
	model changed: self! !

!FormView methodsFor: 'window access'!

defaultWindow 
	^(Rectangle origin: 0 @ 0 extent: model extent)
		expandBy: self borderWidth! !

!FormView methodsFor: 'displaying'!

displaySafe: aBlock
	"Put the display of the receiver at the top of all
	views and evaluate the argument aBlock."

	ScheduledControllers displaySafe: aBlock forController: self controller!

displayView 
	| oldOffset |
	super displayView.
	self insideColor == nil ifFalse: [Display fill: self insetDisplayBox mask: self insideColor].
	oldOffset _ model offset.
	model offset: 0@0.
	model
		displayOn: Display
		transformation: self displayTransformation
		clippingBox: self insetDisplayBox
		rule: self rule
		mask: self mask.
	model offset: oldOffset! !

!FormView methodsFor: 'updating'!

update: aFormView
	self == aFormView ifFalse: [self display]! !

!FormView methodsFor: 'menu messages'!

accept
	"The receiver's model is set to the working version, the one in which edits
	are carried out."
	^self!

cancel
	"Set the working form to be a copy of the model."
	^self! !

!FormView methodsFor: 'private: private'!

defaultMask 
	"The default display mask, blackMask, is a 16x16 Form that is all ones"

	^Form black!

defaultRule 
	"This is the default display rule (3=over or storing)"

	^Form over! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FormView class
	instanceVariableNames: ''!


!FormView class methodsFor: 'examples'!

exampleOne	
	"Frame a Form (specified by the user) with a border of 5 bits in width and
	display it offset 100@100 from the corner of the display screen."

	"FormView exampleOne"

	| f view |
	f _ Form fromUser.
	view _ self new model: f.
	view translateBy: 100 @ 100.
	view borderWidth: 5.
	view insideColor: Form white.
	view display.
	view release!

exampleTwo
	"Frame a Form (specified by the user) that is scaled by 2.  The border is 
	2 bits in width.  Displays at location 100,100."

	"FormView exampleTwo."

	| f view |
	f _ Form fromUser.
	view _ self new model: f.
	view scaleBy: 2.0.
	"if you eliminate this message, no inside border displays"
	view translateBy: 100 @ 100.
	view borderWidth: 2.
	view insideColor: Form white.
	view display.
	view release! !