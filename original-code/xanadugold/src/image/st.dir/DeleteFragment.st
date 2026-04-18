'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:31 pm'!

CompareFragment subclass: #DeleteFragment
	instanceVariableNames: 'srcLocs {IntegerRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(DeleteFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeleteFragment methodsFor: 'accessing'!

{IntegerRegion} finalLocations
	^IntegerRegion make!

{IntegerRegion} startLocations
	^srcLocs! !

!DeleteFragment methodsFor: 'creation'!

create: s {IntegerVar} with: sLocs {IntegerRegion}
	super create: s.
	srcLocs _ sLocs.! !

!DeleteFragment methodsFor: 'printing'!

{void} printOn: stream {ostream reference}

	stream << 'del[' << srcLocs << ']'.! !

!DeleteFragment methodsFor: 'testing'!

{BooleanVar} isShared
	"Does this fragment occur in both the source and the destination?"
	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DeleteFragment class
	instanceVariableNames: ''!

(DeleteFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeleteFragment class methodsFor: 'pseudoConstructors'!

{DeleteFragment} make: s {IntegerVar} with: srcLoc {IntegerRegion}

	^DeleteFragment create: s with: srcLoc! !