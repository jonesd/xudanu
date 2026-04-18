'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:51 pm'!

Converter subclass: #XnRegion2ImmuSet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-set'!

(XnRegion2ImmuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnRegion2ImmuSet methodsFor: 'creation'!

create
	super create: XnRegion with: ImmuSet! !

!XnRegion2ImmuSet methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	^ (value convert: MuSet) asImmuSet! !