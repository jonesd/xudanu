'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:40 pm'!

DiagonalMatrix subclass: #TextDiagonalMatrix
	instanceVariableNames: '
		myRows {IntegerVar}
		myColumns {IntegerVar}
		myDiagonals {IntegerTable of: TextDiagonal}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(TextDiagonalMatrix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextDiagonalMatrix methodsFor: 'creation'!

create: colCount {IntegerVar} with: rowCount {IntegerVar}
	super create.
	myRows _ rowCount.
	myColumns _ colCount.
	myDiagonals _ MuArray make: rowCount + colCount + 1.
	rowCount negated to: colCount do: [:index {IntegerVar} | | newDiag {Diagonal} |
		newDiag _ TextDiagonal make: index.
		myDiagonals atInt: index + rowCount introduce: newDiag]! !

!TextDiagonalMatrix methodsFor: 'accessing'!

{IntegerVar} columns
	^myColumns!

{TextDiagonal} fetch: index {IntegerVar}
	^myDiagonals intFetch: myRows + index!

{IntegerVar} rows
	^myRows! !

!TextDiagonalMatrix methodsFor: 'smalltalk: printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(..., '.
	 (myDiagonals subTableBetween: myRows -5 with: myRows + 5) stepper forEach:
	 	[:diag {TextDiagonal} | 
	 	oo << diag << ', '].
	 oo << '...)'.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextDiagonalMatrix class
	instanceVariableNames: ''!

(TextDiagonalMatrix getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextDiagonalMatrix class methodsFor: 'creation'!

{TextDiagonalMatrix} make: rowCount {IntegerVar} with: colCount {IntegerVar}

	^TextDiagonalMatrix create: rowCount with: colCount! !