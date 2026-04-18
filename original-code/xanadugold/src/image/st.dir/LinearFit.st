'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:53 pm'!

Path subclass: #LinearFit
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Paths'!
LinearFit comment:
'Class LinearFit is a subclass of Path that represents a piece-wise linear approximation to a set of points in the plane.'!


!LinearFit methodsFor: 'displaying'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm
	"Display the receiver on the display medium aDisplayMedium positioned at aDisplayPoint within 
	the rectangle clipRectangle and with the rule, ruleInteger, and mask, aForm. "

	| line |
	line _ Line new.
	line form: self form.
	1 to: self size - 1 do: 
		[:i | 
		line beginPoint: (self at: i).
		line endPoint: (self at: i + 1).
		line displayOn: aDisplayMedium
			at: aDisplayPoint
			clippingBox: clipRectangle
			rule: ruleInteger
			mask: aForm]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinearFit class
	instanceVariableNames: ''!


!LinearFit class methodsFor: 'examples'!

linearFitSample
	"Select points on a Path using the red button.  Terminate by selecting any other
	button.  Creates a Path from the points and displays it as a piece-wise linear
	approximation." 

	"LinearFit linearFitSample."

	| aLinearFit aForm flag |
	aLinearFit _ LinearFit new.
	aForm _ Form new extent: 1 @ 40.
	aForm  black.
	aLinearFit form: aForm.
	flag _ true.
	[flag] whileTrue:
		[Sensor waitButton.
		 Sensor redButtonPressed
			ifTrue: [aLinearFit add: Sensor waitButton. Sensor waitNoButton.
					aForm displayOn: Display at: aLinearFit last]
			ifFalse: [flag_false]].
	aLinearFit displayOn: Display! !