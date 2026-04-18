'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:47 pm'!

DisplayObject subclass: #DisplayText
	instanceVariableNames: 'text textStyle offset form '
	classVariableNames: ''
	poolDictionaries: 'TextConstants '
	category: 'Graphics-Display Objects'!
DisplayText comment:
'Instances of class DisplayText get used two different ways in the system.  In the user interface, a DisplayText is used to hold onto some text which is viewed by some form of ParagraphEditor.  Used more generally as a DisplayObject, an instance may need to display efficiently--an instance variable is used to cache the bits for that purpose.

Instance Variables:
	text		<Text> displayed by the receiver
	textStyle	<TextStyle> style by which the receiver displays its text.
	offset		<Point> translation of the text position when displayed
	form 		<Form>	for caching the bit representation of the receiver''s composed text.
'!


!DisplayText methodsFor: 'accessing'!

form
	"Answer the form containing the composed text."

	form == nil ifTrue: [self composeForm].
	^form!

lineGrid
	"Answer the relative space between lines of the receiver's text."

	^textStyle lineGrid!

numberOfLines 
	"Answer the number of lines of text in the receiver."

	^self height // textStyle lineGrid!

offset 
	"Answer the offset of the receiver."

	^offset!

offset: aPoint 
	"Set the offset to be the argument aPoint."

	offset _ aPoint!

string
	"Answer the string of the characters displayed by the receiver."

	^text string!

text 
	"Answer the text displayed by the receiver."

	^text!

text: aText 
	"Set the receiver to display the argument, aText."
	
	text _ aText.
	form _ nil.
	self changed.!

textStyle 
	"Answer the style by which the receiver displays its text."

	^textStyle!

textStyle: aTextStyle 
	"Set the style by which the receiver should display its text."

	textStyle _ aTextStyle.
	form _ nil.
	self changed.! !

!DisplayText methodsFor: 'displaying'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm
	"Display the receiver on the display medium aDisplayMedium positioned at aDisplayPoint within 
	the rectangle clipRectangle and with the rule, ruleInteger, and mask, aForm. "

	 self form
		displayOn: aDisplayMedium
		at: aDisplayPoint + offset
		clippingBox: clipRectangle
		rule: ruleInteger
		mask: aForm!

displayOn: aDisplayMedium transformation: displayTransformation clippingBox: clipRectangle align: alignmentPoint with: relativePoint rule: ruleInteger mask: aForm
	"Display the receiver where a DisplayTransformation is provided as an argument,
	rule is ruleInteger and mask is aForm.  Translate by relativePoint-alignmentPoint.
	Information to be displayed must be confined to the area that intersects with
	clipRectangle." 

	| absolutePoint |
	absolutePoint _ displayTransformation applyTo: relativePoint.
	absolutePoint _ absolutePoint x truncated @ absolutePoint y truncated.
	self displayOn: aDisplayMedium
		at: absolutePoint - alignmentPoint
		clippingBox: clipRectangle
		rule: ruleInteger
		mask: aForm! !

!DisplayText methodsFor: 'display box access'!

boundingBox 
	"Answer the rectangular area that represents the boundaries of the 
	receiver's space of information."

	^self form boundingBox!

computeBoundingBox 
	"Answer the minimum enclosing rectangle around the characters in the text."

	| character font width carriageReturn lineWidth lineHeight |
	carriageReturn _ Character cr.
	width _ lineWidth _ 0.
	font _ textStyle defaultFont.
	lineHeight _ textStyle lineGrid.
	1 to: text size do: 
		[:i | 
		character _ text at: i.
		character = carriageReturn
		  ifTrue: 
			[lineWidth _ lineWidth max: width.
			lineHeight _ lineHeight + textStyle lineGrid.
			width _ 0]
		  ifFalse: [width _ width + (font widthOf: character)]].
	lineWidth _ lineWidth max: width.
	^offset extent: lineWidth @ lineHeight! !

!DisplayText methodsFor: 'converting'!

asParagraph
	"Answer a Paragraph whose text and style are identical to that of
	the receiver."

	^Paragraph withText: text style: textStyle copy! !

!DisplayText methodsFor: 'private: private'!

composeForm 
	"Cache the form for displaying the paragraph."

	form _ self asParagraph asForm!

setText: aText textStyle: aTextStyle offset: aPoint 
	"Initialize the instance variables."

	text _ aText.
	textStyle _ aTextStyle.
	offset _ aPoint.
	form _ nil! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DisplayText class
	instanceVariableNames: ''!


!DisplayText class methodsFor: 'instance creation'!

text: aText 
	"Answer an instance of me such that the text displayed is aText
	according to the system's default textstyle."
	^self new
		setText: aText
		textStyle: DefaultTextStyle copy
		offset: 0 @ 0!

text: aText textStyle: aTextStyle 
	"Answer an instance of me such that the text displayed is aText 
	according to the style specified by aTextStyle."
	^self new
		setText: aText
		textStyle: aTextStyle
		offset: 0 @ 0!

text: aText textStyle: aTextStyle offset: aPoint 
	"Answer an instance of me such that the text displayed is aText 
	according to the style specified by aTextStyle.  The display of the 
	information should be offset by the amount given as the argument, aPoint."
	^self new
		setText: aText
		textStyle: aTextStyle
		offset: aPoint! !

!DisplayText class methodsFor: 'examples'!

textSampler
	"Continually prints two lines of text wherever you point with the cursor.
	Terminate by pressing any mouse button."

	"DisplayText textSampler."

	| t |
	t _ 'this is a line of characters and
this is the second line.' asDisplayText.
	[Sensor anyButtonPressed]
		whileFalse:
			[t displayOn: Display at: Sensor cursorPoint]! !