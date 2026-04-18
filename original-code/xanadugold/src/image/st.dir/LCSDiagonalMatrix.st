'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:35 pm'!

DiagonalMatrix subclass: #LCSDiagonalMatrix
	instanceVariableNames: '
		myRows {IntegerVar}
		myColumns {IntegerVar}
		myDiagonals {IntegerTable of: LCSDiagonal}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
LCSDiagonalMatrix comment:
'LCSDiagonalMatrix is used in the computation of Longest Common Sequences by LCSFinder.  See LCSFinder for a more elaborate comment.'!

(LCSDiagonalMatrix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSDiagonalMatrix methodsFor: 'creation'!

create: colCount {IntegerVar} with: rowCount {IntegerVar}
	super create.
	myRows _ rowCount.
	myColumns _ colCount.
	myDiagonals _ MuArray make: rowCount + colCount + 1.
	rowCount negated to: colCount do: [:index {IntegerVar} | | newDiag {LCSDiagonal} |
		newDiag _ LCSDiagonal create: index.
		myDiagonals atInt: index + rowCount introduce: newDiag]! !

!LCSDiagonalMatrix methodsFor: 'accessing'!

{IntegerVar} columns
	^myColumns!

{LCSDiagonal} fetch: index {IntegerVar}
	^(myDiagonals intFetch: myRows + index) cast: LCSDiagonal!

{IntegerVar} rows
	^myRows! !

!LCSDiagonalMatrix methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	myDiagonals isEmpty ifFalse: [myDiagonals printOnWithSimpleSyntax: oo with: '(' with: '
' with: ')']! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LCSDiagonalMatrix class
	instanceVariableNames: ''!

(LCSDiagonalMatrix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSDiagonalMatrix class methodsFor: 'creation'!

{LCSDiagonalMatrix} make: rowCount {IntegerVar} with: colCount {IntegerVar}

	^LCSDiagonalMatrix create: rowCount with: colCount! !