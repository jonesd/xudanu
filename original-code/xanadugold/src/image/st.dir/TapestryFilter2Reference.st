'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:18 pm'!

Converter subclass: #TapestryFilter2Reference
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-filters'!

(TapestryFilter2Reference getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TapestryFilter2Reference methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	^(value basicCast: TapestryFilter) referenceFilter! !

!TapestryFilter2Reference methodsFor: 'create'!

create
	super create: TapestryFilter with: ReferenceFilter! !