'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:16 pm'!

FormView subclass: #FormHolderView
	instanceVariableNames: 'displayedForm '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Form editing'!
FormHolderView comment:
'Class FormHolderView represents a view of a Form.  Editing takes place by modifying a working version of the Form.  The message accept is used to copy the working version into the Form;  the message cancel copies the Form into the working version.

Instance Variable:
	displayedForm <Form> a working version of the Form for being able to cancel editing'!


!FormHolderView methodsFor: 'initialize-release'!

release
	"Release references to all dependencies."

	super release.
	displayedForm release.
	displayedForm _ nil! !

!FormHolderView methodsFor: 'model access'!

changeValueAt: location put: anInteger
	"The receiver's model is a Form which has an array of bits.  Change
	the bit at index location to be anInteger (either 1 or 0).  Inform all
	objects that depend on the model that it has changed."

	displayedForm valueAt: location put: anInteger.
	displayedForm changed: self!

model: aForm
	"Set the receiver's model to a copy of aForm.  The model of the receiver's controller is also
	set to aModel. "

	super model: aForm.
	displayedForm _ aForm deepCopy!

workingForm
	"Answer the Form that is currently being displayed--the working version
	in which edits are carried out."

	^displayedForm! !

!FormHolderView methodsFor: 'displaying'!

displayView 
	"This method displays the Form associated with this View according to the rule and mask specified by this class."

	| oldOffset |
	oldOffset _ displayedForm offset.
	displayedForm offset: 0@0.
	displayedForm
		displayOn: Display
		transformation: self displayTransformation
		clippingBox: self insetDisplayBox
		rule: self rule
		mask: self mask.
	displayedForm offset: oldOffset!

updateDisplay
	"The working version is redefined by copying the bits displayed in the receiver's display area."

	displayedForm fromDisplay: self insetDisplayBox.
	displayedForm changed: self.! !

!FormHolderView methodsFor: 'menu messages'!

accept
	"Store the current screen image as the saved model."

	model
		copyBits: displayedForm boundingBox
		from: displayedForm
		at: 0 @ 0
		clippingBox: model boundingBox
		rule: Form over
		mask: Form black.
	model changed: self!

cancel
	"Replace the screen image with the saved form."

	displayedForm become: model deepCopy.
	displayedForm changed: self.
	self display! !