'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:38 pm'!

Heaper subclass: #ScriptBuilder
	instanceVariableNames: '
		curDiagonal {Diagonal}
		curIndex {IntegerVar}
		myMatrix {IntegerVar}
		myScript {IntegerTable of: EditOperation}
		lastScriptEntry {IntegerVar}
		myStartString {AttributedTextModel}
		myEndString {AttributedTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
ScriptBuilder comment:
'ScriptBuilder takes a DiagonalMatrix, and builds an edit script for the least cost path from the start to the finish.  '!



!ScriptBuilder methodsFor: 'creation'!

create: matrix {DiagonalMatrix} with: startString {AttributedTextModel} with: endString {AttributedTextModel}
	super create.
	myMatrix _ matrix.
	myStartString _ startString.
	myEndString _ endString.
	lastScriptEntry _ IntegerVar0.! !

!ScriptBuilder methodsFor: 'emphasizing'!

emphasize: aString {Sting}
	| result {Text} |
	result _ Text fromString: aString.
	(myStartString = aString) ifTrue: 
		[myScript stepper forEach: [:op {PrimOperation} |
		op isPureInsert ifTrue:
			[result emphasizeFrom: op nextStartPosition + 1 to: op nextStartPosition + 1 with: 2].
		op isPureDelete ifTrue:
			[result emphasizeFrom: op startPosition to: op nextStartPosition - 1 with: 13]].
		^result].
	(myEndString = aString) ifTrue: 
		[myScript stepper forEach: [:op {PrimOperation} |
		op isPureInsert ifTrue:
			[result emphasizeFrom: op finalPosition to: op nextFinalPosition - 1 with: 13].
		op isPureDelete ifTrue:
			[result emphasizeFrom: op nextFinalPosition + 1 to: op nextFinalPosition + 1 with: 2]].
		^result].
	^'cache error'! !

!ScriptBuilder methodsFor: 'matching'!

matches: firstString with: secondString 
	^(firstString = myStartString and: [secondString = myEndString])
		or: [secondString = myStartString and: [firstString = myEndString]]! !

!ScriptBuilder methodsFor: 'accessing values'!

{IntegerVar | NULL} aboveValue
	| offset {IntegerVar} aboveIndex {IntegerVar} diag {Diagonal}|
	offset _ curDiagonal offset.
	aboveIndex _ (offset < IntegerVar0 ifTrue: [curIndex] ifFalse: [curIndex - 1]).
	diag _ myMatrix fetch: offset + 1.
	diag == NULL ifTrue: [^NULL].
	^diag entryAt: aboveIndex.!

{IntegerVar} curValue
	^curDiagonal entryAt: curIndex!

{IntegerVar} leftValue
	| offset {IntegerVar} leftIndex {IntegerVar} diag {Diagonal} |
	offset _ curDiagonal offset.
	leftIndex _ offset > IntegerVar0 ifTrue: [curIndex] ifFalse: [curIndex - 1].
	diag _ myMatrix fetch: offset - 1.
	diag == NULL ifTrue: [^NULL].
	^diag entryAt: leftIndex!

{IntegerVar} rawShareLength
	| row column |
	row _ curDiagonal rowFor: curIndex.
	column _ curDiagonal columnFor: curIndex.
	1 to: curIndex - 1 do: [:index |
		(myStartString at: column - index) = (myEndString at: row - index) ifFalse: [^index - 1]].
	^curIndex - 1!

script
	^myScript!

{IntegerVar} shareLength
	| length {IntegerVar} |
	length _ self rawShareLength.
	length to: 1 by: -1 do: [:l |
		(curDiagonal entryAt: curIndex - l) ~~ NULL ifTrue: [^l]].
	self BLAST: 'impossible error condition: couldn''t move up, left, or diagonnally'! !

!ScriptBuilder methodsFor: 'creating script'!

{ScriptBuilder} buildScript
	curDiagonal _ myMatrix fetch: (myMatrix columns - myMatrix rows).
	curIndex _ (myMatrix columns min: myMatrix rows) + 1.
	myScript _ IntegerTable make: myMatrix columns + myMatrix rows.
	[curIndex > 1 or: [curDiagonal offset ~~ 0]] whileTrue: [self pushBack].
	myMatrix _ nil.!

{ void } pushBack
	| curValue {IntegerVar} leftValue {IntegerVar} |
	curValue _ self curValue.
	leftValue _ self leftValue.
	(leftValue ~~ NULL and: [(curValue - 1 - leftValue) == IntegerVar0])
		ifTrue: [self pushLeft]
		ifFalse:
			[ | aboveValue {IntegerVar} |
			aboveValue _ self aboveValue.
			(aboveValue ~~ NULL and: [(curValue - 1 - aboveValue) == IntegerVar0])
				ifTrue: [self pushUp]
				ifFalse: [self pushDiagonal]]!

{ void } pushDiagonal
	"move the current position up and left, and add an entry to myScript reflecting text to be shared"

	| nextFragment {CompareFragment} startColumn {IntegerVar} op {ShareOperation} shareLength |
	shareLength _ self shareLength.
	startColumn _ curDiagonal columnFor: curIndex.
	nextFragment _ TextFragment make: (myStartString copyFrom: startColumn - shareLength to: startColumn - 1).
	op _ ShareOperation make: startColumn - shareLength
						with: (curDiagonal rowFor: curIndex) - shareLength
						with: nextFragment.
	myScript atInt: lastScriptEntry store: op.
	lastScriptEntry _ lastScriptEntry + 1.
	curIndex _ curIndex - shareLength.!

{ void } pushLeft
	"move the current position to the left, and add an entry to myScript reflecting text to be deleted"

	| nextFragment {CompareFragment} column {IntegerVar} op {InsertOperation} prevIndex {IntegerVar} |
	prevIndex _ (curDiagonal offset > IntegerVar0 ifTrue: [curIndex] ifFalse: [curIndex - 1]).
	column _ curDiagonal columnFor: curIndex.
	nextFragment _ TextFragment make: (myStartString copyFrom: column - 1 to: column - 1).
	op _ DeleteOperation make: column - 1 with: (curDiagonal rowFor: curIndex) - 1 with: nextFragment.
	myScript atInt: lastScriptEntry store: op.
	lastScriptEntry _ lastScriptEntry + 1.
	curDiagonal _ myMatrix fetch: curDiagonal offset - 1.
	curIndex _ prevIndex.!

{ void } pushUp
	"move the current position up, and add an entry to myScript reflecting text to be added"

	| nextFragment {CompareFragment} row {IntegerVar} op {DeleteOperation} prevIndex {IntegerVar} |
	prevIndex _ (curDiagonal offset < IntegerVar0 ifTrue: [curIndex] ifFalse: [curIndex - 1]).
	row _ curDiagonal rowFor: curIndex.
	nextFragment _ TextFragment make: (myEndString copyFrom: row - 1 to: row - 1).
	op _ InsertOperation make: (curDiagonal columnFor: curIndex) - 1 with: row - 1 with: nextFragment.
	myScript atInt: lastScriptEntry store: op.
	lastScriptEntry _ lastScriptEntry + 1.
	curDiagonal _ myMatrix fetch: curDiagonal offset + 1.
	curIndex _ prevIndex.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScriptBuilder class
	instanceVariableNames: ''!



!ScriptBuilder class methodsFor: 'creation'!

{ScriptBuilder} make: matrix {DiagonalMatrix} with: startString {AttributedTextModel} with: endString {AttributedTextModel}

	^ScriptBuilder create: matrix with: startString with: endString! !