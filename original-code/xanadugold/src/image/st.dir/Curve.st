'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:53 pm'!

Path subclass: #Curve
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Paths'!
Curve comment:
'Class Curve is a subclass of Path that is a conic section determined by: three points p1,p2 and p3 that interpolates p1 and p3 and is tangent to p1,p2 and p3,p2 at p1 and p3 respectively.'!


!Curve methodsFor: 'displaying'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm
	"Display the receiver on the display medium aDisplayMedium positioned at aDisplayPoint within 
	the rectangle clipRectangle and with the rule, ruleInteger, and mask, aForm. "

	| pa pb k s p1 p2 p3 line |
	line _ Line new.
	line form: self form.
	collectionOfPoints size < 3 ifTrue: [self error: 'Curve must have three points'].
	p1 _ self firstPoint.
	p2 _ self secondPoint.
	p3 _ self thirdPoint.
	s _ Path new.
	s add: p1.
	pa _ p2 - p1.
	pb _ p3 - p2.
	k _ 5 max: pa x abs + pa y abs + pb x abs + pb y abs // 20.
	"k is a guess as to how many line segments to use to approximate 
	the curve."
	1 to: k do: 
		[:i | 
		s add: pa * i // k + p1 * (k - i) + (pb * (i - 1) // k + p2 * (i - 1)) // (k - 1)].
	s add: p3.
	1 to: s size - 1 do: 
		[:i | 
		line beginPoint: (s at: i).
		line endPoint: (s at: i + 1).
		line displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipRectangle
			rule: ruleInteger
			mask: aForm]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Curve class
	instanceVariableNames: ''!


!Curve class methodsFor: 'instance creation'!

new
	"Answer a new instance of the receiver that is essentially a single point
	at the upper left corner of the screen."

	| newSelf | 
	newSelf _ super new: 3.
	newSelf add: 0@0.
	newSelf add: 0@0.
	newSelf add: 0@0.
	^newSelf! !

!Curve class methodsFor: 'examples'!

sampleCurve
	"Designate three locations on the screen by clicking any button.  The curve
	determined by the points will be displayed with a long black form."

	"Curve sampleCurve."

	| aCurve aForm |  
	aForm _ Form new extent: 1@30.			"make a long thin Form for display "
	aForm black.								"turn it black"
	aCurve _ Curve new.
	aCurve form: aForm.						"set the form for display"
				"collect three Points and show them on the dispaly"
	aCurve firstPoint: Sensor waitButton. Sensor waitNoButton.
	aForm displayOn: Display at: aCurve firstPoint.
	aCurve secondPoint: Sensor waitButton. Sensor waitNoButton.
	aForm displayOn: Display at: aCurve secondPoint.
	aCurve thirdPoint: Sensor waitButton. Sensor waitNoButton.
	aForm displayOn: Display at: aCurve thirdPoint.

	aCurve displayOn: Display					"display the Curve"! !