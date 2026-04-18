'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:25 pm'!

TableCounter subclass: #PositionCounter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-monitor'!

(PositionCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PositionCounter methodsFor: 'accessing'!

{void} count: key {Position}
	self privateCount: key!

create: cs {CoordinateSpace}
	super create: cs! !