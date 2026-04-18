'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:51 pm'!

Converter subclass: #XnRegion2MuSet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-set'!

(XnRegion2MuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnRegion2MuSet methodsFor: 'creation'!

create
	super create: XnRegion with: MuSet! !

!XnRegion2MuSet methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	| region {XnRegion} result {MuSet} |
	region _ value cast: XnRegion.
	result _ MuSet make.IntegerVar: region count.
	region stepper forEach: [:position {Position} | result store: position].
	^result! !