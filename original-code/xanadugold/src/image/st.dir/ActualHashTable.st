'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:51 pm'!

HashTable subclass: #ActualHashTable
	instanceVariableNames: '
		myHashEntries {SharedPtrArray NOCOPY}
		myTally {Int32}
		myCoordinateSpace {CoordinateSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
ActualHashTable comment:
'The HashTable is an implementation class that is intended to provide the weakest Position->Object mapping.  It can map from arbitrary Position classes (such as HeaperAsPosition or TreePosition).  HashTable can also be used for very sparse integer domains.
	
	HashTable, and the entire hashtab module, is private implementation.  Not to be included by clients.'!

(ActualHashTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class HashTable */
friend SPTR(HashTable)  actualHashTable (APTR(CoordinateSpace) cs);
friend SPTR(HashTable)  actualHashTable (APTR(CoordinateSpace) cs, IntegerVar size);
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!ActualHashTable methodsFor: 'accessing'!

{Heaper | NULL} at: key {Position} store: aHeaper {Heaper} 
	| offset {Int32} entry {TableEntry | NULL} prev {TableEntry | NULL} |
	aHeaper == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	self aboutToWrite.
	self checkSize.
	offset _ key hashForEqual \\ myHashEntries count.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	prev _ NULL.
	[entry ~~ NULL] whileTrue:
		[(entry match: key) ifTrue:
			[| result {Heaper} |
			result _ entry value.
			(entry replaceValue: aHeaper) ifFalse:
				["Replace the whole entry object if it cannot be side-effected in place."
				| newEntry {TableEntry} |
				newEntry _ TableEntry make: key with: aHeaper.
				newEntry setNext: entry fetchNext.
				prev == NULL
					ifTrue: [myHashEntries at: offset store: newEntry]
					ifFalse: [prev setNext: newEntry].
				entry destroy.].
			^result].
		prev _ entry.
		entry _ entry fetchNext].
	entry _ TableEntry make: key with: aHeaper.
	entry setNext: ((myHashEntries fetch: offset) cast: TableEntry).
	myHashEntries at: offset store: entry.
	myTally _ myTally + 1.
	^NULL!

{Heaper | NULL} atInt: key {IntegerVar} store: aHeaper {Heaper} 
	| offset {Int32} entry {TableEntry | NULL} prev {TableEntry | NULL} |
	aHeaper == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	self aboutToWrite.
	self checkSize.
	offset _ (IntegerPos integerHash: key) \\ myHashEntries count.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	prev _ NULL.
	[entry ~~ NULL] whileTrue:
		[(entry matchInt: key) ifTrue:
			[| result {Heaper} |
			result _ entry value.
			(entry replaceValue: aHeaper) ifFalse:
				["Replace the whole entry object if it cannot be side-effected in place."
				| newEntry {TableEntry} |
				newEntry _ TableEntry make.IntegerVar: key with: aHeaper.
				newEntry setNext: entry fetchNext.
				prev == NULL
					ifTrue: [myHashEntries at: offset store: newEntry]
					ifFalse: [prev setNext: newEntry].
				entry destroy.].
			^result].
		prev _ entry.
		entry _ entry fetchNext].
	entry _ TableEntry make.IntegerVar: key with: aHeaper.
	entry setNext: ((myHashEntries fetch: offset) cast: TableEntry).
	myHashEntries at: offset store: entry.
	myTally _ myTally + 1.
	^NULL!

{CoordinateSpace} coordinateSpace

	^ myCoordinateSpace!

{IntegerVar} count

	^ Integer IntegerVar: myTally!

{XnRegion} domain
	|keys {TableStepper} |
	keys _ self stepper.
	(self coordinateSpace == IntegerSpace make)
		ifTrue: [|result {IntegerRegion} |
			result _ IntegerRegion make.
			[keys hasValue] whileTrue:
				[result _ (result withInt: keys index) cast: IntegerRegion. "This is stupid, I should not need a cast here"
				keys step].
			keys destroy.
			^result]
		ifFalse: [|result {XnRegion} |
			result _ self coordinateSpace emptyRegion.
			[keys hasValue] whileTrue:
				[result _ result with: keys position.
				keys step].
			keys destroy.
			^ result].!

{Heaper | NULL} fetch: key {Position} 

	| offset {Int32} entry {TableEntry wimpy} |
	offset _ key hashForEqual \\ myHashEntries count.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	[entry ~~ NULL] whileTrue:
		[(entry match: key) ifTrue: [^entry value].
		entry _ entry fetchNext].
	^NULL!

{Heaper | NULL} intFetch: key {IntegerVar} 

	| offset {Int32} entry {TableEntry wimpy} |
	offset _ (IntegerPos integerHash: key) \\ myHashEntries count.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	[entry ~~ NULL] whileTrue:
		[(entry matchInt: key) ifTrue: [^entry value].
		entry _ entry fetchNext].
	^NULL!

{ScruTable} subTable: region {XnRegion}

	| newTable {HashTable} elements {TableStepper} |
	newTable _ HashTable make.CoordinateSpace: myCoordinateSpace with: region count.
	elements _ self stepper.
	elements forEach:
		[:elemValue {Heaper} | (region hasMember: elements position) ifTrue:
			[newTable at: elements position store: elemValue]].
	^newTable!

{BooleanVar} wipe: aKey {Position} 
	| offset {UInt32} prev {TableEntry wimpy | NULL} entry {TableEntry wimpy | NULL} |
	offset _ aKey hashForEqual \\ myHashEntries count.
	entry _ (myHashEntries fetch: offset) cast: TableEntry.
	prev _ NULL.
	[entry ~~ NULL] whileTrue:
		[(entry match: aKey) ifTrue: 
			[self aboutToWrite.
			prev == NULL
				ifTrue: [myHashEntries at: offset store: entry fetchNext]
				ifFalse: [prev setNext: entry fetchNext].
			entry destroy.
			myTally _ myTally - 1.
			^true].
		prev _ entry.
		entry _ entry fetchNext].
	^false! !

!ActualHashTable methodsFor: 'testing'!

{UInt32} fastHash
	| result {UInt32 register} entry {TableEntry wimpy} |
	result _ self getCategory hashForEqual + myTally.
	Int32Zero almostTo: myHashEntries count do: 
		[:i {Int32} | 
		entry _ (myHashEntries fetch: i) cast: TableEntry.
		[entry ~~ NULL]
			whileTrue: 
				[result _ result + entry hashForEqual.
				entry _ entry fetchNext]].
	^result!

{BooleanVar} includesKey: aKey {Position}
	^ (self fetch: aKey) ~~ NULL!

{BooleanVar} isEmpty
	^ myTally == Int32Zero! !

!ActualHashTable methodsFor: 'creation'!

{ScruTable} copy 
	^ActualHashTable create: myHashEntries with: self count DOTasLong with: self coordinateSpace!

{ScruTable} emptySize: size {IntegerVar}
	^ActualHashTable make: myCoordinateSpace with: size! !

!ActualHashTable methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name.
	self printOnWithSimpleSyntax: oo with: '[' with: ', ' with: ']'! !

!ActualHashTable methodsFor: 'runLength'!

{XnRegion} runAt: index {Position}
	
	(self includesKey: index)
		ifTrue: [^ index asRegion]
		ifFalse: [^ myCoordinateSpace emptyRegion]! !

!ActualHashTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec default: NULL}
	"ignore order spec for now"
	order == NULL 
		ifTrue: [^ TableEntry bucketStepper: myHashEntries]
		ifFalse: [self unimplemented].
	^NULL "fodder"!

{Heaper} theOne
	| entry {TableEntry wimpy} |
	myTally ~~ 1 ifTrue: [Heaper BLAST: #NotOneElement].
	Int32Zero almostTo: myHashEntries count do: [:index {Int32} |
		(entry _ (myHashEntries fetch: index) cast: TableEntry) ~~ NULL ifTrue: [^entry value]].
	^ NULL. "Keep the compiler quiet"! !

!ActualHashTable methodsFor: 'hooks:'!

{void RECEIVE.HOOK} receiveHashTable: rcvr {Rcvr} 
	"This currently doesn't take advantage of the optimizations in TableEntries.  It should."

	myHashEntries _ SharedPtrArray make: myTally // 2 + 1.
	myHashEntries shareMore.
	(myCoordinateSpace isEqual: IntegerSpace make)
		ifTrue: [myTally timesRepeat: 
				[| index {IntegerVar} |
				index _ rcvr receiveIntegerVar.
				self storeEntry: (TableEntry make.IntegerVar: index with: rcvr receiveHeaper)]]
		ifFalse: [myTally timesRepeat: 
				[| key {Position} |
				key _ rcvr receiveHeaper cast: Position.
				self storeEntry: (TableEntry make: key with: rcvr receiveHeaper)]]!

{void SEND.HOOK} sendHashTable: xmtr {Xmtr}
	"This currently doesn't take advantage of the optimizations in TableEntries.  It should."
	
	(myCoordinateSpace isEqual: IntegerSpace make)
		ifTrue:
			[self stepper forIndices: [:index {IntegerVar} :value {Heaper} |
				xmtr sendIntegerVar: index.
				xmtr sendHeaper: value]]
		ifFalse:
			[self stepper forPositions: [:p {Position} :v {Heaper} |
				xmtr sendHeaper: p.
				xmtr sendHeaper: v]]! !

!ActualHashTable methodsFor: 'protected:'!

create: entries {SharedPtrArray of: TableEntry} with: tally {Int32} with: cs {CoordinateSpace} 
	super create.
	myHashEntries _ entries.
	myTally _ tally.
	myCoordinateSpace _ cs.
	myHashEntries shareMore!

{void} destruct
	myHashEntries shareLess.
	super destruct! !

!ActualHashTable methodsFor: 'private:'!

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
	myTally > (myHashEntries count * 2)
		ifTrue: 
			[oldSize _ myHashEntries count.
			newSize _ LPPrimeSizeProvider make uInt32PrimeAfter: (oldSize * 4).
			myHashEntries shareLess.
			oldEntries _ myHashEntries.
			myHashEntries _ SharedPtrArray make: newSize.
			myHashEntries shareMore.
			Int32Zero almostTo: oldSize do: [:j {Int32} |
				| cur {TableEntry} next {TableEntry} |
				cur _ (oldEntries fetch: j) cast: TableEntry.
				[cur ~~ NULL] whileTrue: 
					[next _ cur fetchNext.
					self storeEntry: cur.
					cur _ next]].
			oldEntries destroy]!

{void} storeEntry: anEntry {TableEntry}
	"Store the tableentry into the entry table"
	| index {UInt32} |
	index _ anEntry position hashForEqual \\ myHashEntries count.
	anEntry setNext: ((myHashEntries fetch: index) cast: TableEntry).
	myHashEntries at: index store: anEntry! !

!ActualHashTable methodsFor: 'smalltalk: private:'!

{void} inspect
	^InspectorView open: (HashTableInspector inspect: self)! !

!ActualHashTable methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myTally _ receiver receiveInt32.
	myCoordinateSpace _ receiver receiveHeaper.
	self receiveHashTable: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: myTally.
	xmtr sendHeaper: myCoordinateSpace.
	self sendHashTable: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualHashTable class
	instanceVariableNames: ''!

(ActualHashTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class HashTable */
friend SPTR(HashTable)  actualHashTable (APTR(CoordinateSpace) cs);
friend SPTR(HashTable)  actualHashTable (APTR(CoordinateSpace) cs, IntegerVar size);
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!ActualHashTable class methodsFor: 'creation'!

{HashTable} make: cs {CoordinateSpace}
	^self create: (SharedPtrArray make: 7) with: Int32Zero with: cs!

{HashTable} make: cs {CoordinateSpace} with: size {IntegerVar}
	^self create: (SharedPtrArray make: (LPPrimeSizeProvider make uInt32PrimeAfter: (size DOTasLong))) with: Int32Zero with: cs! !