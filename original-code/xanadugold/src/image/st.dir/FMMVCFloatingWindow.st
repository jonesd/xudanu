'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:51 pm'!

FMMVCWindow subclass: #FMMVCFloatingWindow
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!



!FMMVCFloatingWindow methodsFor: 'displaying'!

displayRegion
	"Answer the rectangular area of the display in which the receiver 
	can be displayed."

	^self displayBox!

displayView
	"Paint an image of the receiver on the display screen."

	"no display - no label"! !

!FMMVCFloatingWindow methodsFor: 'clipping box access'!

clippingBox
	"Answer the rectangular area in which the receiver can show its label."

	^super insetDisplayBox! !

!FMMVCFloatingWindow methodsFor: 'testing'!

containsPoint: aPoint 
	^(super containsPoint: aPoint)! !

!FMMVCFloatingWindow methodsFor: 'creation'!

create: windowModel {WindowModel} with: minSize {Point}
	super create: windowModel with: '' with: minSize! !