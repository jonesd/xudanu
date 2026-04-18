'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:31 pm'!

Abraham subclass: #GrandOverflow
	instanceVariableNames: '
		numEntries {Int32}
		entries {PtrArray of: GrandEntry}
		children {PtrArray of: GrandOverflow}
		depth {Int32}'
	classVariableNames: 'OTreeArity {Int32} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!
GrandOverflow comment:
'This class has a comment
The instance variable depth actually holds the value OTreeArity ^ depth.'!

(GrandOverflow getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandOverflow */
friend class GrandOverflowStepper;';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandOverflow methodsFor: 'accessing'!

{Heaper} fetch: toMatch {Heaper | Position} with: aHash {UInt32}
	| localIndex {Int32} originalIndex {Int32} entry {GrandEntry}  childIndex {UInt32} |
	localIndex _ originalIndex _ aHash // depth \\ numEntries.
	entry _ (entries fetch: localIndex) cast: GrandEntry.
	[entry ~~ NULL] whileTrue:
		[(aHash == entry hashForEqual) ifTrue: [(entry compare: toMatch) ifTrue: [^ entry value]].
		localIndex _ localIndex + 1 \\ numEntries.
		entry _ (entries fetch: localIndex) cast: GrandEntry.
		localIndex == originalIndex ifTrue:
			[entry _ NULL "break from loop"]].
	childIndex _ aHash // depth \\ OTreeArity.
	(children fetch: childIndex) ~~ NULL ifTrue:
			[^ ((children fetch: childIndex) cast: GrandOverflow) fetch: toMatch with: aHash].
	^NULL!

{GrandOverflow} store.Entry: newEntry {GrandEntry} 
	
	| localIndex {Int32} originalIndex {Int32} entry {GrandEntry wimpy} |
	localIndex _ originalIndex _ newEntry hashForEqual // depth \\ numEntries.
	entry _ (entries fetch: localIndex) cast: GrandEntry.

	[entry ~~ NULL] whileTrue:
		[newEntry hashForEqual == entry hashForEqual ifTrue:
			[(newEntry matches: entry) ifTrue:
				["Note that this does not delete the contents"
				DiskManager consistent: 2 with:
					[entry destroy.
					entries at: localIndex store: newEntry.
					self diskUpdate].
				^self]].

		localIndex _ localIndex + 1 \\ numEntries.
		localIndex == originalIndex ifTrue:
			[| newChild {GrandOverflow} childIndex {UInt32} |
			"This page is now full. Descend overflow tree further."
			childIndex _ newEntry hashForEqual // depth \\ OTreeArity.

			(children fetch: childIndex) == NULL ifTrue:
				[DiskManager consistent: 2 with:
					[newChild _ GrandOverflow create: numEntries with: depth * OTreeArity.
					children at: childIndex store: newChild.
					self diskUpdate]].

			^((children fetch: childIndex) cast: GrandOverflow) store.Entry: newEntry].

		entry _ (entries fetch: localIndex) cast: GrandEntry].

	"Found empty slot."
	DiskManager consistent: 1 with:
		[entries at: localIndex store: newEntry.
		self diskUpdate].
	^self!

{void} wipe: toMatch {Heaper | Position} with: aHash {UInt32} 
	
	| localIndex {Int32} originalIndex {Int32} childIndex {Int32} entry {GrandEntry wimpy} |
	localIndex _ originalIndex _ aHash // depth \\ numEntries.
	entry _ (entries fetch: localIndex) cast: GrandEntry.
	[entry ~~ NULL]
		whileTrue: 
			[aHash == entry hashForEqual ifTrue:
				[(entry compare: toMatch) ifTrue:
					["Note that this does not delete the contents"
					DiskManager consistent: 2 with:
						[entry destroy.
						entries at: localIndex store: NULL.
						self repack.
						self diskUpdate].
					^ VOID]].
			localIndex _ localIndex + 1 \\ numEntries.
			entry _ (entries fetch: localIndex) cast: GrandEntry.
			localIndex == originalIndex ifTrue:
				["break from loop"
				entry _ NULL]].

	childIndex _ aHash // depth \\ OTreeArity.
	(children fetch: childIndex) ~~ NULL
		ifTrue: [((children fetch: childIndex) cast: GrandOverflow) wipe: toMatch with: aHash]! !

!GrandOverflow methodsFor: 'creation'!

create: maxEntries {Int32} with: someDepth {UInt32}
	super create.
	numEntries _ maxEntries.
	entries _ PtrArray nulls: numEntries.
	children _ PtrArray nulls: OTreeArity.
	depth _ someDepth.
	self newShepherd.
	self remember! !

!GrandOverflow methodsFor: 'private:'!

{void} repack
	"This repacks the entry table after a wipe to keep the table consistent with"
	"the linear hash collision resolution technique."
	| newEntries {PtrArray of: GrandEntry} entry {GrandEntry} preferedIndex {Int32} |
	newEntries _ PtrArray nulls: numEntries.
	Int32Zero almostTo: numEntries do: [ :i {Int32} |
		(entry _ (entries fetch: i) cast: GrandEntry) ~~ NULL ifTrue:
			[preferedIndex _ entry hashForEqual // depth \\ numEntries.
			(newEntries fetch: preferedIndex) ~~ NULL ifTrue:
				[[(newEntries fetch: preferedIndex) ~~ NULL] whileTrue:
					[preferedIndex _ preferedIndex + 1 \\ numEntries]].
			newEntries at: preferedIndex store: entry]].
	entries destroy.
	entries _ newEntries! !

!GrandOverflow methodsFor: 'node doubling'!

{void} reinsertEntries: node {GrandNode}
	"Recursively insert all overflowed entries into a newly doubled node."
	| entry {GrandEntry} child {GrandOverflow} |

	DiskManager consistent: self reinsertEntriesConsistency with:
		[Int32Zero almostTo: numEntries do:
			[ :i {Int32} |
			entry _ (entries fetch: i) cast: GrandEntry.
			entry ~~ NULL ifTrue:
				[node store.Entry: entry.
				entries at: i store: NULL.
				self diskUpdate]].

		Int32Zero almostTo: OTreeArity do: [ :j {Int32} |
			child _ (children fetch: j) cast: GrandOverflow.
			child ~~ NULL ifTrue: [(GrandNodeReinserter make: node with: child) schedule]]]!

{IntegerVar} reinsertEntriesConsistency
	^ 4 * numEntries + OTreeArity + 2! !

!GrandOverflow methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << 'GrandOverflow(depth=' << depth << ')'! !

!GrandOverflow methodsFor: 'protected: creation'!

{void} dismantle
	DiskManager consistent: 1 + numEntries + OTreeArity with:
		[entries ~~ NULL ifTrue:
			[Int32Zero almostTo: numEntries do: [ :i {Int32} |
				| entry {GrandEntry} |
				entry _ (entries fetch: i) cast: GrandEntry.
				entry ~~ NULL ifTrue:
					[entry destroy]].
			entries destroy].
		children ~~ NULL ifTrue:
			[Int32Zero almostTo: OTreeArity do: [ :j {Int32} |
				| child {GrandOverflow} |
				child _ (children fetch: j) cast: GrandOverflow.
				child ~~ NULL ifTrue:
					[child destroy]].
			children destroy].
		super dismantle]! !

!GrandOverflow methodsFor: 'private: friendly'!

{GrandOverflow} childAt: idx {IntegerVar}
	^ (children fetch: idx DOTasLong) cast: GrandOverflow!

{IntegerVar} childCount
	^ OTreeArity!

{GrandEntry} entryAt: idx {IntegerVar}
	^ (entries fetch: idx DOTasLong) cast: GrandEntry!

{IntegerVar} entryCount
	^ numEntries! !

!GrandOverflow methodsFor: 'private: smalltalk: private'!

inspectPieces
	^(entries asOrderedCollection)
		addAll: children asOrderedCollection;
		yourself! !

!GrandOverflow methodsFor: 'testing'!

{UInt32} contentsHash

	^(((super contentsHash
		bitXor: (IntegerPos integerHash: numEntries))
		bitXor: entries contentsHash)
		bitXor: children contentsHash)
		bitXor: (IntegerPos integerHash: depth)! !

!GrandOverflow methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	numEntries _ receiver receiveInt32.
	entries _ receiver receiveHeaper.
	children _ receiver receiveHeaper.
	depth _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendInt32: numEntries.
	xmtr sendHeaper: entries.
	xmtr sendHeaper: children.
	xmtr sendInt32: depth.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandOverflow class
	instanceVariableNames: ''!

(GrandOverflow getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandOverflow */
friend class GrandOverflowStepper;';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandOverflow class methodsFor: 'smalltalk: smalltalk initialization'!

linkTimeNonInherited
	OTreeArity _ 4! !