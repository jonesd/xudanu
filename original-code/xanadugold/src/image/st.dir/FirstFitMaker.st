'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:33 pm'!

MoveMaker subclass: #FirstFitMaker
	instanceVariableNames: '
		oldSequences {MuSet of: EditSequences}
		newSequences {MuSet of: EditSequences}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(FirstFitMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FirstFitMaker methodsFor: 'accessing'!

{void} makeSequences
	oldSequences count == 1 ifTrue: 
		[newSequences _ oldSequences cast: MuSet].
	oldSequences stepper forEach: [:eachSeq {EditSequence} |
		self arrange: eachSeq].
	self pickBest: oldSequences.!

{MuSet of: EditSequences} sequences
	newSequences == NULL
		ifTrue: [self makeSequences].
	^newSequences! !

!FirstFitMaker methodsFor: 'scoring'!

{MuSet of: EditSequences} lowestMoveCount: set {MuSet of: EditSequences}
	| scoreTable {IntegerTable of: (MuSet of: EditSequences)} score {IntegerVar} |
	scoreTable _ IntegerTable make.
	set stepper forEach: [:eachSeq {EditSequence} |
		score _ eachSeq countMoves.
		(scoreTable fetch: score) == NULL
			ifTrue: [scoreTable at: score introduce: (MuSet make.Heaper: eachSeq)]
			ifFalse: [((scoreTable fetch: score) cast: MuSet) store: eachSeq]].
	^(scoreTable fetch: (scoreTable domain cast: IntegerRegion) start) cast: MuSet!

{void} pickBest: set {MuSet of: EditSequences}
	"newSequences _ self lowestMoveCount: set."
	newSequences _ self shortestMoves: set.
	"newSequences _ self smallShortMoves: newSequences."!

{MuSet of: EditSequences} shortestMoves: set {MuSet of: EditSequences}
	| scoreTable {IntegerTable of: (MuSet of: EditSequences)} score {IntegerVar} |
	scoreTable _ IntegerTable make.
	set stepper forEach: [:eachSeq {EditSequence} |
		score _ eachSeq totalMoveDistances.
		(scoreTable intFetch: score) == NULL
			ifTrue: [scoreTable atInt: score introduce: (MuSet make.Heaper: eachSeq)]
			ifFalse: [((scoreTable intFetch: score) cast: MuSet) store: eachSeq]].
	^(scoreTable intFetch: (scoreTable domain cast: IntegerRegion) start) cast: MuSet!

{MuSet of: EditSequences} smallShortMoves: set {MuSet of: EditSequences}
	| scoreTable {IntegerTable of: (MuSet of: EditSequences)} score {IntegerVar} |
	scoreTable _ IntegerTable make.
	set stepper forEach: [:eachSeq {EditSequence} |
		score _ eachSeq moveSizeXDist.
		(scoreTable fetch: score) == NULL
			ifTrue: [scoreTable at: score introduce: (MuSet make.Heaper: eachSeq)]
			ifFalse: [((scoreTable fetch: score) cast: MuSet) store: eachSeq]].
	^(scoreTable fetch: (scoreTable domain cast: IntegerRegion) start) cast: MuSet! !

!FirstFitMaker methodsFor: 'arranging Sequences'!

{EditSequence} arrange: aSeq {EditSequence}
	"rearrange the operations in aSeq (by turning some inserts and deletes into moves)"
	| inserts {IntegerTable of: IntegerPos} deletes {IntegerTable of: IntegerPos} editStart {IntegerVar} ops {MuTable of: editOperations} |
	inserts _ IntegerTable make.
	deletes _ IntegerTable make.
	ops _ aSeq operations.
	IntegerVar0 to: aSeq count do: [:index {IntegerVar} | | edit {EditOperation} |
		edit _ (ops intFetch: index) cast: EditOperation.
		(edit == NULL) ifFalse: 
		  [((edit isKindOf: DeleteOperation)
		    and: [edit isPureDelete not]) ifTrue:
			[editStart _ edit startLocations start.
		  	(inserts intFetch: editStart) == NULL
				ifTrue: [deletes at: editStart store: index integer]
				ifFalse: [self arrangeMove: aSeq with: index with: ((inserts intFetch: editStart) cast: IntegerPos) asIntegerVar]].
		  ((edit isKindOf: InsertOperation)
		    and: [edit isPureInsert not]) ifTrue:
			[editStart _ edit startLocations start.
		  	(deletes intFetch: editStart) == NULL
				ifTrue: [inserts at: editStart store: index integer]
				ifFalse: [self arrangeMove: aSeq with: ((deletes intFetch: editStart) cast: IntegerPos) asIntegerVar with: index]].
		 (edit isKindOf: MoveOperation) ifTrue:
			["deal with moves later"]]].
	^aSeq!

{void} arrangeComplexMove: aSeq {EditSequence} with: deletes {IntegerTable of: EditOperation} with: inserts {IntegerTable of: EditOperation}

	| smallSeq {EditSequence} moveIn {MoveInOperation} moveOut {MoveOutOperation} |
	smallSeq _ aSeq editSequenceForMove: deletes with: inserts.
	self arrange: smallSeq.
	moveIn _ MoveInOperation make.IntegerTable: smallSeq operations with: (deletes domain cast: IntegerRegion) start.
	moveOut _ MoveOutOperation make.IntegerTable: smallSeq operations with: (inserts domain cast: IntegerRegion) start.
	aSeq rearrange: (deletes domain cast: IntegerRegion) with: moveOut.
	aSeq rearrange: (inserts domain cast: IntegerRegion) with: moveIn.
	^VOID!

{void} arrangeMove: aSeq {EditSequence} with: from {IntegerVar} with: to {IntegerVar}
	"rearrange the operations in aSeq by turning matching inserts (around 'to') and deletes (around 'from') into moves"
	| fromPiece {EditOperation} toPiece {EditOperation} inserts {IntegerTable of: EditOperation} deletes {IntegerTable of: EditOperation} |
	fromPiece _ aSeq fetchOperation: from.
	toPiece _ aSeq fetchOperation: to.
	((fromPiece isKindOf: DeleteOperation)
	   and: [(toPiece isKindOf: InsertOperation)
		and: [(fromPiece quickCast: DeleteOperation) sameFragmentAs: (toPiece quickCast: InsertOperation)]])
		ifFalse: [^VOID].
	deletes _ aSeq contiguousDeletes: from.
	inserts _ aSeq contiguousInserts: to with: deletes.
	((deletes count == 1) or: [inserts count == 1]) ifTrue:
		[aSeq makeMove: from with: to.
		^VOID].
	self arrangeComplexMove: aSeq with: deletes with: inserts.
	^VOID! !

!FirstFitMaker methodsFor: 'creation'!

create: seqs {MuSet of: EditSequence}
	super create.
	oldSequences _ seqs.
	newSequences _ NULL.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FirstFitMaker class
	instanceVariableNames: ''!

(FirstFitMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FirstFitMaker class methodsFor: 'pseudoConstructors'!

{FirstFitMaker} make: seqs {MuSet of: EditSequence}

	^FirstFitMaker create: seqs! !