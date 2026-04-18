'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:43 pm'!

View subclass: #DisplayTextView
	instanceVariableNames: 'rule mask editParagraph centered '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
DisplayTextView comment:
'Class DisplayTextView represents a view of an instance of DisplayText.

Instance Variables:
	rule		<Integer> according to which character display behaves:  equal over, under, 
			and reverse.
	mask	<Form> with which each character is combined by the display scanner
			before applying the rule.
	editParagraph	<Paragraph> the composed text ready for display
	centered	<Boolean> whether the text is centered
'!


!DisplayTextView methodsFor: 'initialize-release'!

initialize
	"Initialize the instance variables."

	super initialize.
	centered _ false! !

!DisplayTextView methodsFor: 'accessing'!

centered
	"Set the receiver so that the text is displayed centered."

	centered _ true.
	self centerText!

editParagraph: aParagraph 
	"Set the text paragraph for the receiver to be aParagraph centered."

	editParagraph _ aParagraph.
	self centerText!

isCentered
	"Answer whether the text is centered in the view."

	^centered!

mask
	"Answer an instance of class Form that is to be used as the mask when displaying
	the receiver's model (a DisplayText)."

	mask == nil
		ifTrue: [^self defaultMask]
		ifFalse: [^mask]!

mask: aForm 
	"Set aForm to be the mask used when displaying the receiver's model."

	mask _ aForm!

rule
	"Answer a number from 0 to 15 that indicates which of the sixteen display rules
	is to be used when blting the receiver's model (a DisplayText) onto the display
	screen."

	rule == nil
		ifTrue: [^self defaultRule]
		ifFalse: [^rule]!

rule: anInteger 
	"Set anInteger to be the rule used when displaying the receiver's model."

	rule _ anInteger! !

!DisplayTextView methodsFor: 'controller access'!

defaultController
	"Answer a new instance of the default controller and set its
	paragraph for editing to be the text of the receiver."

	^self defaultControllerClass newParagraph: editParagraph!

defaultControllerClass
	"Answer the class of the default controller."

	^ParagraphEditor! !

!DisplayTextView methodsFor: 'window access'!

defaultWindow
	"Answer the rectangle that represents the window into which the
	receiver's text will display."

	^((0@0 extent: editParagraph extent) expandBy: self paragraphInset)
		expandBy: self borderWidth!

window: aWindow 
	"Set the window for display to be the argument aWindow."

	super window: aWindow.
	self centerText! !

!DisplayTextView methodsFor: 'model access'!

model: aDisplayText 
	"Set the model of the receiver to be the argument aDisplayText."

	super model: aDisplayText.
	self editParagraph: aDisplayText asParagraph.! !

!DisplayTextView methodsFor: 'displaying'!

display
	"Show the receiver's text model on the display screen."

	self isUnlocked ifTrue: [self positionText].
	super display!

displayView
	"Display the receiver on the display screen within its bounding rectangle."

	self clearInside.
	(self controller isKindOf: ParagraphEditor )
		ifTrue: [controller changeParagraph: editParagraph].
	self isCentered
		ifTrue: 
			[editParagraph
				displayOn: Display
				transformation: self displayTransformation
				clippingBox: self insetDisplayBox
				fixedPoint: editParagraph boundingBox center]
		ifFalse: 
			[editParagraph displayOn: Display]! !

!DisplayTextView methodsFor: 'deEmphasizing'!

deEmphasizeView
	"Emphasize the receiver's image on the screen."

	(self controller isKindOf: ParagraphEditor)
	 	ifTrue: [controller deselect]! !

!DisplayTextView methodsFor: 'private: private'!

centerText
	"Make the text of the receiver center within its bounding box."

	self isCentered
		ifTrue: 
			[editParagraph
				align: editParagraph boundingBox center
				with: self getWindow center]!

defaultMask
	"Answer the default mask for the receiver."
	
	^Form black!

defaultRule
	"Answer the default combination rule for the receiver."
	
	^Form over!

paragraphInset
	"Answer the amount to inset the paragraph from the border."

	^6@0!

positionText
	"Compose the text so that it displays centered within the clipping box 
	of the receiver."

	| box |
	box _ self insetDisplayBox origin + self paragraphInset
			extent: editParagraph boundingBox extent.
	editParagraph recomposeIn: box clippingBox: box.
	self centerText! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DisplayTextView class
	instanceVariableNames: ''!


!DisplayTextView class methodsFor: 'examples'!

example1	
	"Creates a passive view of some text on the screen."

	"DisplayTextView example1."

	| view |
	view_ self new model: 'this is a test of one line
and the second line' asDisplayText.
	view translateBy: 100@100.	
	view borderWidth: 2.
	view insideColor: Form white.
	view display.
	view release!

example2	
	"Creates four passive views of some text on the screen with fat borders."

	"DisplayTextView example2."

	| view |
	view_ self new model: 'this is a test of one line
and the second line' asDisplayText.
	view translateBy: 100@100.	
	view borderWidth: 5.
	view insideColor: Form white.
	view display.
	3 timesRepeat: [view translateBy: 100@100. view display].
	view release! !