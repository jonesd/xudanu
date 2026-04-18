'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:23 pm'!

Converter subclass: #Point2Dsp
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Points'!

(Point2Dsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!Point2Dsp methodsFor: 'creation'!

create
	super create: PointPos with: Dsp! !

!Point2Dsp methodsFor: 'accessing'!

{Heaper} convert: value {Heaper} 
	| pt {PointPos} |
	pt _ value basicCast: PointPos.
	^PointTranslateDsp make: pt x with: pt y! !