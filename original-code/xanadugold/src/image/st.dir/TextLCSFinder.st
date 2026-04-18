'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:41 pm'!

Heaper subclass: #TextLCSFinder
	instanceVariableNames: '
		myStartString {AttributedTextModel}
		myEndString {AttributedTextModel}
		myDiagonals {HashTable}
		lowerBound {IntegerVar}
		upperBound {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(TextLCSFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextLCSFinder methodsFor: 'creation'!

create: startString {AttributedTextModel} with: finishString {AttributedTextModel}
	super create.
	myStartString _ startString.
	myEndString _ finishString.
	self initializeDiagonals!

{void} initializeDiagonals
	| rowCount {IntegerVar} columnCount {IntegerVar} |
	columnCount _ myStartString count.
	rowCount _ myEndString count.
	myDiagonals _ TextDiagonalMatrix make: columnCount with: rowCount.
	rowCount negated to: columnCount do: [:offset {IntegerVar} |
		self propogateDiagonally: offset with: 1]! !

!TextLCSFinder methodsFor: 'propogating values'!

{void} propogateDiagonally: offset { IntegerVar} with: index {IntegerVar}
	| diagonal {Diagonal} row {IntegerVar} column {IntegerVar} bumpCount {IntegerVar} |
	diagonal _ myDiagonals fetch: offset.
	row _ diagonal rowFor: index.
	column _ diagonal columnFor: index.

	((myStartString count > column and: [myEndString count > row])
		and: [(myStartString at: column ) == (myEndString at: row )])
	   ifTrue:
		[bumpCount _ self sharedLength: column with: row.
		diagonal addEntryAt: index + bumpCount with: (diagonal entryAt: index).]!

{void} propogateDiagonally: offset {IntegerVar} with: diagonal {Diagonal} with: index {IntegerVar}
	| row {IntegerVar} column {IntegerVar} bumpCount {IntegerVar} |
	row _ diagonal rowFor: index.
	column _ diagonal columnFor: index.
	((myDiagonals columns > column and: [myDiagonals rows > row])
		and: [(myStartString at: column ) == (myEndString at: row )])
	   ifTrue:
		[bumpCount _ self sharedLength: column with: row.
		diagonal addEntryAt: index + bumpCount with: (diagonal entryAt: index)]
	ifFalse:
		[bumpCount _ 0].
	(column + bumpCount > myDiagonals columns) ifTrue:
		[upperBound _ offset - 2.
		^VOID].
	(row + bumpCount > myDiagonals rows) ifTrue:
		[lowerBound _ offset + 2.
		^VOID]!

{void} propogateDown: offset {IntegerVar} with: aboveEntry with: aboveIndex

	| nextIndex {IntegerVar} nextDiagonal {Diagonal} |
	nextIndex _ (offset > IntegerVar0) ifTrue: [aboveIndex + 1] ifFalse: [aboveIndex].
	nextDiagonal _ myDiagonals fetch: offset - 1.
	nextDiagonal addEntryAt: nextIndex with: aboveEntry + 1.
	self propogateDiagonally: offset - 1 with: nextDiagonal with: nextIndex.!

{void} propogateRight: offset {IntegerVar} with: leftEntry with: leftIndex
	| nextIndex {IntegerVar} nextDiagonal {Diagonal} |
	nextIndex _ (offset < IntegerVar0) ifTrue: [leftIndex + 1] ifFalse: [leftIndex].
	nextDiagonal _ myDiagonals fetch: offset + 1.
	nextDiagonal addEntryAt: nextIndex with: leftEntry + 1.
	self propogateDiagonally: offset + 1 with: nextDiagonal with: nextIndex.!

{void} propogateTo: offset { IntegerVar}
	| above {Diagonal} below {Diagonal} rowFromAbove {IntegerVar} rowFromBelow {IntegerVar} aboveIndex {IntegerVar} belowIndex {IntegerVar} |
	above _ myDiagonals fetch: offset + 1.
	below _ myDiagonals fetch: offset - 1.
	aboveIndex _ above lastIndex.
	belowIndex _ below lastIndex.
	rowFromAbove _ (above rowFor: aboveIndex) + 1.
	rowFromBelow _ below rowFor: belowIndex.
	rowFromBelow >= rowFromAbove
		ifTrue: [self propogateRight: offset - 1 with: below lastEntry with: belowIndex]
		ifFalse: [self propogateDown: offset + 1 with: above lastEntry with: aboveIndex]! !

!TextLCSFinder methodsFor: 'computing commonSequence'!

{ScriptBuilder} fillInTable
	"the bounds are modified by propogateRight and propogateLeft when they reach a boundary."
	| finalDiagonal {LCSDiagonal} finalIndex {IntegerVar} row {IntegerVar} |
	finalDiagonal _ myDiagonals fetch: (myStartString count - myEndString count).
	finalIndex _ (myStartString count min: myEndString count) + 1.
	row _ (myDiagonals fetch: IntegerVar0) lastIndex.
	lowerBound _ (row - 1 == myEndString count) ifTrue: [1] ifFalse: [-1].
	upperBound _ (row - 1 == myStartString count) ifTrue: [-1] ifFalse: [1].

	1 to: (myStartString count + myEndString count) do: 
		[:i {IntegerVar} |
		lowerBound to: upperBound by: 2 do:
			[:diag {IntegerVar} | self propogateTo: diag].
		(finalDiagonal entryAt: finalIndex) == NULL ifFalse:
			[^(ScriptBuilder make: myDiagonals with: myStartString with: myEndString) buildScript].
		lowerBound _ lowerBound - 1.
		upperBound _ upperBound + 1].
	self assert: 'difference should be smaller than the concatenation of the strings.'!

{IntegerVar} sharedLength: column {IntegerVar} with: row {IntegerVar}
	| columns {IntegerVar} rows {IntegerVar} |
	columns _ myDiagonals columns - column.
	rows _ myDiagonals rows - row.
	0 to: (columns min: rows) do: [:i |
		(myStartString at: column + i) = (myEndString at: row + i) ifFalse: [^i]].
	^(columns min: rows) + 1! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextLCSFinder class
	instanceVariableNames: ''!

(TextLCSFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextLCSFinder class methodsFor: 'pseudoConstructors'!

{TextFinder} make: startString {String} with: finishString {String}

	^TextLCSFinder create: startString with: finishString! !