'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:36 pm'!

MoveOperation subclass: #MoveInOperation
	instanceVariableNames: 'myMoveFromPosition {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(MoveInOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MoveInOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'MoveIn[' << myMoveFromPosition << ']'! !

!MoveInOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: ops {IntegerTable of: EditOperations} with: from {IntegerVar}
	super create: s with: f with: ops.
	myMoveFromPosition _ from! !

!MoveInOperation methodsFor: 'scoring'!

{IntegerVar} moveDistance
	| dist {IntegerVar} |
	dist _ self finalPosition - self startPosition.
	(dist < IntegerVar0) ifTrue: [dist _ dist negated].
	^dist - self count.! !

!MoveInOperation methodsFor: 'accessing'!

{IntegerVar} fromPosition
	^myMoveFromPosition!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	^1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MoveInOperation class
	instanceVariableNames: ''!

(MoveInOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MoveInOperation class methodsFor: 'pseudoConstructors'!

{MoveInOperation} make.IntegerTable: ops {IntegerTable of: EditOperation} with: from {IntegerVar}
	| start {IntegerRegion} final {IntegerRegion} stepper {Stepper} |
	stepper _ ops domain stepper.
	start _ ((ops fetch: (stepper fetch cast: IntegerPos)) cast: EditOperation) startLocations.
	final _ ((ops fetch: (stepper fetch cast: IntegerPos)) cast: EditOperation) finalLocations.
	stepper forEach: [:index {IntegerPos} |
		start _ (start unionWith: ((ops fetch: index) cast: EditOperation) startLocations) cast: IntegerRegion.
		final _ (final unionWith: ((ops fetch: index) cast: EditOperation) finalLocations) cast: IntegerRegion].
	^MoveInOperation create: start start with: final start with: ops with: from!

{MoveInOperation} make: insert {InsertOperation} with: from {IntegerVar}
	| t {IntegerTable of: EditOperation} |
	t _ IntegerTable make.
	t at: UInt32Zero introduce: insert.
	^MoveInOperation create: insert startPosition with: insert finalPosition with: t with: from! !