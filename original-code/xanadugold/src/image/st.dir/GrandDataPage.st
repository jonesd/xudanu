'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:26 pm'!

Abraham subclass: #GrandDataPage
	instanceVariableNames: '
		myLowHashBits {UInt32}
		numEntries {Int32}
		entries {PtrArray of: GrandEntry}
		overflow {GrandOverflow}
		myGroup {GrandNode}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!
GrandDataPage comment:
'GrandDataPage behaves as a small hash table.
Linear hashing and the GrandOverflow structure are used to resolve collisions.
The shift argument to the various methods is the number of pages in the
parent node to indicate how many low bits of the hash are ignored.'!

(GrandDataPage getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandDataPage */
friend class GrandDataPageStepper;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandDataPage methodsFor: 'accessing'!

{Heaper} fetch: toMatch {Heaper | Position} with: aHash {UInt32} with: shift {Int32}
	| localIndex {Int32} originalIndex {Int32} entry {GrandEntry} |
	localIndex _ originalIndex _ aHash // shift \\ numEntries.
	entry _ (entries fetch: localIndex) cast: GrandEntry.
	[entry ~~ NULL] whileTrue:
		[(aHash == entry hashForEqual) ifTrue: [(entry compare: toMatch) ifTrue: [^entry value]].
		localIndex _ localIndex + 1 \\ numEntries.
		entry _ (entries fetch: localIndex) cast: GrandEntry.
		localIndex == originalIndex ifTrue: [ entry _ NULL "break" ]].
	overflow ~~ NULL ifTrue: [ ^ overflow fetch: toMatch with: aHash].
	^NULL!

{void} store.Entry: newEntry {GrandEntry} with: shift {Int32} 
	
	| localIndex {UInt32} originalIndex {UInt32} entry {GrandEntry wimpy} |
	localIndex _ originalIndex _ newEntry hashForEqual // shift \\ numEntries.
	entry _ (entries fetch: localIndex) cast: GrandEntry.
	
	[entry ~~ NULL] whileTrue:
		[newEntry hashForEqual == entry hashForEqual ifTrue:
			[(newEntry matches: entry) ifTrue:
				["Note that this does not delete the contents"
				DiskManager consistent: 1 with:
					[entry destroy.
					entries at: localIndex store: newEntry.
					self diskUpdate].
				^VOID]].

		localIndex _ localIndex + 1 \\ numEntries.
		localIndex == originalIndex ifTrue:
			["This page is now full"
			overflow == NULL
				ifTrue:
					[DiskManager consistent: 4 with:
						[overflow _ myGroup getOverflow store.Entry: newEntry.
						self diskUpdate]]
				ifFalse:
					[overflow store.Entry: newEntry].
				^VOID].

			entry _ (entries fetch: localIndex) cast: GrandEntry].

	"Found empty slot."
	DiskManager consistent: 1 with:
		[entries at: localIndex store: newEntry.
		self diskUpdate]!

{void} wipe: toMatch {Heaper | Position} with: aHash {UInt32} with: shift {Int32} 
	
	| localIndex {Int32} originalIndex {Int32} entry {GrandEntry wimpy} |
	localIndex _ originalIndex _ aHash // shift \\ numEntries.
	entry _ (entries fetch: localIndex) cast: GrandEntry.

	[entry ~~ NULL] whileTrue:
		[aHash == entry hashForEqual ifTrue:
			[(entry compare: toMatch) ifTrue:
				[DiskManager consistent: 2 with:
					[entry destroy.
					"Note that this does not delete the contents"
					entries at: localIndex store: NULL.
					self repack: shift.
					self diskUpdate].
				^VOID]].

		localIndex _ localIndex + 1 \\ numEntries.
		entry _ (entries fetch: localIndex) cast: GrandEntry.
		localIndex = originalIndex ifTrue:
			["break"
			entry _ NULL]].
			
	overflow ~~ NULL ifTrue:
		[overflow wipe: toMatch with: aHash]! !

!GrandDataPage methodsFor: 'protected: creation'!

create: nEntries {Int32} with: node {GrandNode} with: lowHashBits {UInt32}
	super create.
	myLowHashBits _ lowHashBits.
	numEntries _ nEntries.
	entries _ PtrArray nulls: numEntries.
	myGroup _ node.
	overflow _ NULL.
	self newShepherd.
	self remember! !

!GrandDataPage methodsFor: 'private: private'!

{void} repack: shift {Int32}
	"This repacks the entry table after a wipe to keep the table consistent with"
	"the linear hash collision resolution technique."
	| newEntries {PtrArray of: GrandEntry} entry {GrandEntry} preferedIndex {Int32} |
	newEntries _ PtrArray nulls: numEntries.
	Int32Zero almostTo: numEntries do: [ :i {Int32} |
		(entry _ (entries fetch: i) cast: GrandEntry) ~~ NULL ifTrue:
			[preferedIndex _ entry hashForEqual // shift \\ numEntries.
			(newEntries fetch: preferedIndex) ~~ NULL ifTrue:
				[[(newEntries fetch: preferedIndex) ~~ NULL] whileTrue:
					[preferedIndex _ preferedIndex + 1 \\ numEntries]].
			newEntries at: preferedIndex store: entry]].
	entries destroy.
	entries _ newEntries.! !

!GrandDataPage methodsFor: 'node doubling'!

{GrandDataPage} makeDouble: newNumPages {Int32} 
	"Create a new page with all entries of current page that have a"
	"'1' in the new lowest significant bit of the hash."
	"Retain all '0' entries in this page."
	
	| newPage {GrandDataPage} oldEntry {GrandEntry wimpy} oldNumPages {Int32} |
	DiskManager consistent: 2 with:
		[oldNumPages _ newNumPages / 2.
		newPage _ GrandDataPage make: numEntries with: myGroup with: myLowHashBits + oldNumPages.
		overflow _ NULL.
		"Reset overflow structure. Old one is held by parent node."
		Int32Zero
			almostTo: numEntries
			do: [:i {Int32} | 
				oldEntry _ (entries fetch: i) cast: GrandEntry.
				"This test is necessary since page to be doubled may not be full."
				oldEntry ~~ NULL
					ifTrue: 
						[(oldEntry hashForEqual // oldNumPages bitAnd: 1) == 1
							ifTrue: 
								[newPage store.Entry: oldEntry with: newNumPages.
								entries at: i store: NULL]]].
		"Now let pages sort themselves out."
		self repack: newNumPages.
		self diskUpdate].
	^newPage! !

!GrandDataPage methodsFor: 'special'!

{IEEEDoubleVar} loadFactor
	| loadCount {Int32} |
	loadCount _ Int32Zero.
	Int32Zero almostTo: numEntries do: [ :i {Int32} |
		(entries fetch: i) ~~ NULL ifTrue: [ loadCount _ loadCount + 1]].
	^ loadCount asFloat / numEntries asFloat!

{UInt32} lowHashBits
	^ myLowHashBits! !

!GrandDataPage methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	| count {Int32} |
	aStream << 'GrandDataPage(' << numEntries << ' slots, '.
	count _ Int32Zero.
	Int32Zero almostTo: numEntries do: [ :i {Int32} |
		(entries fetch: i) ~~ NULL ifTrue: [ count _ count + 1 ]].
	aStream << count << ' full'.
	overflow ~~ NULL ifTrue: [ aStream << ' and overflow'].
	aStream << ')'! !

!GrandDataPage methodsFor: 'protected: destruction'!

{void} dismantle
	DiskManager consistent: 1 + numEntries with:
		[| entry {Heaper} |
		entries ~~ NULL ifTrue:
			[Int32Zero almostTo: numEntries do: [ :i {Int32} |
				entry _ entries fetch: i.
				entry ~~ NULL ifTrue:
					[entry destroy.
					entries at: i store: NULL]].
			entries destroy.
			entries _ NULL].
		super dismantle]! !

!GrandDataPage methodsFor: 'testing'!

{UInt32} contentsHash

	^((((super contentsHash
		bitXor: (IntegerPos integerHash: myLowHashBits))
		bitXor: (IntegerPos integerHash: numEntries))
		bitXor: entries contentsHash)
		bitXor: overflow hashForEqual)
		bitXor: myGroup hashForEqual!

{BooleanVar} isEmpty
	UInt32Zero almostTo: numEntries do: [ :i {UInt32} |
		(entries fetch: i) ~~ NULL ifTrue: [ ^ false ]].
	^ true! !

!GrandDataPage methodsFor: 'private: friendly'!

{GrandEntry} entryAt: idx {IntegerVar}
	^(entries fetch: idx DOTasLong) cast: GrandEntry!

{IntegerVar} entryCount
	^ numEntries! !

!GrandDataPage methodsFor: 'private: smalltalk: private'!

inspectPieces
	^entries asOrderedCollection! !

!GrandDataPage methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myLowHashBits _ receiver receiveUInt32.
	numEntries _ receiver receiveInt32.
	entries _ receiver receiveHeaper.
	overflow _ receiver receiveHeaper.
	myGroup _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendUInt32: myLowHashBits.
	xmtr sendInt32: numEntries.
	xmtr sendHeaper: entries.
	xmtr sendHeaper: overflow.
	xmtr sendHeaper: myGroup.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandDataPage class
	instanceVariableNames: ''!

(GrandDataPage getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandDataPage */
friend class GrandDataPageStepper;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandDataPage class methodsFor: 'creation'!

make: nEntries {Int32} with: node {GrandNode} with: lowHashBits {UInt32}
	^ self create: nEntries with: node with: lowHashBits! !