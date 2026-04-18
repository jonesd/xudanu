'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:54 pm'!

Controller subclass: #BinaryChoiceController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Prompt/Confirm'!
BinaryChoiceController comment:
'Instances of class BinaryChoiceController assume that their model can carry out some action only once--that is, make a selection only once.  Control is given up if the model responds true to the message actionTaken.'!


!BinaryChoiceController methodsFor: 'control defaults'!

isControlActive
	model actionTaken ifTrue: [^false].
	[super isControlActive] whileFalse: [view flash].
	^true! !

!BinaryChoiceController methodsFor: 'basic control sequence'!

idle
	"do nothing"!

startUp

	Cursor normal showWhile: [super startUp]! !

!BinaryChoiceController methodsFor: 'cursor'!

centerCursorInView
	"Position sensor's mousePoint (which is assumed to be connected to the 
	cursor) to the center of its view's inset display box (see Sensor|mousePoint: and 
	View|insetDisplayBox)."

	| lowestSubView subViews |
	subViews_ view subViews.
	subViews isEmpty
		ifFalse:	[lowestSubView _ subViews at: 1.
				subViews do:
					[:subView |
						(subView insetDisplayBox top >
							lowestSubView insetDisplayBox top)
						ifTrue:	[lowestSubView _ subView]].
				^lowestSubView controller centerCursorInView].

	^super centerCursorInView! !