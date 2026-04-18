'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:34 pm'!

Diagonal subclass: #LCSDiagonal
	instanceVariableNames: '
		myEntries {IntegerTable of: IntegerPos}
		myScript {IntegerTable of: EditSequence}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
LCSDiagonal comment:
'LCSDiagonal is used in the computation of Longest Common Sequences by LCSFinder.  See LCSFinder for a more elaborate comment.'!

(LCSDiagonal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSDiagonal methodsFor: 'creation'!

create: offset {IntegerVar}
	super create: offset.
	myEntries _ IntegerTable make.
	myScript _ IntegerTable make.! !

!LCSDiagonal methodsFor: 'accessing'!

{BooleanVar} addDeleteEntryAt: index {IntegerVar} with: entry {IntegerVar} with: editSeq {EditSequence} with: newFragment {CompareFragment}
	"The return value tells whether the argument entry was added, and therefore better.  If it was then my caller will want to propogate it, otherwise it won't have any effect on the table values, and will be forgotten."
	| oldEntry {IntegerPos} |
	oldEntry _ (myEntries intFetch: index) cast: IntegerPos.
	oldEntry == NULL
		ifTrue: [myEntries atInt: index introduce: (IntegerPos make: entry).
				myScript atInt: index introduce: (editSeq copy addDeletion: newFragment).
				^true]
		ifFalse: [(oldEntry asIntegerVar < entry)  "if oldEntry is smaller, do nothing"
			ifFalse: [(entry < oldEntry asIntegerVar)
				ifTrue: [myEntries atInt: index replace: (IntegerPos make: entry).
						myScript atInt: index replace: (editSeq copy addDeletion: newFragment).
						^true]
				ifFalse:
					[((myScript intFetch: index) cast: EditSequence) addSequence: (editSeq copy addDeletion: newFragment).
					^false "Already added to stack, not acted on yet"]]].
	^false!

{BooleanVar} addEntryAt: index {IntegerVar} with: entry {IntegerVar} with: editSeq {EditSequence}
	"The return value tells whether the argument entry was added, and therefore better.  If it was then my caller will want to propogate it, otherwise it won't have any effect on the table values, and will be forgotten."
	| oldEntry {IntegerPos} |
	oldEntry _ (myEntries intFetch: index) cast: IntegerPos.
	oldEntry == NULL
		ifTrue: [myEntries atInt: index introduce: (IntegerPos make: entry).
				myScript atInt: index introduce: editSeq.
				^true]
		ifFalse: [(oldEntry asIntegerVar < entry)  "if oldEntry is smaller, do nothing"
			ifFalse: [(entry < oldEntry asIntegerVar)
				ifTrue: [myEntries atInt: index replace: (IntegerPos make: entry).
						myScript atInt: index replace: editSeq.
						^true]
				ifFalse:
					[((myScript fetch: index) cast: EditSequence) addSequence: editSeq.
					^false "Already added to stack, not acted on yet"]]].
	^false!

{BooleanVar} addInsertEntryAt: index {IntegerVar} with: entry {IntegerVar} with: editSeq {EditSequence} with: newFragment {CompareFragment}
	"The return value tells whether the argument entry was added, and therefore better.  If it was then my caller will want to propogate it, otherwise it won't have any effect on the table values, and will be forgotten."
	| oldEntry {IntegerPos} |
	oldEntry _ (myEntries intFetch: index) cast: IntegerPos.
	oldEntry == NULL
		ifTrue: [myEntries atInt: index introduce: (IntegerPos make: entry).
				myScript atInt: index introduce: (editSeq copy addInsertion: newFragment).
				^true]
		ifFalse: [(oldEntry asIntegerVar < entry)  "if oldEntry is smaller, do nothing"
			ifFalse: [(entry < oldEntry asIntegerVar)
				ifTrue: [myEntries atInt: index replace: (IntegerPos make: entry).
						myScript atInt: index replace: (editSeq copy addInsertion: newFragment).
						^true]
				ifFalse:
					[((myScript intFetch: index) cast: EditSequence) addSequence: (editSeq copy addInsertion: newFragment).
					^false "Already added to stack, not acted on yet"]]].
	^false!

{BooleanVar} addShareEntryAt: index {IntegerVar} with: entry {IntegerVar} with: editSeq {EditSequence} with: newFragment {CompareFragment}
	"The return value tells whether the argument entry was added, and therefore better.  If it was then my caller will want to propogate it, otherwise it won't have any effect on the table values, and will be forgotten."
	| oldEntry {IntegerPos} |
	oldEntry _ (myEntries intFetch: index) cast: IntegerPos.
	oldEntry == NULL
		ifTrue: [myEntries atInt: index introduce: (IntegerPos make: entry).
				myScript atInt: index introduce: (editSeq copy addShare: newFragment).
				^true]
		ifFalse: [(oldEntry asIntegerVar < entry)  "if oldEntry is smaller, do nothing"
			ifFalse: [(entry < oldEntry asIntegerVar)
				ifTrue: [myEntries atInt: index replace: (IntegerPos make: entry).
						myScript atInt: index replace: (editSeq copy addShare: newFragment).
						^true]
				ifFalse:
					[((myScript fetch: index) cast: EditSequence) addSequence: (editSeq copy addShare: newFragment).
					^false "Already added to stack, not acted on yet"]]].
	^false!

{IntegerVar} entryAt: index {IntegerVar}
	| entry {IntegerPos} |
	entry _ (myEntries intFetch: index) cast: IntegerPos.
	(entry == NULL) 
		ifTrue: [^NULL]
		ifFalse: [^entry asIntegerVar]!

{EditSequence} scriptFor: index {IntegerVar}
	^(myScript intFetch: index) cast: EditSequence! !

!LCSDiagonal methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	oo << 'D[' << self offset << ']'.
	myEntries isEmpty ifFalse: [myEntries printOnWithSimpleSyntax: oo with: '(' with: ',' with: ')']! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LCSDiagonal class
	instanceVariableNames: ''!

(LCSDiagonal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LCSDiagonal class methodsFor: 'pseudoConstructors'!

{LCSDiagonal} make: offset {IntegerVar}
	^LCSDiagonal create: offset! !