'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:34 pm'!

CompareFragment subclass: #InsertFragment
	instanceVariableNames: 'destLocs {IntegerRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(InsertFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertFragment methodsFor: 'testing'!

{BooleanVar} isShared
	"Does this fragment occur in both the source and the destination?"
	^false! !

!InsertFragment methodsFor: 'accessing'!

{IntegerRegion} finalLocations
	^destLocs!

{IntegerRegion} startLocations
	^IntegerRegion make! !

!InsertFragment methodsFor: 'creation'!

create: s {IntegerVar} with: dLocs {IntegerRegion}
	super create: s.
	destLocs _ dLocs.! !

!InsertFragment methodsFor: 'printing'!

{void} printOn: stream {ostream reference}

	stream << 'Insert[' << destLocs << ']'.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InsertFragment class
	instanceVariableNames: ''!

(InsertFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InsertFragment class methodsFor: 'pseudoConstructors'!

{InsertFragment} make: s {IntegerVar} with: dLoc {IntegerRegion}

	^InsertFragment create: s with: dLoc! !