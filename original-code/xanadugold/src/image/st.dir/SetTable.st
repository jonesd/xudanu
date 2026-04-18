'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:07 pm'!

Heaper subclass: #SetTable
	instanceVariableNames: '
		myHashEntries {SharedPtrArray}
		myTally {Int32}
		myCoordinateSpace {CoordinateSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-SetTable'!
SetTable comment:
'SetTable is a table-like object (NOT at true table) that can store multiple values at a single position.  See MuTable for comments on the protocol.
  The reason that this is not a table subclass is because of several ambiguities in the contract.  For example, replace for a table implies that the position must be previously occupied, but in a settable the position is occupied only if the exact association (key->value) is present.'!

(SetTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!SetTable methodsFor: 'accessing'!

{void} at: aKey {Position} introduce: anObject {Heaper}
	"Store anObject at position aKey; BLAST if position is already occupied
	 (for SetTable, there must be an object that isEqual to anObject at aKey 
	 for the position to be considered occupied)"
	(self at: aKey store: anObject) ifFalse: [Heaper BLAST: #AlreadyInTable]!

{BooleanVar} at: aKey {Position} store: anObject {Heaper}
	"Store anObject at position aKey; return TRUE if store accomplished, FALSE otherwise"
	| index {Int32 register} entry {TableEntry} |
	anObject == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	self aboutToWrite.
	self checkSize.
	index _ aKey hashForEqual \\ myHashEntries count.
	entry _ (myHashEntries fetch: index) cast: TableEntry.
	[entry ~~ NULL] whileTrue:
		[((entry match: aKey) and: [entry matchValue: anObject]) ifTrue: [^false].
		entry _ entry fetchNext].
	entry _ TableEntry make: aKey with: anObject.
	entry setNext: ((myHashEntries fetch: index) cast: TableEntry).
	myHashEntries at: index store: entry.
	myTally _ myTally + 1.
	^true!

{void} atInt: index {IntegerVar} introduce: anObject {Heaper}
	(self atInt: index store: anObject) ifFalse: [Heaper BLAST: #AlreadyInTable]!

{BooleanVar} atInt: index {IntegerVar} store: anObject {Heaper} 
	| offset {Int32 register} entry {TableEntry} |
	anObject == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	self aboutToWrite.
	self checkSize.
	offset _ (IntegerPos integerHash: index) \\ myHashEntries count.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	[entry ~~ NULL] whileTrue:
		[((entry matchInt: index) and: [entry matchValue: anObject]) ifTrue: [^false].
		entry _ entry fetchNext].
	entry _ TableEntry make.IntegerVar: index with: anObject.
	entry setNext: ((myHashEntries fetch: offset) cast: TableEntry).
	myHashEntries at: offset store: entry.
	myTally _ myTally + 1.
	^true!

{CoordinateSpace INLINE} coordinateSpace

	^ myCoordinateSpace!

{IntegerVar INLINE} count

	^ Integer IntegerVar: myTally!

{XnRegion} domain
	| result {XnRegion} keys {TableStepper} |
	result _ self coordinateSpace emptyRegion.
	(keys _ self stepper) forEach: [ :element {Heaper} |
		result _ result with: keys position].
	^result!

{void} intRemove: index {IntegerVar} with: value {Heaper}
	(self wipe.IntegerVar: index with: value) ifFalse: [Heaper BLAST: #NotInTable]!

{void} remove: key {Position} with: value {Heaper}
	(self wipeAssociation: key with: value) ifFalse: [Heaper BLAST: #NotInTable]!

{BooleanVar} wipe.IntegerVar: index {IntegerVar} with: value {Heaper}
	| offset {Int32 register} prev {TableEntry} entry {TableEntry} |
	offset _ (IntegerPos integerHash: index) \\ myHashEntries count.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	prev _ entry.
	[entry ~~ NULL] whileTrue:
		[((entry matchInt: index) and: [entry matchValue: value]) ifTrue:
			[self aboutToWrite.
			(entry isEqual: prev)
				ifTrue: [myHashEntries at: offset store: entry fetchNext]
				ifFalse: [prev setNext: entry fetchNext].
			entry destroy.
			entry _ NULL.
			prev _ NULL.
			myTally _ myTally - 1.
			^true].
		prev _ entry.
		entry _ entry fetchNext].
	^false!

{BooleanVar} wipeAssociation: key {Position} with: value {Heaper}
	| offset {Int32 register} prev {TableEntry} entry {TableEntry} |
	offset _ key hashForEqual \\ myHashEntries count.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	prev _ NULL.
	[entry ~~ NULL] whileTrue:
		[((entry match: key) and: [entry matchValue: value]) ifTrue:
			[self aboutToWrite.
			prev == NULL
				ifTrue: [myHashEntries at: offset store: entry fetchNext]
				ifFalse: [prev setNext: entry fetchNext].
			entry destroy.
			entry _ prev _ NULL.
			myTally _ myTally - 1.
			^true].
		prev _ entry.
		entry _ entry fetchNext].
	^false! !

!SetTable methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name.
	self printOnWithSimpleSyntax: oo with: '[' with: ', ' with: ']'!

{void} printOnWithSimpleSyntax: oo {ostream reference} with: open {char star} with: sep {char star} with: close {char star} 
	| stomp {TableStepper} |
	oo << open.
	self isEmpty
		ifTrue: [oo << 'empty']
		ifFalse: 
			[stomp _ self stepper.
			oo << stomp position << '->' << stomp fetch.
			stomp step.
			stomp forEach: [:val {Heaper} |
				oo << sep << stomp position << '->' << val]].
	oo << close! !

!SetTable methodsFor: 'runLength'!

{XnRegion} runAt: index {Position}
	
	(self includesKey: index)
		ifTrue: [^ index asRegion]
		ifFalse: [^ myCoordinateSpace emptyRegion]!

{XnRegion} runAtInt: index {IntegerVar}
	
	^ self runAt: index integer! !

!SetTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	"ignore order spec for now"
	order == NULL 
		ifTrue: [^TableEntry bucketStepper: myHashEntries]
		ifFalse: [self unimplemented.
			^NULL "fodder"]!

{Stepper} stepperAt: key {Position}

	| offset {Int32 register} elements {PrimSet} entry {TableEntry wimpy} |
	offset _ key hashForEqual \\ myHashEntries count.
	elements _ PrimSet make.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	[entry ~~ NULL] whileTrue:
		[(entry match: key) 
			ifTrue: [elements introduce: entry value].
		entry _ entry fetchNext].
	^elements stepper!

{Stepper} stepperAtInt: index {IntegerVar}

	| offset {Int32 register} elements {PtrArray} entry {TableEntry wimpy} i {Int32} |
	offset _ (IntegerPos integerHash: index) \\ myHashEntries count.
	elements _ SetTableStepper array.
	i _ Int32Zero.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	[entry ~~ NULL] whileTrue:
		[(entry matchInt: index) 
			ifTrue: [
				i >= elements count ifTrue: [elements _ (elements copyGrow: 4) cast: PtrArray].
				elements at: i store: entry value.
				i := i + 1].
		entry _ entry fetchNext].
	^SetTableStepper make: elements.! !

!SetTable methodsFor: 'creation'!

create: entries {SharedPtrArray of: TableEntry} with: tally {Int32} with: cs {CoordinateSpace} 
	super create.
	myHashEntries _ entries.
	myTally _ tally.
	myCoordinateSpace _ cs.
	myHashEntries shareMore!

{void} destruct
	myHashEntries shareLess.
	super destruct!

{SetTable INLINE} emptySize: size {IntegerVar}
	"return an empty table just like the current one"

	^SetTable make: myCoordinateSpace with: size! !

!SetTable methodsFor: 'smalltalk:'!

stepper
	^self stepper: NULL! !

!SetTable methodsFor: 'testing'!

{BooleanVar} at: key {Position} includes: value {Heaper}
	(self stepperAt: key) forEach: [:val {Heaper} | (val isEqual: value) ifTrue: [^true]].
	^false!

{BooleanVar} includesKey: aKey {Position}
	| stp {Stepper} result {BooleanVar} |
	stp _ self stepperAt: aKey.
	result _ stp hasValue.
	stp destroy.
	^result!

{BooleanVar} isEmpty
	^self count == IntegerVar0! !

!SetTable methodsFor: 'private: resize'!

{void} aboutToWrite
	"If my contents are shared, and I'm about to change them, make a copy of them."
	myHashEntries shareCount > 1 ifTrue:
		[| newEntries {SharedPtrArray of: TableEntry} entryCount {Int32} |
		entryCount _ myHashEntries count.
		newEntries _ SharedPtrArray make: entryCount.
		Int32Zero almostTo: entryCount do: [:index {Int32} | 
			| entry {TableEntry wimpy} |
			(entry _ (myHashEntries fetch: index) cast: TableEntry) ~~ NULL ifTrue: 
				[| newEntry {TableEntry} |
				newEntry _ entry copy.
				newEntries at: index store: newEntry.
				entry _ entry fetchNext.
				[entry ~~ NULL] whileTrue: 
					[newEntry setNext: entry copy.
					newEntry _ newEntry fetchNext.
					entry _ entry fetchNext]]].
		myHashEntries shareLess.
		myHashEntries _ newEntries.
		myHashEntries shareMore]!

{void} checkSize
	| oldEntries {SharedPtrArray} oldSize {Int32} newSize {Int32} |
	myTally > (myHashEntries count * 3)
		ifTrue:
			[oldSize _ myHashEntries count.
			newSize _ PrimeSizeProvider make uInt32PrimeAfter: (oldSize * 4).
			myHashEntries shareLess.
			oldEntries _ myHashEntries.
			myHashEntries _ SharedPtrArray make: newSize.
			myHashEntries shareMore.
			Int32Zero almostTo: oldSize do: [:j {Int32 register} |
				| cur {TableEntry} next {TableEntry} |
				cur _ (oldEntries fetch: j) cast: TableEntry.
				[cur ~~ NULL] whileTrue: 
					[next _ cur fetchNext.
					self storeEntry: cur.
					cur _ next]].
			oldEntries destroy]!

{void} storeEntry: entry {TableEntry}
	| idx {UInt32} |
	(myCoordinateSpace isEqual: IntegerSpace make)
		ifTrue: [idx _ IntegerPos integerHash: entry index ]
		ifFalse: [idx _ entry position hashForEqual].
	idx _ idx \\ myHashEntries count.
	entry setNext: ((myHashEntries fetch: idx) cast: TableEntry).
	myHashEntries at: idx store: entry! !

!SetTable methodsFor: 'smalltalk: private: smalltalk private'!

{void} inspect
	^InspectorView open: (SetTableInspector inspect: self)! !

!SetTable methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myHashEntries _ receiver receiveHeaper.
	myTally _ receiver receiveInt32.
	myCoordinateSpace _ receiver receiveHeaper.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myHashEntries.
	xmtr sendInt32: myTally.
	xmtr sendHeaper: myCoordinateSpace.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SetTable class
	instanceVariableNames: ''!

(SetTable getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #COPY; yourself)!

!SetTable class methodsFor: 'creation'!

{SetTable INLINE} make: cs {CoordinateSpace}
	^self make: cs with: 7!

make: cs {CoordinateSpace} with: size {IntegerVar}
	^self create: (SharedPtrArray make: (size DOTasLong bitOr: 1)) with: Int32Zero with: cs! !