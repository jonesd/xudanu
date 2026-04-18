'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:36 pm'!

EditOperation subclass: #MoveOperation
	instanceVariableNames: 'myOperations {IntegerTable of: EditOperations}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(MoveOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!MoveOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: ops {IntegerTable of: EditOperations}
	super create: s with: f.
	myOperations _ ops.! !

!MoveOperation methodsFor: 'accessing'!

{IntegerVar} count
	| size {IntegerVar} |
	size _ UInt32Zero.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		size _ size + ((myOperations fetch: opIndex) cast: EditOperation) count].
	^size!

{IntegerRegion} finalLocations
	| locs {IntegerRegion} |
	locs _ IntegerRegion make.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		locs _ (locs unionWith: ((myOperations fetch: opIndex) cast: EditOperation) finalLocations) cast: IntegerRegion].
	^locs!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	self subclassResponsibility!

{IntegerRegion} startLocations
	| locs {IntegerRegion} |
	locs _ IntegerRegion make.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		locs _ (locs unionWith: ((myOperations fetch: opIndex) cast: EditOperation) startLocations) cast: IntegerRegion].
	^locs! !

!MoveOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	self subclassResponsibility! !

!MoveOperation methodsFor: 'protected: protected accessing'!

{IntegerTable of: EditOperations} operations
	^myOperations! !