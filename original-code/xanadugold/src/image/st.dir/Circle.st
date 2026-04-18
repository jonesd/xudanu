'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:52 pm'!

Arc subclass: #Circle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Paths'!
Circle comment:
'A full circle is made from four arcs.  Class Circle modifies the Arc methods for displaying.'!


!Circle methodsFor: 'displaying'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm 
	"Display the receiver on the display medium aDisplayMedium positioned 
	at aDisplayPoint within the rectangle clipRectangle and with the rule, 
	ruleInteger, and mask, aForm. "

	1 to: 4 do: 
		[:i | 
		super quadrant: i.
		super
			displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipRectangle
			rule: ruleInteger
			mask: aForm]!

displayOn: aDisplayMedium transformation: aTransformation clippingBox: clipRect rule: anInteger mask: aForm 
	"Display the receiver, translated and scaled by aTransformation, 
	displaying with combination rule ruleInteger, masked by aForm, and 
	clipped with the rectangle clipRectangle."

	1 to: 4 do: 
		[:i | 
		super quadrant: i.
		super
			displayOn: aDisplayMedium
			transformation: aTransformation
			clippingBox: clipRect
			rule: anInteger
			mask: aForm]! !

!Circle methodsFor: 'display box access'!

computeBoundingBox
	"Answer the minimum enclosing rectangle around the image."

	^center - radius + form offset extent: form extent + (radius * 2) asPoint! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Circle class
	instanceVariableNames: ''!


!Circle class methodsFor: 'examples'!

exampleOne 
	"Click any button somewhere on the screen.  The point will be the
	center of the circle of radius 150."
	"Circle exampleOne."

	| aCircle aForm |
	aForm _ Form new extent: 1@30.
	aForm black.
	aCircle _ Circle new.
	aCircle form: aForm.
	aCircle radius: 150.
	aCircle center: Sensor waitButton.
	aCircle displayOn: Display!

exampleTwo
	"Designate a rectangular area that should be used as the brush for displaying the 
	circle. Click any button at a point on the screen which will be the center location
	for the circle.  The curve will be displayed with a long black form."
	 
	 "Circle exampleTwo."

	| aCircle aForm |
	aForm _ Form fromUser.
	aCircle _ Circle new.
	aCircle form: aForm.
	aCircle radius: 150.
	aCircle center: Sensor waitButton.
	aCircle displayOn: Display at: 0 @ 0 rule: Form reverse! !