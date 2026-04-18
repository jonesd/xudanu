'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:52 pm'!

Path subclass: #Arc
	instanceVariableNames: 'quadrant radius center '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Paths'!
Arc comment:
'Class Arc represents a quarter of a Circle, the quadrant is specified by 1, 2, 3 or 4 points which indicate which part of the circle is to be displayed. Quadrants are numbered 1 - 4 counter clockwise.

Instance Variables:
	quadrant	<Integer> 1 - 4 representing a part of the circle
	radius	<Integer> length of the Circle radius
	center	<Point> position at the center of the Circle'!


!Arc methodsFor: 'accessing'!

center
	"Answer the point at the center of the receiver."

	^center!

center: aPoint 
	"Set aPoint to be the receiver's center."

	center _ aPoint!

center: aPoint radius: anInteger 
	"The receiver is defined by a point at the center and a radius.
	The quadrant is not reset."

	center _ aPoint.
	radius _ anInteger!

center: aPoint radius: anInteger quadrant: section 
	"The receiver is an Arc for the quadrant specified by section.  The size of
	the arc is defined by the center and its radius."

	center _ aPoint.
	radius _ anInteger.
	quadrant _ section!

quadrant
	"Answer the section of a circle represented by the receiver."

	^quadrant!

quadrant: section 
	"Set section to be the part of the circle represented by the receiver."

	quadrant _ section!

radius
	"Answer the receiver's radius."

	^radius!

radius: anInteger 
	"Set anInteger to be the receiver's radius."

	radius _ anInteger! !

!Arc methodsFor: 'displaying'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm 
	"Display the receiver on the display medium aDisplayMedium positioned at aDisplayPoint within 
	the rectangle clipRectangle and with the rule, ruleInteger, and mask, aForm. "

	| nSegments line angle sin cos xn yn xn1 yn1 |
	nSegments _ 12.0.
	line _ Line new.
	line form: self form.
	angle _ 90.0 / nSegments.
	sin _ (angle * (2 * Float pi / 360.0)) sin.
	cos _ (angle * (2 * Float pi / 360.0)) cos.
	quadrant = 1
		ifTrue: 
			[xn _ radius asFloat.
			yn _ 0.0].
	quadrant = 2
		ifTrue: 
			[xn _ 0.0.
			yn _ 0.0 - radius asFloat].
	quadrant = 3
		ifTrue: 
			[xn _ 0.0 - radius asFloat.
			yn _ 0.0].
	quadrant = 4
		ifTrue: 
			[xn _ 0.0.
			yn _ radius asFloat].
	nSegments truncated
		timesRepeat: 
			[xn1 _ xn * cos + (yn * sin).
			yn1 _ yn * cos - (xn * sin).
			line beginPoint: center + (xn truncated @ yn truncated).
			line endPoint: center + (xn1 truncated @ yn1 truncated).
			line
				displayOn: aDisplayMedium
				at: aDisplayPoint
				clippingBox: clipRectangle
				rule: ruleInteger
				mask: aForm.
			xn _ xn1.
			yn _ yn1]! !

!Arc methodsFor: 'transforming'!

scaleBy: aPoint 
	"Answers with a new Arc scaled by aPoint.  Does not effect the current data in 
	this Arc."

	| newArc tempCenter |
	newArc _ super scaleBy: aPoint.
	newArc center: self center.
	newArc radius: (self radius * aPoint x) truncated.
	newArc quadrant: self quadrant.
	^newArc!

translateBy: aPoint 
	"Answers with a new instance of Arc whose elements are translated by aPoint.  
	Does not effect the elements of this Arc."

	| newArc |
	newArc _ super translateBy: aPoint.
	newArc center: (self center x + aPoint x) @ (self center y + aPoint y).
	newArc radius: self radius.
	newArc quadrant: self quadrant.
	^newArc! !

!Arc methodsFor: 'display box access'!

computeBoundingBox 

	| origin |
	quadrant = 1 ifTrue: [origin _ center - (0 @ radius)].
	quadrant = 2 ifTrue: [origin _ center - (radius @ radius)].
	quadrant = 3 ifTrue: [origin _ center - (radius @ 0)].
	quadrant = 4 ifTrue: [origin _ center].
	^Rectangle origin: origin + self form offset extent: radius @ radius + form
extent! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Arc class
	instanceVariableNames: ''!


!Arc class methodsFor: 'examples'!

arcDraw
	"Click the button somewhere on the screen.  The designated point will
	be the center of an Arc with radius 50 in the 4th quadrant."

	"Arc arcDraw."

	| anArc aForm |
	aForm _ Form new extent: 1 @ 30.	"make a long thin Form for display"
	aForm black.						"turn it black"
	anArc _ Arc new.
	anArc form: aForm.					"set the form for display"
	anArc radius: 50.0.
	anArc center: Sensor waitButton.
	anArc quadrant: 4.
	anArc displayOn: Display.
	Sensor waitButton! !