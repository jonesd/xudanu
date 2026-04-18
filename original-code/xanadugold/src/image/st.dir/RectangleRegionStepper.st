'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:27 pm'!

Stepper subclass: #RectangleRegionStepper
	instanceVariableNames: 'myRect {PointRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!

(RectangleRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RectangleRegionStepper methodsFor: 'create'!

{Stepper} copy
	myRect == NULL
		ifTrue: [^self]
		ifFalse: [^RectangleRegionStepper create: myRect]!

create: onRegion {PointRegion}
	super create.
	myRect _ onRegion cast: RectanglePointRegion! !

!RectangleRegionStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	^ myRect!

{BooleanVar} hasValue
	^ myRect ~~ NULL!

{void} step
	myRect _ NULL! !