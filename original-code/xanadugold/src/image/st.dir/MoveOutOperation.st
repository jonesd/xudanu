'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:37 pm'!

MoveOperation subclass: #MoveOutOperation
	instanceVariableNames: 'myMoveToPosition {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(MoveOutOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MoveOutOperation methodsFor: 'creation'!

create: s {IntegerVar} with: f {IntegerVar} with: ops {IntegerTable of: EditOperations} with: to {IntegerVar}
	super create: s with: f with: ops.
	myMoveToPosition _ to! !

!MoveOutOperation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'MoveOut[(' << self startPosition << ',' << self finalPosition << ')->' << myMoveToPosition << ','.
	self operations isEmpty ifFalse:
		[self operations printOnWithSimpleSyntax: oo with: '
	(' with: '
	' with: ')'].

	oo << ']'! !

!MoveOutOperation methodsFor: 'accessing'!

{IntegerVar} sizeInMerge
	"My size in the compare merge representation"
	^self count! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MoveOutOperation class
	instanceVariableNames: ''!

(MoveOutOperation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MoveOutOperation class methodsFor: 'pseudoConstructors'!

{MoveOutOperation} make.IntegerTable: ops {IntegerTable of: EditOperations} with: to {IntegerVar}
	| start {IntegerRegion} final {IntegerRegion} stepper {Stepper} |
	stepper _ ops domain stepper.
	start _ ((ops fetch: (stepper fetch cast: IntegerPos) asIntegerVar) cast: EditOperation) startLocations.
	final _ ((ops fetch: (stepper fetch cast: IntegerPos) asIntegerVar) cast: EditOperation) finalLocations.
	stepper forEach: [:index {IntegerPos} |
		start _ (start unionWith: ((ops fetch: index) cast: EditOperation) startLocations) cast: IntegerRegion.
		final _ (final unionWith: ((ops fetch: index) cast: EditOperation) finalLocations) cast: IntegerRegion].
	^MoveOutOperation create: start start with: final start with: ops with: to!

{MoveOutOperation} make: del {DeleteOperation} with: to {IntegerVar}
	| t {IntegerTable of: EditOperation} |
	t _ IntegerTable make.
	t at: UInt32Zero introduce: del.
	^MoveOutOperation create: del startPosition with: del finalPosition with: t with: to! !