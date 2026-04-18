'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:32 pm'!

Heaper subclass: #EditSequence
	instanceVariableNames: '
		myOperations {IntegerTable of: EditOperation}
		myNextSequence {EditSequence}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
EditSequence comment:
'EditSequence holds a sequence of EditOperations to represent a mapping from one document to another in a comparison.  EditSequences are built by LCSFinder, which adds operations one at time as it searches for a longest common sequence between two documents.'!

(EditSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EditSequence methodsFor: 'scoring'!

{IntegerVar} countMoves
	| count {IntegerVar} |
	count _ IntegerVar0.
	myOperations stepper forEach: [:op {EditOperation} |
		(op isKindOf: MoveOperation) ifTrue: [count _ count + 1]].
	^count!

{IntegerVar} moveDistanceFor: moveIndex {IntegerVar}
	| count {IntegerVar} |
	count _ IntegerVar0.
	((myOperations fetch: moveIndex) isKindOf: MoveInOperation) ifTrue:
		[ | op {MoveInOperation} |
		op _ (myOperations fetch: moveIndex) cast: MoveInOperation.
		moveIndex to: op fromPosition do: [:index {IntegerVar} |
			((myOperations intFetch: index) == NULL) ifFalse:
				[count _ count + ((myOperations intFetch: index) cast: EditOperation) sizeInMerge]]].
	^count!

{IntegerVar} moveSizeXDist
	| count {IntegerVar} |
	count _ IntegerVar0.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		((myOperations fetch: opIndex) isKindOf: MoveInOperation) ifTrue:
			[count _ count + ((self moveDistanceFor: opIndex asIntegerVar) 
							* ((myOperations fetch: opIndex) cast: MoveInOperation) count)]].
	^count!

{IntegerVar} totalMoveDistances
	| count {IntegerVar} |
	count _ IntegerVar0.
	myOperations domain stepper forEach: [:opIndex {IntegerPos} |
		((myOperations fetch: opIndex) isKindOf: MoveInOperation) ifTrue:
			[count _ count + (self moveDistanceFor: opIndex asIntegerVar)]].
	^count! !

!EditSequence methodsFor: 'moves'!

{EditSequence} editSequenceForMove: source {IntegerTable of: EditOperation} with: dest {IntegerTable of: EditOperation}
	| s {IntegerTable of: CompareOperation} f {IntegerTable of: CompareOperation} |
	s _ IntegerTable make.
	(self operationsSubTable: (source domain cast: IntegerRegion)) stepper forEach: [:each {PrimOperation} |
		s at: each startPosition introduce: each fragment].
	f _ IntegerTable make.
	(self operationsSubTable: (dest domain cast: IntegerRegion)) stepper forEach: [:each {PrimOperation} |
		f at: each finalPosition introduce: each fragment].
	[LCSFinder] USES.
	^(TextComparator make.IntegerTable: f with.IntegerTable: s) findLCS!

{void} makeMove: from {IntegerVar} with: to {IntegerVar}

	| fromOp {EditOperation} toOp {EditOperation} |
	(((self fetchOperation: from) == NULL) or: [(self fetchOperation: to) == NULL])
		ifTrue: [^VOID].
	fromOp _ self fetchOperation: from.
	toOp _ self fetchOperation: to.
	(((fromOp isKindOf: DeleteOperation) and: [toOp isKindOf: InsertOperation])
	   and: [(fromOp cast: DeleteOperation) sameFragmentAs: (toOp cast: InsertOperation)])
		ifFalse: [^VOID].
	myOperations at: to store: (MoveInOperation make: (toOp cast: InsertOperation) with: from).
	myOperations at: from store: (MoveOutOperation make: (fromOp cast: DeleteOperation) with: to).!

{void} rearrange: range {IntegerRegion} with: move {MoveOperation}
	range stepper forEach: [:r {IntegerPos} | myOperations wipe: r].
	myOperations at: range start introduce: move.
	^VOID! !

!EditSequence methodsFor: 'adding'!

{EditSequence} addDeleteOperation: del {DeleteOperation}
	myOperations atInt: myOperations count store: del.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addDeleteOperation: del].
	^self!

{EditSequence} addDeletion: aFragment {CompareFragment}
	| del {DeleteOperation} startPosition {IntegerVar} finalPosition {IntegerVar} |
	(myOperations count == IntegerVar0)
		ifTrue: [startPosition _ finalPosition _ UInt32Zero]
		ifFalse: [startPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextStartPosition.
				finalPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextFinalPosition].
	del _ DeleteOperation make: startPosition with: finalPosition with: aFragment.
	myOperations atInt: myOperations count store: del.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addDeleteOperation: del].
	^self!

{EditSequence} addInsertion: aFragment {CompareFragment}
	| insert {InsertOperation} startPosition {IntegerVar} finalPosition {IntegerVar} |
	(myOperations count == IntegerVar0)
		ifTrue: [startPosition _ finalPosition _ UInt32Zero]
		ifFalse: [startPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextStartPosition.
				finalPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextFinalPosition].
	insert _ InsertOperation make: startPosition with: finalPosition with: aFragment.
	myOperations atInt: myOperations count store: insert.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addInsertOperation: insert].
	^self!

{EditSequence} addInsertOperation: insert {InsertOperation}
	myOperations atInt: myOperations count store: insert.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addInsertOperation: insert].
	^self!

{void} addSequence: aSequence {EditSequence}
	(myNextSequence == NULL) 
		ifTrue: [myNextSequence _ aSequence]
		ifFalse: [(self isEqual: myNextSequence)
					ifFalse: [myNextSequence addSequence: aSequence]]!

{EditSequence} addShare: aFragment {CompareFragment}
	| share {ShareOperation} startPosition {IntegerVar} finalPosition {IntegerVar} |
	(myOperations count == IntegerVar0)
		ifTrue: [startPosition _ finalPosition _ UInt32Zero]
		ifFalse: [startPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextStartPosition.
				finalPosition _ ((myOperations intFetch: myOperations count - 1) cast: PrimOperation) nextFinalPosition].
	share _ ShareOperation make: startPosition with: finalPosition with: aFragment.
	myOperations atInt: myOperations count store: share.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addShareOperation: share].
	^self!

{EditSequence} addShareOperation: share {ShareOperation}
	myOperations atInt: myOperations count store: share.
	(myNextSequence == NULL)
		ifFalse: [myNextSequence addShareOperation: share].
	^self! !

!EditSequence methodsFor: 'smalltalk: displaying'!

{Text} asText
	^Text streamContents: [:aStream |
		myOperations stepper forEach: [:op {PrimOperation} |
			op printTextOn: aStream]]! !

!EditSequence methodsFor: 'accessing'!

{MuSet of: EditSequence} allSequences
	(myNextSequence == NULL) 
		ifTrue:
			[^MuSet make.Heaper: self]
		ifFalse:
			[| seq {MuSet of: EditSequence} |
			seq _ myNextSequence allSequences.
			seq store: self.
			^seq]!

{IntegerTable of: EditOperation} contiguousDeletes: index {IntegerVar}
	"make a table of DeleteOperations which are contiguous with index."
	| contig {IntegerTable of: EditOperation} lowerBound {IntegerVar} upperBound {IntegerVar} nextOp {EditOperation} |
	contig _ IntegerTable make.
	contig at: index store: (self fetchOperation: index).

	lowerBound _ index.
	[((nextOp _ self fetchOperation: lowerBound - 1) ~= NULL)
			and: [(nextOp isKindOf: DeleteOperation)
			 and: [(nextOp cast: DeleteOperation) isPureDelete not]]]
	whileTrue:
		[contig at: lowerBound - 1 store: nextOp.
		lowerBound _ lowerBound - 1].

	upperBound _ index.
	[((nextOp _ self fetchOperation: upperBound + 1) ~= NULL)
			and: [(nextOp isKindOf: DeleteOperation)
			 and: [(nextOp cast: DeleteOperation) isPureDelete not]]]
	whileTrue:
		[contig at: upperBound + 1 store: nextOp.
		upperBound _ upperBound + 1].
	^contig!

{IntegerTable of: EditOperation} contiguousInserts: index {IntegerVar} with: deleteOps {IntegerTable of: EditOperation}
	| contig {IntegerTable of: EditOperation} lowerBound {IntegerVar} upperBound {IntegerVar} deleteStarts {IntegerTable} nextOp {EditOperation} op {EditOperation} deleteLoc {IntegerVar} | 
	contig _ IntegerTable make.
	contig at: index store: (self fetchOperation: index).
	deleteStarts _ IntegerTable make.
	deleteOps domain stepper forEach: [:del {IntegerPos} |
		op _ (deleteOps fetch: del) cast: EditOperation.
		deleteStarts at: op startLocations start store: op].

	lowerBound _ index.
	[((nextOp _ self fetchOperation: lowerBound - 1) ~= NULL)
		and: [(nextOp isInsertMove)
		 and: [(deleteStarts fetch: (deleteLoc _ nextOp startLocations start)) ~= NULL]]]
	whileTrue:
		[contig at: lowerBound - 1 store: nextOp.
		deleteStarts intRemove: deleteLoc.
		lowerBound _ lowerBound - 1].

	upperBound _ index.
	[((nextOp _ self fetchOperation: upperBound + 1) ~= NULL)
		and: [(nextOp isInsertMove)
		 and: [(deleteStarts fetch: (deleteLoc _ nextOp startLocations start)) ~= NULL]]]
	whileTrue:
		[contig at: upperBound + 1 store: nextOp.
		deleteStarts intRemove: deleteLoc.
		upperBound _ upperBound + 1].
	^contig!

{IntegerVar} count
	^myOperations count!

{EditOperation} fetchOperation: index {IntegerVar}
	^(myOperations intFetch: index) cast: EditOperation!

{UInt32} hashForEqual
	^myOperations hashForEqual!

{BooleanVar}isEqual: other{Heaper}
	"Return true if the two objects are equal."
	^ self hashForEqual = other hashForEqual!

{IntegerTable of: EditOperation} operations
	^myOperations!

{IntegerTable of: EditOperations} operationsSubTable: reg {XnRegion}
	^(myOperations subTable: reg) cast: IntegerTable! !

!EditSequence methodsFor: 'creation'!

create
	super create.
	myNextSequence _ NULL.
	myOperations _ IntegerTable make.!

create: ops {IntegerTable of: CompareFragment}
	super create.
	myNextSequence _ NULL.
	myOperations _ ops.!

create: ops {IntegerTable of: CompareFragment} with: seq {EditSequence}
	super create.
	myNextSequence _ seq.
	myOperations _ ops.! !

!EditSequence methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	myOperations isEmpty
		ifTrue: [oo << 'EditSequence(empty)']
		ifFalse: [myOperations printOnWithSimpleSyntax: oo with: '(' with: '
' with: ')'].
	(myNextSequence == NULL)  ifFalse: 
			[oo << '
EditSequences . . .'].! !

!EditSequence methodsFor: 'copying'!

{EditSequence} copy
	(myNextSequence == NULL )
		ifFalse: [^EditSequence make: (myOperations copy cast: IntegerTable)
							with: myNextSequence copy]
		ifTrue: [^EditSequence make: (myOperations copy cast: IntegerTable)]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EditSequence class
	instanceVariableNames: ''!

(EditSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EditSequence class methodsFor: 'pseudoConstructors'!

{EditSequence} make
	^EditSequence create!

{EditSequence} make: ops {IntegerTable of: CompareFragment}
	^EditSequence create: ops!

{EditSequence} make: ops {IntegerTable of: CompareFragment} with: seq {EditSequence}
	^EditSequence create: ops with: seq!

{EditSequence}  makeShare: aFragment {CompareFragment}
	| table {IntegerTable} |
	table _ IntegerTable make: 1.
	table at: 1 introduce: (ShareOperation make: IntegerVar0 with: IntegerVar0 with: aFragment).
	^EditSequence create: table! !