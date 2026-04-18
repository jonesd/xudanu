'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:45 pm'!

DisplayObject subclass: #DisplayMedium
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Display Objects'!
DisplayMedium comment:
'The abstract class DisplayMedium represents a display object which can both paint itself on a medium (such as Display) and can act as a medium itself.  Its chief subclass is Form.

Subclasses must implement methods for
	coloring
		fill:rule:mask: 
	displaying
		copyBits:from:at:clippingBox:rule:mask:
		drawLine:from:to:clippingBox:rule:mask:'!


!DisplayMedium methodsFor: 'coloring'!

black
	"Set all bits in the receiver to black (ones)."

	self fill: self boundingBox
		mask: Form black!

black: aRectangle 
	"Set all bits in the receiver's area defined by aRectangle to black (ones)."

	self fill: aRectangle rule: Form over mask: Form black!

darkGray
	"Set all bits in the receiver to darkGray."

	self fill: self boundingBox
		mask: Form darkGray!

darkGray: aRectangle
	"Set all bits in the receiver's area defined by aRectangle to the darkGray mask."

	self fill: aRectangle rule: Form over mask: Form darkGray!

fill: aRectangle 
	"Fill aRectangle with the default background, Form gray."

	self fill: aRectangle rule: Form over mask: Form gray!

fill: aRectangle mask: aForm 
	"Replace a rectangular area of the receiver with the pattern described by aForm 
	according to the rule over."

	self fill: aRectangle rule: Form over mask: aForm!

fill: aRectangle rule: anInteger mask: aForm 
	"Replace a rectangular area of the receiver with the pattern described by aForm 
	according to the rule anInteger."

	self subclassResponsibility!

gray
	"Set all bits in the receiver to gray."

	self fill: self boundingBox
		mask: Form gray!

gray: aRectangle
	"Set all bits in the receiver's area defined by aRectangle to the gray mask."

	self fill: aRectangle rule: Form over mask: Form gray!

lightGray
	"Set all bits in the receiver to lightGray."

	self fill: self boundingBox
		mask: Form lightGray!

lightGray: aRectangle
	"Set all bits in the receiver's area defined by aRectangle to the lightGray mask."

	self fill: aRectangle rule: Form over mask: Form lightGray!

reverse
	"Change all the bits in the receiver that are white to black, and the ones
	that are black to white."

	self fill: self boundingBox
		rule: Form reverse
		mask: Form black!

reverse: aRectangle
	"Change all the bits in the receiver's area that intersects with aRectangle
	that are white to black, and the ones that are black to white."

	self fill: aRectangle rule: Form reverse mask: Form black!

reverse: aRectangle mask: aMask	
	"Change all the bits in the receiver's area that intersect with aRectangle
	according to the mask.  Black does not necessarily turn to white, rather it
	changes with respect to the rule and the bit in a corresponding mask location.
	Bound to give a surprise."

	self fill: aRectangle rule: Form reverse mask: aMask!

veryLightGray
	"Set all bits in the receiver to veryLightGray."

	self fill: self boundingBox
		mask: Form veryLightGray!

veryLightGray: aRectangle
	"Set all bits in the receiver's area defined by aRectangle to the veryLightGray mask."

	self fill: aRectangle rule: Form over mask: Form veryLightGray!

white
	"Set all bits in the form to white (i.e., to zeros)."

	self fill: self boundingBox
		mask: Form white!

white: aRectangle
	"Set all bits in the receiver's area defined by aRectangle to white (i.e., to zeros)."

	self fill: aRectangle rule: Form over mask: Form white! !

!DisplayMedium methodsFor: 'bordering'!

border: aRectangle width: borderWidth 
	"Paint a border whose rectangular area is defined by aRectangle.  The width of
	the border of each side is borderWidth.  Uses Form black for drawing the border."

	self border: aRectangle
		width: borderWidth
		mask: Form black!

border: aRectangle width: borderWidth mask: aHalfTone 
	"Paint a border whose rectangular area is defined by aRectangle.  The width of
	the border of each side is borderWidth.  Uses aHalfTone for drawing the border."

	self border: aRectangle
		widthRectangle: 
			(Rectangle
				left: borderWidth
				right: borderWidth
				top: borderWidth
				bottom: borderWidth)
		mask: aHalfTone!

border: aRectangle width: borderWidth rule: aRule mask: aHalfTone 
	"Paint a border whose rectangular area is defined by aRectangle.  The width of
	the border of each side is borderWidth.  Uses aHalfTone for drawing the border."

	self border: aRectangle
		widthRectangle: 
			(Rectangle
				left: borderWidth
				right: borderWidth
				top: borderWidth
				bottom: borderWidth)
		rule: aRule
		mask: aHalfTone!

border: aRectangle widthRectangle: insets mask: aHalfTone 
	"Paint a border whose rectangular area is defined by aRectangle.  The width of
	each edge of the border is determined by the four coordinates of insets.
	Uses aHalfTone for drawing the border."

	(aRectangle areasOutside: (aRectangle insetBy: insets)) do:
		[:edgeStrip | self fill: edgeStrip mask: aHalfTone]!

border: aRectangle widthRectangle: insets mask: aHalfTone clippingBox: clipRect
	"Paint a border whose rectangular area is defined by aRectangle.  The width of
	each edge of the border is determined by the four coordinates of insets.
	Uses aHalfTone for drawing the border."

	(aRectangle areasOutside: (aRectangle insetBy: insets)) do:
		[:edgeStrip | self fill: (edgeStrip intersect: clipRect) mask: aHalfTone]!

border: aRectangle widthRectangle: insets rule: aRule mask: aHalfTone 
	"Paint a border whose rectangular area is defined by aRectangle.  The width of
	each edge of the border is determined by the four coordinates of insets.
	Uses aHalfTone for drawing the border."

	(aRectangle areasOutside: (aRectangle insetBy: insets)) do:
		[:edgeStrip | self fill: edgeStrip rule: aRule mask: aHalfTone]! !

!DisplayMedium methodsFor: 'displaying'!

copyBits: sourceRect from: sourceForm at: destOrigin clippingBox: clipRect rule: rule mask: aForm 
	"Copy into the rectangle sourceRect within the receiver those pits from the form
	sourceForm starting at position destOrigin according to the mixing rule rule and with
	aForm as the mask.  Clip the receiver's destination rectangle with respect to clipRect."

	self subclassResponsibility!

display: aDisplayObject
	"The receiver places the argument aDisplayObject on itself at its relative origin."

	self display: aDisplayObject at: 0@0!

display: aDisplayObject at: aPoint
	"The receiver places the argument aDisplayObject on itself at aPoint."

	aDisplayObject displayOn: self at: aPoint!

drawLine: sourceForm from: beginPoint to: endPoint clippingBox: clipRect rule: anInteger mask: aForm 
	"Affect the receiver by modifying its contents so as to effectively
	draw a straight line starting at beginPoint (a position relative to the receiver) and
	ending at endPoint, according to the combination rule anInteger, masked by
	aForm and clipped by clipRect.  Each position on the line is drawn with the
	form sourceForm."
	
	self subclassResponsibility!

drawLine: sourceForm from: beginPoint to: endPoint rule: anInteger
	"Affect the receiver by modifying its contents so as to effectively
	draw a straight line starting at beginPoint (a position relative to the receiver) and
	ending at endPoint, according to the combination rule anInteger, masked by
	aForm and clipped by clipRect.  Each position on the line is drawn with the
	form sourceForm."
	
	self drawLine: sourceForm from: beginPoint to: endPoint clippingBox: self boundingBox rule: anInteger mask: nil! !