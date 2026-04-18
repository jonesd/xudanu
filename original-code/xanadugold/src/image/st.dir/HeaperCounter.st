'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:24 pm'!

TableCounter subclass: #HeaperCounter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-monitor'!

(HeaperCounter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!HeaperCounter methodsFor: 'accessing'!

{void} count: value {Heaper}
	self privateCount: (HeaperAsPosition make: value)!

create
	super create: HeaperSpace make! !