'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:51 pm'!

DisplayObject subclass: #Path
	instanceVariableNames: 'form collectionOfPoints '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Display Objects'!
Path comment:
'Class Path is the basic superclass of the graphic spatial primitives.  Spatial primitives are used to generate "trajactories" or paths like lines and circles.
	
Instance Variables:
	form 	<Form> the "brush" used for displaying the path
	collectionOfPoints	<OrderedCollection> of Points along the path
'!


!Path methodsFor: 'adding'!

add: aPoint 
	"Include aPoint as one of the receiver's elements."

	collectionOfPoints add: aPoint! !

!Path methodsFor: 'removing'!

removeAllSuchThat: aBlock 
	"Evaluate aBlock with each of the collectionOfPoints's as the argument.
	 Remove each point for which aBlock evaluates to true.
	 Answer the new instance of receiver's class."

	| newCollection newPath |
	newPath _ self species new.
	newCollection _ collectionOfPoints removeAllSuchThat: aBlock.
	newCollection do: [:point | newPath add: point].
	newPath form: self form.
	^newPath! !

!Path methodsFor: 'enumerating'!

collect: aBlock 
	"Evaluate aBlock with each of the collectionOfPoints's as the argument. 
	Collect the resulting values into a new collectionOfPoints.  Answer the 
	new instance of receivers' class."

	| newCollection newPath |
	newPath _ self species new.
	newCollection _ collectionOfPoints collect: aBlock.
	newCollection do: [:point | newPath add: point].
	newPath form: self form.
	^newPath!

select: aBlock 
	"Evaluate aBlock with each of the collectionOfPoints's as the argument. 
	Collect into a new collectionOfPoints, only those elements for which aBlock 
	evaluates to true.  Answer the new instance of receivers' class."

	| newCollection newPath |
	newPath _ self species new.
	newCollection _ collectionOfPoints select: aBlock.
	newCollection do: [:point | newPath add: point].
	newPath form: self form.
	^newPath! !

!Path methodsFor: 'testing'!

isEmpty
	"Answer whether the receiver contains any elements."

	^collectionOfPoints isEmpty! !

!Path methodsFor: 'accessing'!

at: index 
	"Answer the point on the receiver's path at position index."

	^collectionOfPoints at: index!

at: index put: aPoint 
	"Store the argument, aPoint, as the point on the receiver's path at 
	position index."

	^collectionOfPoints at: index put: aPoint!

first
	"Answer the first point on the receiver's path."

	^collectionOfPoints first!

firstPoint
	"Answer the first point on the receiver's path."

	^collectionOfPoints first!

firstPoint: aPoint 
	"Answer the argument aPoint.  Replace the first element of the receiver
	with the new value aPoint."

	collectionOfPoints at: 1 put: aPoint.
	^aPoint!

form
	"Answer the receiver's form. If form is nil then a 1 x 1 black form (a 
	black dot) is answered."

	| aForm |
	form == nil
		ifTrue: 
			[aForm _ Form new extent: 1 @ 1.
			aForm black.
			^aForm]
		ifFalse: 
			[^form]!

form: aForm 
	"Make the argument, aForm, the receiver's form."

	form _ aForm!

last
	"Answer the last point on the receiver's path."

	^collectionOfPoints last!

offset
	"There are basically two kinds of display objects in the system:  those that, when 
	asked to transform themselves, create a new object;  and those that side effect 
	themselves by maintaining a record of the transformation request (typically 
	an offset).  Path, like Rectangle and Point, is a display object of the first kind."

	self shouldNotImplement!

secondPoint
	"Answer the second element of the receiver."

	^collectionOfPoints at: 2!

secondPoint: aPoint 
	"Answer the argument aPoint.  Replace the second element of the receiver
	with the new value aPoint."

	collectionOfPoints at: 2 put: aPoint.
	^aPoint!

size
	"Answer how many elements the receiver contains."

	^collectionOfPoints size!

thirdPoint
	"Answer the third element of the receiver."

	^collectionOfPoints at: 3!

thirdPoint: aPoint 
	"Answer the argument aPoint.  Replace the third element of the receiver
	with the new value aPoint."

	collectionOfPoints at: 3 put: aPoint.
	^aPoint! !

!Path methodsFor: 'displaying'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm 
	"Display this Path--offset by aDisplayPoint, clipped by clipRectangle and the form 
	associated with this Path will be displayed according to one of the sixteen 
	functions of two logical variables (ruleInteger).  Also the source form will be first 
	ANDed with aForm as a mask.  Does not effect the state of the Path."

	collectionOfPoints do: 
		[:element | 
		self form
			displayOn: aDisplayMedium
			at: element + aDisplayPoint
			clippingBox: clipRectangle
			rule: ruleInteger
			mask: aForm]!

displayOn: aDisplayMedium transformation: displayTransformation clippingBox:
clipRectangle rule: ruleInteger mask: aForm 
	"Displays this path, translated and scaled by aTransformation."
	"get the scaled and translated Path."

	| transformedPath |
	transformedPath _ displayTransformation applyTo: self.
	transformedPath
		displayOn: aDisplayMedium
		at: 0 @ 0
		clippingBox: clipRectangle
		rule: ruleInteger
		mask: aForm! !

!Path methodsFor: 'display box access'!

computeBoundingBox

	| box computedOrigin computedExtent |
	form == nil
	     ifTrue: [computedOrigin _ 0@0.
		  		computedExtent _ 0@0]
		ifFalse: [computedOrigin _ form offset.
			     computedExtent _ form extent].
	box _ Rectangle origin: (self at: 1) + computedOrigin extent: computedExtent.
	collectionOfPoints do:
		[:aPoint | box _ box merge: (Rectangle origin: aPoint + computedOrigin extent: computedExtent)].
	^box! !

!Path methodsFor: 'transforming'!

scaleBy: aPoint 
	"Answers with a new Path scaled by aPoint.  Does not effect the current data in
	this Path."

	| newPath |
	newPath _ self species new: self size.
	newPath form: self form.
	collectionOfPoints do: 
		[:element | 
		newPath add: 
				(aPoint x * element x) truncated @ (aPoint y * element y) truncated].
	^newPath!

translateBy: aPoint 
	"Answers with a new instance of Path whose elements are translated by aPoint.  
	Does not effect the elements of this Path."

	| newPath |
	newPath _ self species new: self size.
	newPath form: self form.
	collectionOfPoints do: 
		[:element | 
		newPath add: 
			(element x + aPoint x) truncated @ (element y + aPoint y) truncated].
	^newPath! !

!Path methodsFor: 'private: private'!

initializeCollectionOfPoints
	"Initialize the collection of points on the path to be empty."

	collectionOfPoints _ OrderedCollection new!

initializeCollectionOfPoints: anInteger 
	"Initialize the collection of points on the path to have potential anInteger elements."

	collectionOfPoints _ OrderedCollection new: anInteger! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Path class
	instanceVariableNames: ''!


!Path class methodsFor: 'instance creation'!

new
	"Answer a new instance of the receiver that is an empty sequence."

	^self basicNew initializeCollectionOfPoints!

new: anInteger 
	"Answer a new instance of the receiver that has
	initially anInteger elements in its sequence."

	^self basicNew initializeCollectionOfPoints: anInteger! !

!Path class methodsFor: 'examples'!

pathSampler
	"Creates a Path from mouse points and displays it several ways on the display 
	screen.  Messes up the display.   Each path displays using a different form.  
	A path is indicated by pressing the red mouse button in sequence;  press any other 
	mouse button to terminate."
	"Path pathSampler"

	| aPath aForm p1 f1 flag |
	aForm _ Form new extent: 2 @ 40.
	"creates a form one inch long"
	aForm black.
	"turns it black"
	aPath _ Path new.
	aPath form: aForm.
	"use the long black form for display"
	flag _ true.
	[flag]
		whileTrue: 
			[Sensor waitButton.
			Sensor redButtonPressed
				ifTrue: 
					[aPath add: Sensor waitButton.
					Sensor waitNoButton.
					aForm displayOn: Display at: aPath last]
				ifFalse: [flag _ false]].
	Display white.
	aPath displayOn: Display.			"the original path"
	p1 _ aPath translateBy: 0 @ 300.
	f1 _ Form new extent: 40 @ 40.
	f1 gray.
	p1 form: f1.
	p1 displayOn: Display.		"the translated path"
	Sensor waitNoButton! !