'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:18 pm'!

Converter subclass: #ReferenceFilter2Tapestry
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-filters'!

(ReferenceFilter2Tapestry getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ReferenceFilter2Tapestry methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	| filter {ReferenceFilter} |
	filter _ value basicCast: ReferenceFilter.
	(filter workType isEqual: (Sequence string: 'LinkFilter')) ifTrue:
		[^TapestryLinkFilter create: filter]
	ifFalse: [(filter workType isEqual: (Sequence string: 'VariantFilter')) ifTrue:
		[^TapestryVariantFilter create: filter]
	ifFalse:
		[Heaper BLAST: #CantConvert]]!

create
	"super create: ReferenceFilter with: TapestryFilter"! !