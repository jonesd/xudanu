'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:49 pm'!

DisplayObject subclass: #OpaqueForm
	instanceVariableNames: 'figure shape '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Display Objects'!
OpaqueForm comment:
'OpaqueForms include a shape as well as a figure form.  The shape indicates what part of the background should get occluded in displaying, so that patterns other than black in the figure form will still appear opaque.

Instance Variables:
	figure	<Form> the actual image
	shape	<Form> the mask for displaying'!


!OpaqueForm methodsFor: 'accessing'!

figure
	"Answer the visible image of the receiver."

	^ figure!

offset
	"Answer the offset for displaying the image."

	^ figure offset!

shape
	"Answer the form that indicates what part of the background should 
	get occluded in displaying the receiver."

	^ shape!

valueAt: aPoint 
	"Answer the bit of the form image at position aPoint.  The value is
	either 0, 1 or 2 where 0 is white, 1 is black,  2 is transparent."

	(shape valueAt: aPoint) = 1
		ifTrue: [^ figure valueAt: aPoint]  "opaque"
		ifFalse: [^ 2 + (figure valueAt: aPoint)]  "background shows through"!

valueAt: aPoint put: value
	"Store a bit of the form image at position aPoint.  The value is
	either 0, 1 or 2 where 0 is white, 1 is black,  2 is transparent."

	shape valueAt: aPoint put: 1 - (value//2).
	figure valueAt: aPoint put: value\\2! !

!OpaqueForm methodsFor: 'displaying'!

copyBits: copyRect from: sourceForm at: destPoint clippingBox: clipRect rule: rule mask: mask
	"Copy into the rectangle sourceRect within the receiver those pits from the form
	sourceForm starting at position destOrigin according to the mixing rule rule and with
	aForm as the mask.  Clip the receiver's destination rectangle with respect to clipRect."

	| sourceFigure sourceShape |
	(sourceForm isMemberOf: OpaqueForm)
		ifTrue:
			[sourceFigure _ sourceForm figure.
			sourceShape _ sourceForm shape]
		ifFalse: [sourceFigure _ sourceShape _ sourceForm].
	figure copyBits: copyRect
		from: sourceFigure
		at: destPoint
		clippingBox: clipRect
		rule: rule
		mask: mask.
	shape copyBits: copyRect
		from: sourceShape
		at: destPoint
		clippingBox: clipRect
		rule: rule
		mask: mask!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm
	"Display the receiver on the display medium aDisplayMedium positioned at aDisplayPoint within 
	the rectangle clipRectangle and with the rule, ruleInteger, and mask, aForm. "

	shape displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: Form erase mask: nil.
	figure displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: Form under mask: aForm!

displayOn: aDisplayMedium transformation: displayTransformation clippingBox:
clipRectangle align: alignmentPoint with: relativePoint rule: ruleInteger mask:
aForm 
	"See comment in Form."

	shape displayOn: aDisplayMedium transformation: displayTransformation
clippingBox: clipRectangle align: alignmentPoint with: relativePoint rule: Form
erase mask: nil.
	figure displayOn: aDisplayMedium transformation: displayTransformation
clippingBox: clipRectangle align: alignmentPoint with: relativePoint rule: Form
under mask: aForm! !

!OpaqueForm methodsFor: 'display box access'!

computeBoundingBox
	"Answer the minimum enclosing rectangle around the image."

	^figure boundingBox! !

!OpaqueForm methodsFor: 'editing'!

bitEdit
	"Create and schedule a view located in an area designated by the user that
	contains a view of the receiver magnified by 8@8 that can be modified
	using the Bit Editor.  It also contains a view of the original form."

	BitEditor openOnForm: self

	"OpaqueForm makeStar bitEdit."! !

!OpaqueForm methodsFor: 'printing'!

storeOn: aStream
	"Append to the argument aStream a sequence of characters that is an expression 
	whose evaluation creates an object similar to the receiver.  The general format
	for OpaqueForm is
		OpaqueForm figure: ( figure ) shape: ( shape )."

	aStream nextPutAll: '(OpaqueForm figure: ('.
	figure storeOn: aStream.
	aStream nextPutAll: ') shape: ('.
	shape storeOn: aStream.
	aStream nextPutAll: '))'! !

!OpaqueForm methodsFor: 'private: private'!

setFigure: figureForm shape: shapeForm
	"Initialize the instance variables."

	figure _ figureForm.
	shape _ shapeForm! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

OpaqueForm class
	instanceVariableNames: ''!


!OpaqueForm class methodsFor: 'instance creation'!

figure: figureForm shape: shapeForm
	"Answer a new instance of the receiver whose figure
	and shape forms are defined by the arguments."

	^ self new setFigure: figureForm shape: shapeForm!

shape: aSolidForm
	"Answer a new instance of the receiver that is black where aSolidForm is black
	and transparent where aSolidForm is white."

	^ self new setFigure: aSolidForm shape: aSolidForm! !

!OpaqueForm class methodsFor: 'examples'!

makeStar
	"Answer a new OpaqueForm in the shape of a five-pointed star
	filled with black."

	"OpaqueForm makeStar."
	"OpaqueForm makeStar bitEdit"

	| figure shape pen formRect |
	formRect_ 0@0 extent: 50@50.
	pen _ Pen new.
	pen defaultNib: 2.
	Display fill: formRect mask: Form white.
	pen north; place: formRect center; spiral: 45 angle: 144.
	shape _ Form fromDisplay: formRect.
	pen white; north; place: formRect center; spiral: 30 angle: 144.
	figure _ Form fromDisplay: formRect.
	^ OpaqueForm figure: figure shape: shape!

starCursor
	"Make the cursor track a five-pointed star."

	"OpaqueForm starCursor"

	Cursor blank showWhile:
		[self makeStar follow: [Sensor cursorPoint] while: [Sensor noButtonPressed]]! !