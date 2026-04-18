'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:39 pm'!

Heaper subclass: #TextComparator
	instanceVariableNames: '
		myStartMoves {IntegerTable of: PrimFragment}
		myFinalMoves {IntegerTable of: PrimFragment}
		myInsertions {IntegerTable of: CompareFragment}
		myDeletions {IntegerTable of: CompareFragment}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!
TextComparator comment:
'TextComparator takes in a mapping from one document to another, and constructs tables of CompareFragments representing the parts of the documents that are shared in different ways.  '!

(TextComparator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextComparator methodsFor: 'comparison'!

{EditSequence} findLCS
	| startArray {IntegerTable of: Move} startTable {IntegerTable of: CompareFragment}
	  endArray {IntegerTable of: Move} endTable {IntegerTable of: CompareFragment} |

	startTable _ myStartMoves copy cast: IntegerTable.
	startTable storeAll: myDeletions.
	startArray _ IntegerTable make: myStartMoves count.
	startTable stepper forEach: [:eachMove {CompareFragment} |
			startArray atInt: startArray count + 1 store: eachMove].

	endTable _ myFinalMoves copy cast: IntegerTable.
	endTable storeAll: myInsertions.
	endArray _ IntegerTable make: myFinalMoves count.
	endTable stepper forEach: [:eachMove {CompareFragment} |
			endArray atInt: endArray count + 1 store: eachMove].
	^(LCSFinder make: startArray with: endArray) fillInTable! !

!TextComparator methodsFor: 'initialize'!

{IntegerTable of: PrimFragment} copyMovesByDestination: inputMoves {IntegerTable of: PrimFragment}
	"return a table of all of the moves with each stored at all of the destinations it specifies"
	| moves {IntegerTable of: PrimFragment} |
	moves _ IntegerTable make.
	inputMoves stepper forEach: [:eachMove {PrimFragment} |
		eachMove finalLocations stepper forEach: [:eachDest {IntegerPos} |
			moves _ eachMove mergeInto: moves with: eachDest asIntegerVar]].
	^moves!

{IntegerTable of: PrimFragment} copyMovesByOrigin: inputMoves {IntegerTable of: PrimFragment}
	"return a table of all of the moves with each stored at all of the origins it specifies"
	| moves {IntegerTable of: PrimFragment} |
	moves _ IntegerTable make.
	inputMoves stepper forEach: [:eachMove {PrimFragment} |
		eachMove startLocations stepper forEach: [:eachStart {IntegerPos} |
			moves _ eachMove mergeInto: moves with: eachStart asIntegerVar]].
	^moves!

{IntegerTable of: PrimFragment} fixOverlapsIn: inputMoves {IntegerTable of: PrimFragment}
	"iterate through the table, making sure that none of the PrimFragments overlaps with the next."

	| moves {IntegerTable of: PrimFragment} lowerBound {IntegerVar} curMove {PrimFragment} overlapRegion {IntegerRegion} |
	moves _ inputMoves copy cast: IntegerTable.
	lowerBound _ moves lowestIndex.
	[(moves intFetch: lowerBound) == NULL] whileFalse: 
		[curMove _ (moves intFetch: lowerBound) cast: PrimFragment.
		overlapRegion _ ((IntegerRegion make: lowerBound + 1 with: lowerBound + curMove count)
								intersect: moves domain) cast: IntegerRegion. "use firstElemAfter: if possible"
		overlapRegion isEmpty
			ifFalse: [ | newMoves {Pair of: PrimFragment} |
				newMoves _ curMove breakAt: overlapRegion start - lowerBound.
				moves atInt: lowerBound replace: newMoves left.
				moves _ (newMoves right cast: PrimFragment) mergeInto: moves with: overlapRegion start.
				lowerBound _ overlapRegion start]
			ifTrue: [ | nextRegion { IntegerRegion} |
				nextRegion _ ((IntegerRegion after: lowerBound + curMove count) 
								intersect: moves domain) cast: IntegerRegion.  "use firstElemAfter: if possible"
				nextRegion isEmpty 
					ifTrue: [lowerBound _ lowerBound + curMove count "move past the end"]
					ifFalse: [lowerBound _ nextRegion start]]].
	^moves

	"I'd bet that all of the time in this routine is in the region intersections.  What I really want 
	to know is firstElemAfter:, but it's a private method.    --cth  9/14/90"!

{void} setDeletionsFrom: dRegion {IntegerRegion} with: size {IntegerVar}
	| deleteRegion {IntegerRegion} |

	deleteRegion _ ((IntegerRegion make: IntegerVar0 with: size) intersect: dRegion) cast: IntegerRegion.
	myDeletions _ IntegerTable make.
	deleteRegion simpleRegions forEach: [:simple {IntegerRegion} |
		myDeletions atInt: simple start introduce: (DeleteFragment make: simple count with: simple)]!

{void} setInsertionsFrom: iRegion {IntegerRegion} with: size {IntegerVar}
	| insertRegion {IntegerRegion} |

	insertRegion _ ((IntegerRegion make: IntegerVar0 with: size) intersect: iRegion) cast: IntegerRegion.
	myInsertions _ IntegerTable make.
	insertRegion simpleRegions forEach: [:simple {IntegerRegion} |
		myInsertions atInt: simple start introduce: (InsertFragment make: simple count with: simple)]!

{void} setUpFromDocs: orig {XuText} with: final {XuText}
	"The algorithm needs two passes in order to find overlaps in both the original and the final doc."
	| simpleMapping {Mapping} firstPass {IntegerTable of: PrimFragment} secondPass {IntegerTable of: PrimFragment} |
	simpleMapping _ orig compare: final.
	self setInsertionsFrom: (simpleMapping range complement cast: IntegerRegion) with: final count.
	self setDeletionsFrom: (simpleMapping domain complement cast: IntegerRegion) with: orig count.
	firstPass _ self fixOverlapsIn: (self setUpSourceMoves: simpleMapping simpleRegionMappings).
	secondPass _ self fixOverlapsIn: (self copyMovesByDestination: firstPass).
	myStartMoves _ IntegerTable make.
	myFinalMoves _ IntegerTable make.
	secondPass stepper forEach: [:eachMove {PrimFragment}|
		eachMove startLocations stepper forEach: [:eachStart {IntegerPos} |
			myStartMoves at: eachStart store: eachMove].
		eachMove finalLocations stepper forEach: [:eachEnd {IntegerPos} |
			myFinalMoves at: eachEnd store: eachMove]].!

{IntegerTable} setUpSourceMoves:  mappings {ImmuSet of: Mapping} 
	| moves {IntegerTable of: PrimFragment} srcStart {IntegerVar} newMove {PrimFragment} |
	moves _ IntegerTable make.
	mappings stepper forEach: [:each {Mapping} |
		srcStart _ (each domain cast: IntegerRegion) start.
		newMove _ PrimFragment make: (each domain cast: IntegerRegion) count with: srcStart with: (each range cast: IntegerRegion) start.
		moves _ newMove mergeInto: moves with: srcStart].
	^moves!

{IntegerTable} setUpSourcePrimFragments:  mappings {ImmuSet of: Mapping} 
	| moves {IntegerTable of: PrimFragment} srcStart {IntegerVar} newMove {PrimFragment} |
	moves _ IntegerTable make.
	mappings stepper forEach: [:each {Mapping} |
		srcStart _ (each domain cast: IntegerRegion) start.
		newMove _ PrimFragment make: (each domain cast: IntegerRegion) count
								with: srcStart
								with: (each range cast: IntegerRegion) start.
		moves _ newMove mergeInto: moves with: srcStart].
	^moves! !

!TextComparator methodsFor: 'creation'!

create.IntegerTable: aTable {IntegerTable of: CompareOperation} with.IntegerTable: anotherTable {IntegerTable of: CompareOperation}
	super create.
	myStartMoves _ aTable.
	myFinalMoves _ anotherTable.
	myInsertions _ IntegerTable make: IntegerVar0.
	myDeletions _ IntegerTable make: IntegerVar0.!

create: aText {XuText} with: anotherText {XuText}
	super create.
	self setUpFromDocs: aText with: anotherText.! !

!TextComparator methodsFor: 'accessing'!

{IntegerTable} deletions
	^myDeletions!

{IntegerTable of: PrimFragment} finalMoves
	^myFinalMoves!

{IntegerTable} insertions
	^myInsertions!

{IntegerTable of: PrimFragment} startMoves
	^myStartMoves! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextComparator class
	instanceVariableNames: ''!

(TextComparator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextComparator class methodsFor: 'pseudoConstructors'!

{TextComparator} make.IntegerTable: aTable {IntegerTable of: CompareOperation} with.IntegerTable: anotherTable {IntegerTable of: CompareOperation}

	^TextComparator create.IntegerTable: aTable with.IntegerTable: anotherTable!

{TextComparator} make: aText {XuText} with: anotherText {XuText}

	^TextComparator create: aText with: anotherText! !