'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:43 pm'!

Rectangle subclass: #Quadrangle
	instanceVariableNames: 'borderWidth borderColor insideColor '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Primitives'!
Quadrangle comment:
'Class Quadrangle represents a particular kind of Rectangle that has a border and inside color.

Instance Variables:
	borderWidth	<Rectangle> representing the left, right, top, bottom border widths
	borderColor		<Form> color of the outside rectangular border
	insideColor 		<Form> color of the inside background area
'!


!Quadrangle methodsFor: 'initialize-release'!

initialize
	"Initialize the region to a null Rectangle, the border width to 1, the  
	border color to black, and the inside color to white."

	origin _ 0 @ 0.
	corner _ 0 @ 0.
	borderWidth _ 1.
	borderColor _ Form black.
	insideColor _ Form white! !

!Quadrangle methodsFor: 'bordering'!

borderColor
	"Answer the border color of the receiver."

	^borderColor!

borderColor: aColor 
	"Set the border color of the receiver to aColor."

	borderColor _ aColor!

borderWidth
	"Answer the border width of the receiver."

	^borderWidth!

borderWidth: anInteger 
	"Set the border width of the receiver to anInteger."

	borderWidth _ anInteger!

borderWidthLeft: anInteger1 right: anInteger2 top: anInteger3 bottom: anInteger4
	"Set the border width of the receiver so that the arguments denote the left, 
	right, top, and bottom border widths."

	borderWidth _ anInteger1 @ anInteger3 corner: anInteger2 @ anInteger4!

inside
	"Answer a Rectangle that is the receiver inset by the border width."

	^self insetBy: borderWidth!

insideColor
	"Answer the inside color of the receiver."

	^insideColor!

insideColor: aColor 
	"Set the inside color of the receiver to the argument aColor."

	insideColor _ aColor!

region
	"Answer a Rectangle that defines the area of the receiver."

	^origin corner: corner!

region: aRectangle 
	"Set the rectangular area of the receiver to aRectangle."

	origin _ aRectangle origin.
	corner _ aRectangle corner! !

!Quadrangle methodsFor: 'displaying'!

display
	"Display the border and inside region of the receiver."

	self displayOn: Display!

displayAlign: aPoint1 with: aPoint2 clippingBox: aRectangle 
	"Display the border and region of the reciever so that its position at
	aPoint1 is aligned with position aPoint2.  The displayed information should
	be clipped so that only information with the area determined by aRectangle
	is displayed."

	| savedRegion |
	savedRegion _ self region.
	self region: ((savedRegion align: aPoint1 with: aPoint2) intersect: aRectangle).
	self displayOn: Display.
	self region: savedRegion!

displayOn: aDisplayMedium 
	"Display the border and insideRegion of the receiver."

	insideColor ~~ nil ifTrue: [aDisplayMedium fill: self inside mask: insideColor].
	borderWidth ~~ 0 & (insideColor ~~ nil) ifTrue: [aDisplayMedium
			border: self region
			widthRectangle: borderWidth
			mask: borderColor]!

displayOn: aDisplayMedium align: aPoint1 with: aPoint2 clippingBox: aRectangle 
	"Display the border and region of the reciever so that its position at
	aPoint1 is aligned with position aPoint2.  The displayed information should
	be clipped so that only information with the area determined by aRectangle
	is displayed."

	| savedRegion |
	savedRegion _ self region.
	self region: ((savedRegion align: aPoint1 with: aPoint2) intersect: aRectangle).
	self displayOn: aDisplayMedium.
	self region: savedRegion!

displayOn: aDisplayMedium transformation: aWindowingTransformation clippingBox: aRectangle 
	"Display the border and region of the reciever so that it is scaled and 
	translated with respect to aWindowingTransformation. The displayed 
	information should be clipped so that only information with the area 
	determined by aRectangle is displayed."

	| screenRectangle |
	screenRectangle _ (aWindowingTransformation applyTo: self)
				intersect: aRectangle.
	borderWidth ~~ 0 & (insideColor ~~ nil)
		ifTrue: [borderWidth isInteger
				ifTrue: [aDisplayMedium
						border: screenRectangle
						width: borderWidth
						mask: borderColor]
				ifFalse: [aDisplayMedium
						border: screenRectangle
						widthRectangle: borderWidth
						mask: borderColor].
			aDisplayMedium fill: (screenRectangle insetBy: borderWidth) mask: insideColor]! !

!Quadrangle methodsFor: 'rectangle functions'!

intersect: aRectangle 
	"Answer a new Quadrangle whose region is the intersection of the 
	receiver's area and aRectangle."

	^ self species
	 	region: (super intersect: aRectangle)
		borderWidth: borderWidth
		borderColor: borderColor
		insideColor: insideColor! !

!Quadrangle methodsFor: 'transforming'!

adjustInsideHeightToMultipleOf: anInteger 
	"Answer a new Quadrangle that is a copy of the receiver with the rectangular
area changed so that its hight is a multiple of the argument anInteger."

	| inside |
	inside _ self inside.
	^self species
		region: ((inside height: inside height - (inside height \\ anInteger))
				expandBy: borderWidth)
		borderWidth: borderWidth
		borderColor: borderColor
		insideColor: insideColor!

align: aPoint1 with: aPoint2 
	"Answer a new Quadrangle translated by aPoint2 - aPoint1."

	^ self species
		region: (super translateBy: aPoint2 - aPoint1)
		borderWidth: borderWidth
		borderColor: borderColor
		insideColor: insideColor!

scaleBy: aPoint 
	"Answer a new Quadrangle whose rectangular area is
	scaled by the argument aPoint."

	^ self species
		region: (super scaleBy: aPoint)
		borderWidth: borderWidth
		borderColor: borderColor
		insideColor: insideColor!

translateBy: aPoint 
	"Answer a new Quadrangle whose rectangular area is
	translated by aPoint."

	^ self species
		region: (super translateBy: aPoint)
		borderWidth: borderWidth
		borderColor: borderColor
		insideColor: insideColor! !

!Quadrangle methodsFor: 'private: private'!

region: aRectangle borderWidth: anInteger borderColor: aMask1 insideColor: aMask2
	"Initialize the instance variables."

	origin _ aRectangle origin.
	corner _ aRectangle corner.
	borderWidth _ anInteger.
	borderColor _ aMask1.
	insideColor _ aMask2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Quadrangle class
	instanceVariableNames: ''!


!Quadrangle class methodsFor: 'instance creation'!

new
	"Answer an instance of the receiver, initialized to a null Rectangle, 
	with border width of 1, border color of black, and inside color of white."

	^super new initialize!

region: aRectangle borderWidth: anInteger borderColor: aMask1 insideColor: aMask2
	"Answer an instance of the receiver with rectangle, border width and color, and 
	inside color determined by the arguments."

	^super new
		region: aRectangle
		borderWidth: anInteger
		borderColor: aMask1
		insideColor: aMask2! !