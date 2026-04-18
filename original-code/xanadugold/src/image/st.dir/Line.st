'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:53 pm'!

Path subclass: #Line
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Paths'!
Line comment:
'Class Line represents a straight line or path through two points. '!


!Line methodsFor: 'accessing'!

beginPoint
	"Answer the first end point of the receiver."

	^self first!

beginPoint: aPoint 
	"Set the first end point of the receiver. Answer the argument, aPoint."

	self at: 1 put: aPoint.
	^aPoint!

endPoint
	"Answer the first end point of the receiver."

	^self last!

endPoint: aPoint 
	"Set the first end point of the receiver."

	self at: 2 put: aPoint.
	^aPoint! !

!Line methodsFor: 'displaying'!

displayOn: aDisplayMedium at: aPoint clippingBox: clipRect rule: anInteger mask: aForm 
	"The form associated with this Path will be displayed, according  
	to one of the sixteen functions of two logical variables (rule), at  
	each point on the Line. Also the source form will be first ANDed  
	with aForm as a mask. Does not effect the state of the Path."

	collectionOfPoints size < 2 ifTrue: [self error: 'a line must have two points'].
	aDisplayMedium
		drawLine: self form
		from: self beginPoint + aPoint
		to: self endPoint + aPoint
		clippingBox: clipRect
		rule: anInteger
		mask: aForm! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Line class
	instanceVariableNames: ''!


!Line class methodsFor: 'instance creation'!

from: beginPoint to: endPoint withForm: aForm
	"Answer a new instance of the receiver with end points beginPoint and
	endPoint such that the image is drawn using the drawing nib aForm."

	| newSelf | 
	newSelf _ super new: 2.
	newSelf add: beginPoint.
	newSelf add: endPoint.
	newSelf form: aForm.
	^newSelf!

new 
	"Answer a new instance of the receiver that is essential a single point
	at the upper left corner of the screen."

	| newSelf | 
	newSelf _ super new: 2.
	newSelf add: 0@0.
	newSelf add: 0@0.
	^newSelf! !

!Line class methodsFor: 'examples'!

sampleLine
	"Designate two places on the screen by clicking any mouse button.
	A straight path with a square black form will be displayed connecting the
	two selected points."

	"Line sampleLine."

	| aLine aForm |  
	aForm _ Form new extent: 20@20.		"make a form one quarter of inch square"
	aForm black.							"turn it black"
	aLine _ Line new.
	aLine form: aForm.						"use the black form for display"
	aLine beginPoint: Sensor waitButton. Sensor waitNoButton.
	aForm displayOn: Display at: aLine beginPoint.	
	aLine endPoint: Sensor waitButton.
	aLine displayOn: Display.				"display the line"! !