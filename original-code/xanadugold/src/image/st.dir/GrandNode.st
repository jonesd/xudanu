'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:30 pm'!

Abraham subclass: #GrandNode
	instanceVariableNames: '
		primaryPages {PtrArray of: GrandDataPage}
		numPrimaries {Int32}
		overflowRoot {GrandOverflow}
		oldOverflowRoot {GrandOverflow}
		numReinserters {Int32}'
	classVariableNames: 'OverflowPageSize {Int32} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!
GrandNode comment:
'oldOverflowRoot holds onto the overflow tree that was in place when a node doubling starts.
It allows an object stored to be found at any time during the doubling.'!

(GrandNode getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandNode */
friend class GrandNodeStepper;
friend class GrandNodeDoubler;
friend class GrandNodeReinserter;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandNode methodsFor: 'accessing'!

{Heaper} fetch: toMatch {Heaper | Position} with: aHash {UInt32}
	| result {Heaper} |
	result _ ((primaryPages fetch: aHash \\ numPrimaries) cast: GrandDataPage)
		fetch: toMatch with: aHash with: numPrimaries.
	result ~~ NULL ifTrue:
		[ ^ result ].
	oldOverflowRoot ~~ NULL ifTrue:
		[^oldOverflowRoot fetch: toMatch with: aHash].
	^ NULL!

{void} store.Entry: newEntry {GrandEntry}
	((primaryPages fetch: newEntry hashForEqual \\ numPrimaries) cast: GrandDataPage)
		store.Entry: newEntry with: numPrimaries!

{void} wipe: toMatch {Heaper | Position} with: aHash {UInt32} 
	((primaryPages fetch: aHash \\ numPrimaries) cast: GrandDataPage)
		wipe: toMatch with: aHash with: numPrimaries.
	oldOverflowRoot ~~ NULL ifTrue:
		[oldOverflowRoot wipe: toMatch with: aHash]! !

!GrandNode methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << 'GrandNode(numPages=' << numPrimaries << ')'! !

!GrandNode methodsFor: 'protected: creation'!

create
	| aPage {GrandDataPage} |
	super create.
	overflowRoot _ NULL.
	oldOverflowRoot _ NULL.
	numReinserters _ Int32Zero.
	numPrimaries _ 1.
	primaryPages _ PtrArray nulls: 1.
	aPage _ GrandDataPage make: GrandNode primaryPageSize with: self with: UInt32Zero.
	primaryPages at: Int32Zero store: aPage.
	self newShepherd.
	self remember!

{void} dismantle
	DiskManager consistent: 2 + numPrimaries with:
		[| page {Heaper} |
		primaryPages ~~ NULL ifTrue:
			[Int32Zero almostTo: numPrimaries do: [:i {Int32} |
				page _ (primaryPages fetch: i).
				page ~~ NULL ifTrue:
				[page destroy]].
			primaryPages destroy].
		overflowRoot ~~ NULL 
			ifTrue: [overflowRoot destroy].
		oldOverflowRoot ~~ NULL
			ifTrue: [oldOverflowRoot destroy].
		super dismantle]! !

!GrandNode methodsFor: 'node doubling'!

{void} addReinserter
	DiskManager consistent: 1 with:
		[numReinserters _ numReinserters + 1.
		self diskUpdate]!

{void} doubleNode
	| newPage {GrandDataPage} newNumPrimaries {Int32} newPrimaries {PtrArray of: GrandDataPage} |
	
	DiskManager consistent: self doubleNodeConsistency with: 
		[newNumPrimaries _ numPrimaries * 2.
		newPrimaries _ PtrArray nulls: newNumPrimaries.

		Int32Zero almostTo: numPrimaries do:
			[:i {Int32} | 
			newPage _ ((primaryPages fetch: i) cast: GrandDataPage) makeDouble: newNumPrimaries.
			newPrimaries at: i store: (primaryPages fetch: i).
			newPrimaries at: newPage lowHashBits store: newPage].

		primaryPages destroy.
		primaryPages _ newPrimaries.
		numPrimaries _ newNumPrimaries.
		"At this point, the structure is consistent, but still doesn't have the full benefit of the node
		doubling.  Inserts will be faster now, but reinsertion of the overflow data is required for fetch
		to improve."
		overflowRoot ~~ NULL ifTrue:
			[oldOverflowRoot ~~ NULL ifTrue:
				[Heaper BLAST: #FallenBehindInNodeDoubling].
			oldOverflowRoot _ overflowRoot.
			overflowRoot _ NULL.
			(GrandNodeReinserter make: self with: oldOverflowRoot) schedule].
		self diskUpdate].!

{IntegerVar} doubleNodeConsistency
	Eric knownBug. "Sometimes this is off by one in either direction"
	^ 2 * numPrimaries + 2!

{void} removeReinserter
	DiskManager consistent: 1 with:
		[numReinserters _ numReinserters - 1.
		numReinserters == Int32Zero ifTrue:
			[oldOverflowRoot destroy.
			oldOverflowRoot _ NULL].
		self diskUpdate]! !

!GrandNode methodsFor: 'private: friendly access'!

{GrandDataPage} pageAt: idx {IntegerVar}
	^ (primaryPages fetch: idx DOTasLong) cast: GrandDataPage!

{IntegerVar} pageCount
	^ numPrimaries! !

!GrandNode methodsFor: 'testing'!

{UInt32} contentsHash
	| result {UInt32} |
	
	result _ ((super contentsHash
		bitXor: primaryPages contentsHash)
		bitXor: (IntegerPos integerHash: numPrimaries)).
	
	overflowRoot ~~ NULL ifTrue:
		[result _ result bitXor: overflowRoot hashForEqual].
		
	oldOverflowRoot ~~ NULL ifTrue:
		[result _ result bitXor: oldOverflowRoot hashForEqual].
		
	^ result!

{BooleanVar} isEmpty
	UInt32Zero almostTo: numPrimaries do: [ :i {UInt32} |
		((primaryPages fetch: i) cast: GrandDataPage) isEmpty ifFalse: [ ^ false ]].
	^ overflowRoot == NULL and: [oldOverflowRoot == NULL]! !

!GrandNode methodsFor: 'smalltalk: inspection'!

inspect
	EntView make: self!

inspectPieces
	| result |
	result _ primaryPages asOrderedCollection.
	overflowRoot ~~ NULL ifTrue:
		[result add: overflowRoot].
	oldOverflowRoot ~~ NULL ifTrue:
		[result add: oldOverflowRoot].
	^result! !

!GrandNode methodsFor: 'overflow'!

{GrandOverflow} fetchOldOverflow
	^ oldOverflowRoot!

{GrandOverflow} fetchOverflow
	
	^overflowRoot!

{GrandOverflow} getOverflow
	
	overflowRoot == NULL
		ifTrue: 
			[DiskManager consistent: 2 with:
				[overflowRoot _ GrandOverflow create: OverflowPageSize with: 1.
				self diskUpdate]].
	^overflowRoot! !

!GrandNode methodsFor: 'special'!

{IEEEDoubleVar} loadFactor
	| loadSum {IEEEDoubleVar} |
	loadSum _ 0.0.
	Int32Zero almostTo: numPrimaries do: [ :i {Int32} |
		loadSum _ loadSum + (((primaryPages fetch: i) cast: GrandDataPage) loadFactor)].
	^ loadSum / numPrimaries! !

!GrandNode methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	primaryPages _ receiver receiveHeaper.
	numPrimaries _ receiver receiveInt32.
	overflowRoot _ receiver receiveHeaper.
	oldOverflowRoot _ receiver receiveHeaper.
	numReinserters _ receiver receiveInt32.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: primaryPages.
	xmtr sendInt32: numPrimaries.
	xmtr sendHeaper: overflowRoot.
	xmtr sendHeaper: oldOverflowRoot.
	xmtr sendInt32: numReinserters.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandNode class
	instanceVariableNames: ''!

(GrandNode getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandNode */
friend class GrandNodeStepper;
friend class GrandNodeDoubler;
friend class GrandNodeReinserter;
';
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!GrandNode class methodsFor: 'smalltalk: smalltalk initialization'!

linkTimeNonInherited
	OverflowPageSize _ 8! !

!GrandNode class methodsFor: 'create'!

make
	^ self create! !

!GrandNode class methodsFor: 'static functions'!

{Int32 INLINE} primaryPageSize
	^ 128! !