'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:27 pm'!

MuSet subclass: #GrandHashSet
	instanceVariableNames: '
		grandNodes {PtrArray copy of: GrandNode}
		numNodes {Int32 copy}
		nodeIndexShift {Int32 copy}
		myTally {Counter copy}
		myDoublingFrontIndex {Counter copy}
		myDoublingPasses {Counter copy}
		cacheHash {UInt32 NOCOPY}
		cacheValue {Heaper wimpy NOCOPY}
		myOutstandingSteppers {IntegerVar NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!

(GrandHashSet getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandHashSet */
friend SPTR(GrandHashSet)  grandHashSet ();
friend SPTR(GrandHashSet)  grandHashSet (Int4 nNodes);
friend class GrandHashSetStepper;
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!GrandHashSet methodsFor: 'adding-removing'!

{void} introduce: aHeaper {Heaper}

	| hash {UInt32} node {GrandNode} |
	self checkSteppers.
	aHeaper == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	hash _ ExponentialHashMap exponentialMap: aHeaper hashForEqual.
	node _ (grandNodes fetch: hash // nodeIndexShift) cast: GrandNode.
	(node fetch: aHeaper with: hash) ~~ NULL
		ifTrue: [Heaper BLAST: #AlreadyInSet]
		ifFalse: [| newEntry {GrandEntry} |
				DiskManager consistent: 6 with:
					[newEntry _ GrandSetEntry make: aHeaper with: hash.
					node store.Entry: newEntry]].
	myTally increment.
	self considerNeedForDoubling.
	self invalidateCache.!

{void} remove: aHeaper {Heaper} 

	((self hasMember: aHeaper) == NULL) 
		ifTrue: [Heaper BLAST: #NotInSet]
		ifFalse: [self wipe: aHeaper]!

{void} store: aHeaper {Heaper} 
	| hash {UInt32} node {GrandNode} newEntry {GrandEntry} test {BooleanVar} |
	self checkSteppers.
	aHeaper == NULL ifTrue: [Heaper BLAST: #NullInsertion].
	hash _ ExponentialHashMap exponentialMap: aHeaper hashForEqual.
	node _ (grandNodes fetch: hash // nodeIndexShift) cast: GrandNode.
	test _ (node fetch: aHeaper with: hash) == NULL.
	DiskManager consistent: 6 with:
		[newEntry _ GrandSetEntry make: aHeaper with: hash.
		node store.Entry: newEntry].
	test ifTrue: 
		[myTally increment.
		self considerNeedForDoubling].
	self invalidateCache.!

{void} wipe: aHeaper {Heaper} 
	| hash {UInt32} node {GrandNode} |
	self checkSteppers.
	hash _ ExponentialHashMap exponentialMap: aHeaper hashForEqual.
	node _ (grandNodes fetch: hash // nodeIndexShift) cast: GrandNode.
	(node fetch: aHeaper with: hash) ~~ NULL
		ifTrue: 
			[node wipe: aHeaper with: hash.
			myTally decrement]! !

!GrandHashSet methodsFor: 'accessing'!

{IntegerVar} count

	^myTally count!

{BooleanVar} hasMember: aHeaper {Heaper} 
	| hash {UInt32} result {Heaper} |
	hash _ ExponentialHashMap exponentialMap: aHeaper hashForEqual.
	"(cacheKey ~~ NULL and: [cacheHash == hash and: [cacheKey isEqual: key]]) ifTrue: [ ^ cacheValue ]."
	result _ ((grandNodes fetch: hash // nodeIndexShift) cast: GrandNode) fetch: aHeaper with: hash.
	"result ~~ NULL ifTrue:
		[cacheHash _ hash.
		 cacheKey _ key.
		 cacheValue _ result]."
	^ result ~~ NULL! !

!GrandHashSet methodsFor: 'testing'!

{BooleanVar} isEmpty

	^myTally count == IntegerVar0! !

!GrandHashSet methodsFor: 'conversion'!

{ImmuSet} asImmuSet
	self willNotImplement.
	^ NULL!

{MuSet} asMuSet
	self willNotImplement.
	^ NULL! !

!GrandHashSet methodsFor: 'creation'!

{ScruSet} copy
	| newSet {MuSet} |
	newSet _ GrandHashSet make: numNodes.
	self stepper forEach:
		[:e {Heaper} |
		newSet store: e].
	^ newSet! !

!GrandHashSet methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << 'GrandHashSet(' << self count << ' entries over ' << numNodes << ' nodes)'!

{void} printOnWithSimpleSyntax: oo {ostream reference} with: open {char star} with: sep {char star} with: close {char star} 
	| stomp {Stepper} |
	oo << open.
	self isEmpty
		ifTrue: [oo << 'empty']
		ifFalse: 
			[stomp _ self stepper.
			[stomp hasValue]
				whileTrue: 
					[oo << stomp fetch.
					stomp step.
					stomp hasValue ifTrue: [oo << sep]].
			stomp destroy].
	oo << close! !

!GrandHashSet methodsFor: 'enumerating'!

{Stepper} stepper
	^ GrandHashSetStepper create: self! !

!GrandHashSet methodsFor: 'protected: creation'!

create: nNodes {Int32}
	| aNode {GrandNode} |
	super create. 
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
 	self checkSteppers.
 	DiskManager consistent: numNodes with:
		[UInt32Zero almostTo: numNodes do:
			[:i {UInt32} |
			(temp _ grandNodes fetch: i) ~~ NULL ifTrue: [temp destroy]]].
	super destruct! !

!GrandHashSet methodsFor: 'private: housekeeping'!

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
	cacheValue _ NULL.! !

!GrandHashSet methodsFor: 'receiver'!

{void RECEIVE.HOOK} restartGrandHashSet: trans {Rcvr unused default: NULL}
	"re-initialize the non-persistent part"
	cacheValue _ NULL.
	myOutstandingSteppers _ IntegerVar0! !

!GrandHashSet methodsFor: 'private: friendly'!

{GrandNode} nodeAt: idx {IntegerVar}
	^ (grandNodes fetch: idx DOTasLong) cast: GrandNode!

{IntegerVar} nodeCount
	^ numNodes! !

!GrandHashSet methodsFor: 'private: smalltalk: private'!

inspectPieces
	^grandNodes asOrderedCollection! !

!GrandHashSet methodsFor: 'private: enumerating'!

{void INLINE} checkSteppers
	myOutstandingSteppers > IntegerVar0 ifTrue:
		[ Heaper BLAST: #ModifyBlockedByOutstandingStepper ]!

{void} fewerSteppers
	myOutstandingSteppers _ myOutstandingSteppers - 1.
	myOutstandingSteppers < IntegerVar0 ifTrue:
		[ Heaper BLAST: #TooManySteppersReleased ]!

{Stepper} immuStepper
	self hack. "This will have to be fixed if GrandHashSet::stepper ever makes a copy"
	 ^ self stepper!

{void} moreSteppers
	myOutstandingSteppers _ myOutstandingSteppers + 1! !

!GrandHashSet methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	grandNodes _ receiver receiveHeaper.
	numNodes _ receiver receiveInt32.
	nodeIndexShift _ receiver receiveInt32.
	myTally _ receiver receiveHeaper.
	myDoublingFrontIndex _ receiver receiveHeaper.
	myDoublingPasses _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: grandNodes.
	xmtr sendInt32: numNodes.
	xmtr sendInt32: nodeIndexShift.
	xmtr sendHeaper: myTally.
	xmtr sendHeaper: myDoublingFrontIndex.
	xmtr sendHeaper: myDoublingPasses.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GrandHashSet class
	instanceVariableNames: ''!

(GrandHashSet getOrMakeCxxClassDescription)
	friends:
'/* friends for class GrandHashSet */
friend SPTR(GrandHashSet)  grandHashSet ();
friend SPTR(GrandHashSet)  grandHashSet (Int4 nNodes);
friend class GrandHashSetStepper;
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!GrandHashSet class methodsFor: 'pseudoConstructors'!

make 
	^ self create: 32 "A Very big table"!

make: nNodes {Int32} 
	^ self create: nNodes! !

!GrandHashSet class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	"GrandHashTable initTimeNonInherited"
	
	self REQUIRES: ExponentialHashMap! !