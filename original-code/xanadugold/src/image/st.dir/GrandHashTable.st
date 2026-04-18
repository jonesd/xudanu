'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:28 pm'!

MuTable subclass: #GrandHashTable
	instanceVariableNames: '
		grandNodes {PtrArray of: GrandNode}
		numNodes {Int32}
		nodeIndexShift {Int32}
		myTally {Counter}
		myDoublingFrontIndex {Counter}
		myDoublingPasses {Counter}
		myCs {CoordinateSpace}
		cacheHash {UInt32 NOCOPY}
		cacheKey {Position NOCOPY wimpy}
		cacheValue {Heaper NOCOPY wimpy}
		myOutstandingSteppers {IntegerVar NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!

(GrandHashTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandHashTable */
friend SPTR(GrandHashTable) grandHashTable (CoordinateSpace *);
friend SPTR(GrandHashTable) grandHashTable (CoordinateSpace *, Int4 nNodes);
friend class GrandHashTableStepper;';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!GrandHashTable methodsFor: 'adding-removing'!

{Heaper} at: aKey {Position} store: aHeaper {Heaper} 
	| hash {UInt32} node {GrandNode} newEntry {GrandEntry} old {Heaper} |
	self checkSteppers.
	aHeaper == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	hash _ ExponentialHashMap exponentialMap: aKey hashForEqual.
	node _ (grandNodes fetch: hash // nodeIndexShift) cast: GrandNode.
	old _ node fetch: aKey with: hash.
	DiskManager consistent: 1 with: [newEntry _ GrandTableEntry make: aHeaper with: aKey with: hash].
	node store.Entry: newEntry.
	old == NULL ifTrue: 
		[myTally increment.
		self considerNeedForDoubling].
	self invalidateCache.
	^ old!

{BooleanVar} wipe: aKey {Position} 
	| hash {UInt32} node {GrandNode} |
	self checkSteppers.
	hash _ ExponentialHashMap exponentialMap: aKey hashForEqual.
	node _ (grandNodes fetch: hash // nodeIndexShift) cast: GrandNode.
	(node fetch: aKey with: hash) ~~ NULL
		ifTrue: 
			[node wipe: aKey with: hash.
			myTally decrement.
			^ true].
	^ false! !

!GrandHashTable methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^ myCs!

{IntegerVar} count

	^myTally count!

{XnRegion} domain
	| result {XnRegion} stepper {TableStepper} |
	
	result _ self coordinateSpace emptyRegion.
	(stepper _ self stepper cast: TableStepper) forEach:
		[ :elem {Heaper} |
		result _ result with: (stepper position)].
	^ result!

{Heaper} fetch: key {Position} 

	| hash {UInt32} result {Heaper} |
	hash _ ExponentialHashMap exponentialMap: key hashForEqual.

	"(cacheKey ~~ NULL 
	  and: [cacheHash == hash 
	  and: [cacheKey isEqual: key]]) 
	  	ifTrue: [ ^ cacheValue ]. "
	  	
	result _ ((grandNodes fetch: hash // nodeIndexShift) cast: GrandNode) 
				fetch: key 
				with: hash.
	"result ~~ NULL ifTrue:
		[cacheHash _ hash.
		 cacheKey _ key.
		 cacheValue _ result]."
	^ result!

{ScruTable} subTable: region {XnRegion}

	| newTable {GrandHashTable} elements {TableStepper} |
	newTable _ GrandHashTable make.CoordinateSpace: myCs with: 8.
	elements _ self stepper.
	elements forEach:
		[:elemValue {Heaper} | (region hasMember: elements position) ifTrue:
			[newTable at: elements position store: elemValue]].
	^newTable! !

!GrandHashTable methodsFor: 'testing'!

{BooleanVar} includesIntKey: aKey {IntegerVar}

	^super includesIntKey: aKey!

{BooleanVar} includesKey: aKey {Position}

	^ (self fetch: aKey) ~~ NULL!

{BooleanVar} isEmpty

	^myTally count == IntegerVar0! !

!GrandHashTable methodsFor: 'creation'!

{ScruTable} copy

	| newTable {GrandHashTable} s {TableStepper} |
	newTable _ GrandHashTable make: myCs with: numNodes.
	(s _ self stepper) forEach:
		[:e {Heaper} |
		newTable at: (s position) store: e].
	^ newTable!

{ScruTable} emptySize: size {IntegerVar unused}

	^ GrandHashTable make: myCs! !

!GrandHashTable methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << 'GrandHashTable(' << self count << ' entries over ' << numNodes << ' nodes)'! !

!GrandHashTable methodsFor: 'runs'!

{XnRegion} runAt: index {Position}

	(self includesKey: index)
		ifTrue: [^ index asRegion]
		ifFalse: [^ myCs emptyRegion]!

{XnRegion} runAtInt: index {IntegerVar}
	
	^super runAtInt: index! !

!GrandHashTable methodsFor: 'private: enumerating'!

{void INLINE} checkSteppers
	myOutstandingSteppers > IntegerVar0 ifTrue:
		[ Heaper BLAST: #ModifyBlockedByOutstandingStepper ]!

{void} fewerSteppers
	myOutstandingSteppers _ myOutstandingSteppers - 1.
	myOutstandingSteppers < IntegerVar0 ifTrue:
		[ Heaper BLAST: #TooManySteppersReleased ]!

{void} moreSteppers
	myOutstandingSteppers _ myOutstandingSteppers + 1! !

!GrandHashTable methodsFor: 'enumerating'!

{TableStepper} stepper: order {OrderSpec unused default: NULL}
	^ GrandHashTableStepper create: self! !

!GrandHashTable methodsFor: 'protected: creation'!

create: cs {CoordinateSpace} with: nNodes {Int32}
	| aNode {GrandNode} |
	super create.
	myCs _ cs.
	numNodes _ nNodes.
	nodeIndexShift _ ExponentialHashMap hashBits // numNodes.
	grandNodes _ PtrArray nulls: numNodes.
	DiskManager consistent: 2 * numNodes + 3 with:
		[Int32Zero almostTo: numNodes do: [:i {Int32} | 
			aNode _ GrandNode make.
			grandNodes at: i store: aNode].
		myTally _ Counter make.
		myDoublingFrontIndex _ Counter make.
		myDoublingPasses _ Counter make].
	myOutstandingSteppers _ IntegerVarZero.
	self invalidateCache!

{void} destruct
 	| temp {Heaper} |
 	DiskManager consistent: numNodes with:
		[UInt32Zero almostTo: numNodes do:
			[:i {UInt32} |
			(temp _ grandNodes fetch: i) ~~ NULL ifTrue: [temp destroy]]].
	super destruct! !

!GrandHashTable methodsFor: 'private: housekeeping'!

{void} considerNeedForDoubling
	"Compute location of doubling front from tally.  If front crosses a node boundary"
	" and that node has index higher than doublingFrontIndex then double that node."
	" Then increase doublingFrontIndex.  If the front has hit the end of the table index"
	" reset it to zero.  This allows elements to be wiped from the table without causing"
	" extra node doubling to occur on later insertions.  This aims for 80% max table"
	"loading using an approximation of the formula given in the Fagin paper."
	| desiredDoublingIndex {Int32} x {IEEEDoubleVar} dfi {Int32} |
	x _ 0.05"Magic number" * numNodes * (1 bitShift: myDoublingPasses count DOTasLong) * GrandNode primaryPageSize.
	desiredDoublingIndex _ (myTally count DOTasLong asFloat / x) asInteger "- 1".
	dfi _ myDoublingFrontIndex count DOTasLong.
	desiredDoublingIndex >= (dfi + 1) ifTrue:
		[(grandNodes fetch: dfi) ~~ NULL ifTrue: [(GrandNodeDoubler make: ((grandNodes fetch: dfi) cast: GrandNode)) schedule].
		dfi _ myDoublingFrontIndex increment DOTasLong].
	dfi >= numNodes ifTrue:
		[myDoublingFrontIndex setCount: IntegerVar0.
		myDoublingPasses increment]!

{void} invalidateCache
	cacheKey _ NULL.! !

!GrandHashTable methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartGrandHashTable: trans {Rcvr unused default: NULL}
	"re-initialize the non-persistent part"
	cacheKey _ NULL.
	myOutstandingSteppers _ IntegerVar0! !

!GrandHashTable methodsFor: 'private: friendly'!

{GrandNode} nodeAt: idx {IntegerVar}
	^ (grandNodes fetch: idx DOTasLong) cast: GrandNode!

{IntegerVar} nodeCount
	^ numNodes! !

!GrandHashTable methodsFor: 'private: smalltalk: private'!

{void} inspect
	(Sensor ctrlDown) ifTrue:
		[^EntView make: self].
	 ^InspectorView open: (HashTableInspector inspect: self)!

inspectPieces
	^grandNodes asOrderedCollection! !

!GrandHashTable methodsFor: 'conversion'!

{ImmuTable}  asImmuTable
	self willNotImplement.
	^ NULL!

{MuTable}  asMuTable
	self willNotImplement.
	^ NULL! !

!GrandHashTable methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	grandNodes _ receiver receiveHeaper.
	numNodes _ receiver receiveInt32.
	nodeIndexShift _ receiver receiveInt32.
	myTally _ receiver receiveHeaper.
	myDoublingFrontIndex _ receiver receiveHeaper.
	myDoublingPasses _ receiver receiveHeaper.
	myCs _ receiver receiveHeaper.
	self restartGrandHashTable: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: grandNodes.
	xmtr sendInt32: numNodes.
	xmtr sendInt32: nodeIndexShift.
	xmtr sendHeaper: myTally.
	xmtr sendHeaper: myDoublingFrontIndex.
	xmtr sendHeaper: myDoublingPasses.
	xmtr sendHeaper: myCs.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandHashTable class
	instanceVariableNames: ''!

(GrandHashTable getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandHashTable */
friend SPTR(GrandHashTable) grandHashTable (CoordinateSpace *);
friend SPTR(GrandHashTable) grandHashTable (CoordinateSpace *, Int4 nNodes);
friend class GrandHashTableStepper;';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!GrandHashTable class methodsFor: 'pseudoConstructors'!

{GrandHashTable} make: cs {CoordinateSpace}
	^ GrandHashTable create: cs with: 32 "A Very big table"!

{GrandHashTable} make: cs {CoordinateSpace} with: nNodes {Int32}
	^ GrandHashTable create: cs with: nNodes! !

!GrandHashTable class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	"GrandHashTable initTimeNonInherited"
	
	self REQUIRES: ExponentialHashMap! !