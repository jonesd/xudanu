'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:40 pm'!

Diagonal subclass: #TextDiagonal
	instanceVariableNames: '
		myEntries {IntegerTable of: IntegerPos}
		lastIndex {IntegerPos}
		lastEntry {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(TextDiagonal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextDiagonal methodsFor: 'accessing'!

{BooleanVar} addEntryAt: index {IntegerVar} with: entry {IntegerVar}
	myEntries atInt: index store: entry.
	lastIndex _ index.
	lastEntry _ entry.
	^true!

{IntegerVar} entryAt: index {IntegerVar}
	^myEntries intFetch: index!

{IntegerVar} lastEntry

	^lastEntry!

{IntegerVar} lastIndex

	^lastIndex! !

!TextDiagonal methodsFor: 'creation'!

create: offset {IntegerVar}
	super create: offset.
	myEntries _ IntegerTable make.
	myEntries atInt: 1 introduce: offset abs.
	lastIndex _ 1.
	lastEntry _ offset abs.! !

!TextDiagonal methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'D[' << self offset << ']'.
	myEntries isEmpty ifFalse: [myEntries printOnWithSimpleSyntax: oo with: '(' with: ',' with: ')']! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextDiagonal class
	instanceVariableNames: ''!

(TextDiagonal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextDiagonal class methodsFor: 'creation'!

{TextDiagonal} make: index {IntegerVar}

	^TextDiagonal create: index! !