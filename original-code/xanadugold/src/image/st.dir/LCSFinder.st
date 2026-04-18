'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:35 pm'!

Heaper subclass: #LCSFinder
	instanceVariableNames: '
		myStartOrder {IntegerTable of: CompareFragment}
		myEndOrder {IntegerTable of: CompareFragment}
		myNextDiagonals {IntegerTable of: (MuSet of: (Pair of: IntegerPos))}
		myDiagonals {LCSDiagonalMatrix}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
LCSFinder comment:
'LCSFinder finds Longest Common Sequences between two documents.  Its algorithm is based on the one in "A File Comparison Program" by W. Miller and E. W. Myers which appeared in Software Practice & Experience V15 #11 in November 1985.  Please see the paper for an explanation of the basic algorithm.  

There are some modifications used because I have been provided with a pre-computed comparison of the documents.  This allows me to check whole ranges of text with a single operation, and so I increase the costs by the size of the regions rather than 1 as they did.  (They compared a character or line at a time, and so their costs were constant.)

Since my regions have different sizes, I can''t expand the frontier the same way they do either.  I keep track of a current lowerBound, and at any point all entries less than the lowerBound have already been propogated, and so only higher values can appear.  

Because of the way I''m expanding the frontiers, I don''t know that I''ll get each entry correct the first time I store something in it.  I therefore check when adding an entry, and if the new value is lower, I continue propogating, and otherwise just discard the value.

I use a DiagonalMatrix to store the intermediate values as Miller & Myers did.  This is not really necessary; I can''t expand only at the frontier so I have to store a cost and editSequence with each entry.  I''ve kept the DiagonalMatrix around because it understands how to store and provide access to the cost and editSequence at each matrix element.'!

(LCSFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSFinder methodsFor: 'creation'!

create: start {IntegerTable of: CompareFragment} with: finish {IntegerTable of: CompareFragment}
	super create.
	myStartOrder _ start.
	myEndOrder _ finish.
	myNextDiagonals _ IntegerTable make.
	self initializeDiagonals!

{void} initializeDiagonals
	myDiagonals _ LCSDiagonalMatrix make: myStartOrder count with: myEndOrder count.
	(myDiagonals fetch: IntegerVar0)
		addEntryAt: IntegerVar0 with: IntegerVar0 with: EditSequence make.
	self propogateDiagonally: IntegerVar0 with: IntegerVar0.! !

!LCSFinder methodsFor: 'propogating values'!

{void} addToQueue: offset {IntegerVar} with: index {IntegerVar}
	| curEntry {IntegerVar} pair {Pair of: IntegerPos} |
	curEntry _ (myDiagonals fetch: offset) entryAt: index.
	pair _ Pair make: (IntegerPos make: offset) with: (IntegerPos make: index).
	(myNextDiagonals intFetch: curEntry) == NULL
		ifTrue: 
			[ | newSet {MuSet of: (Pair of: IntegerPos)} |
			newSet _ MuSet make.Heaper: pair.
			myNextDiagonals atInt: curEntry introduce: newSet]
		ifFalse:
			[((myNextDiagonals intFetch: curEntry) cast: MuSet) store: pair]!

{void} propogate: offset {IntegerVar} with: index {IntegerVar}
	self propogateRight: offset with: index.
	self propogateDown: offset with: index.!

{void} propogateDiagonally: offset { IntegerVar} with: index {IntegerVar}
	| diagonal {LCSDiagonal} row {IntegerVar} column {IntegerVar} valueIsNew {BooleanVar} bumpCount {IntegerVar}|
	diagonal _ myDiagonals fetch: offset.
	row _ diagonal rowFor: index.
	column _ diagonal columnFor: index.
	valueIsNew _ true.
	bumpCount _ 1.
	[valueIsNew
		and: [((myStartOrder intFetch: column + bumpCount) == NULL) not
			and: [((myStartOrder intFetch: column + bumpCount) cast: CompareFragment)
				== ((myEndOrder intFetch: row + bumpCount) cast: CompareFragment)]]]
	   whileTrue:
		[ | nextFragment {CompareFragment} |
		nextFragment _ (myStartOrder intFetch: column + bumpCount) cast: CompareFragment.
		valueIsNew _ diagonal 
			addShareEntryAt: index + bumpCount
			with: (diagonal entryAt: index)
			with: ((diagonal scriptFor: index + bumpCount - 1) cast: EditSequence)
			with: nextFragment.
		bumpCount _ bumpCount + 1].
	valueIsNew ifTrue:
		[self addToQueue: offset with: index + bumpCount - 1]
		"The final test could be moved inside the loop if you want to find more paths."!

{void} propogateDown: offset {IntegerVar} with: index {IntegerVar}

	| diagonal {LCSDiagonal} nextIndex {IntegerVar} nextFragment {CompareFragment} |
	diagonal _ myDiagonals fetch: offset.
	(offset > IntegerVar0) ifTrue: [nextIndex _ index + 1] ifFalse: [nextIndex _ index].
	((diagonal rowFor: index + 1) > myDiagonals rows) ifTrue: [^VOID].
	nextFragment _ (myEndOrder intFetch: (diagonal rowFor: index + 1)) cast: CompareFragment.
	((myDiagonals fetch: offset - 1)
		addInsertEntryAt: nextIndex
		with: (diagonal entryAt: index) + nextFragment count
		with: ((diagonal scriptFor: index) cast: EditSequence)
		with: nextFragment)
	    ifTrue:
		[self propogateDiagonally: offset - 1 with: nextIndex].!

{void} propogateRight: offset {IntegerVar} with: index {IntegerVar}

	| diagonal {LCSDiagonal} nextIndex {IntegerVar} nextFragment {CompareFragment} |
	diagonal _ myDiagonals fetch: offset.
	(offset < IntegerVar0)
		ifTrue: [nextIndex _ index + 1]
		ifFalse: [nextIndex _ index].
	((diagonal columnFor: index + 1) > myDiagonals columns)
		ifTrue: [^VOID].
	nextFragment _ (myStartOrder intFetch: (diagonal columnFor: index + 1)) cast: CompareFragment.
	((myDiagonals fetch: offset + 1)
		addDeleteEntryAt: nextIndex
		with: (diagonal entryAt: index) + nextFragment count
		with: ((diagonal scriptFor: index) cast: EditSequence)
		with: nextFragment)
	   ifTrue:
		[self propogateDiagonally: offset + 1 with: nextIndex].! !

!LCSFinder methodsFor: 'computing commonSequence'!

{void} advanceLowerBound
	| curValue {IntegerVar} |
	curValue _ (myNextDiagonals domain cast: IntegerRegion) start.
	((myNextDiagonals intFetch: curValue) cast: MuSet) stepper forEach: 
		[:each {Pair of: IntegerPos} | | l {IntegerVar} r {IntegerVar} |
		l _ (each left cast: IntegerPos) asIntegerVar.
		r _ (each right cast: IntegerPos) asIntegerVar.
		(((myDiagonals fetch: l) entryAt: r) == curValue)
			ifTrue: [self propogate: l with: r]].
	myNextDiagonals intWipe: curValue.!

{EditSequence} fillInTable
	| finalDiagonal {LCSDiagonal} finalIndex {IntegerVar} |
	finalDiagonal _ myDiagonals fetch: (myStartOrder count - myEndOrder count).
	finalIndex _ myStartOrder count min: myEndOrder count.
	[(myNextDiagonals domain isEmpty) not
		and: [((finalDiagonal entryAt: finalIndex) == NULL) 
		or: [(myNextDiagonals domain cast: IntegerRegion) start <= (finalDiagonal entryAt: finalIndex)]]]
	whileTrue:
		[self advanceLowerBound].
	^(finalDiagonal scriptFor: finalIndex) cast: EditSequence! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LCSFinder class
	instanceVariableNames: ''!

(LCSFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSFinder class methodsFor: 'pseudoConstructors'!

{LCSFinder} make: start {IntegerTable of: CompareFragment} with: finish {IntegerTable of: CompareFragment}

	^LCSFinder create: start with: finish! !