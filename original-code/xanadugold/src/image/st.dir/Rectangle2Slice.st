'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:26 pm'!

Converter subclass: #Rectangle2Slice
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!

(Rectangle2Slice getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Rectangle2Slice methodsFor: 'creation'!

create
	super create: RectanglePointRegion with: SlicePointRegion! !

!Rectangle2Slice methodsFor: 'accessing'!

{Heaper} convert: value {Heaper} 
	| rect {RectanglePointRegion} |
	rect _ value basicCast: RectanglePointRegion.
	^SlicePointRegion
		make: rect left
		with: rect top
		with: rect right
		with: rect bottom! !