'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:44 pm'!

Abraham subclass: #DagWood
	instanceVariableNames: '
		myRoot {TracePosition}
		myTrunk {MuTable of: TracePosition and: BranchDescription}
		myCachedPosition {TracePosition NOCOPY}
		myNavCache {PrimIndexTable NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Traces'!
DagWood comment:
'Each dagwood defines a partial ordering of TracePositions.  Several implementation variables use longs because they represent the size of an in-core array (which can''t get that large).  The variable ''myRoot'' is just for debugging for the moment.'!

(DagWood getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!DagWood methodsFor: 'accessing'!

{TracePosition} root
	^myRoot!

{BranchDescription} successorBranchOf: branch {BranchDescription unused} position: position {UInt32 unused}
	"Return all the successors of the receiver in the trace tree."
	self unimplemented.
	^NULL!

{MuSet} successorsOf: trace {TracePosition} 
	"Return the first used positions on all the successors of trace."

	| prevBranch {BranchDescription} set {MuSet} |
	set _ MuSet make.
	prevBranch _ (myTrunk fetch: (HeaperAsPosition make: trace)) cast: BranchDescription.
	prevBranch ~~ NULL
		ifTrue: [prevBranch addSuccessorsTo: set].
	^set! !

!DagWood methodsFor: 'branches'!

{void} installBranch: branch {BranchDescription} after: anchorTrace {TracePosition} 
	"Lookup the anchorTrace to find the branch hanging off it. If there isn't one, 
	then install branch as that branch. Otherwise walk a balanced walk down the 
	binary tree of branches to find a place to hang the new branch."

	| prevBranch {BranchDescription} pos {Position} |
	prevBranch _ (myTrunk fetch: (pos _ HeaperAsPosition make: anchorTrace)) cast: BranchDescription.
	prevBranch == NULL
		ifTrue: [myTrunk at: pos introduce: branch]
		ifFalse: [prevBranch installBranch: branch]!

{TracePosition} newPosition
	"This should really create a new root, but that's harder to draw!!."

	^myRoot newSuccessor! !

!DagWood methodsFor: 'caching'!

{PrimIndexTable} cacheTracePos: tracePos {TracePosition}
	"Install the supplied branch and position as the navCache and return it. "

	(myCachedPosition ~~ NULL 
		and: [tracePos isEqual: myCachedPosition]) 
		ifTrue: [^myNavCache].
	myCachedPosition _ tracePos.
	myNavCache clearAll.
	tracePos cacheIn: myNavCache.
	^myNavCache! !

!DagWood methodsFor: 'smalltalk: inspect'!

{void} inspect
	Sensor leftShiftDown
		ifTrue: [self basicInspect]
		ifFalse: 
			[myRoot inspect]! !

!DagWood methodsFor: 'create'!

create
	super create.
	myCachedPosition _ NULL.
	myNavCache _ PrimIndexTable make: 128.
	myTrunk _ GrandHashTable make: HeaperSpace make.
	myRoot _ TracePosition make: (BranchDescription make: self) with: 1.
	"Ensure that no elements get allocated on the root branch."
	myRoot newSuccessor.
	self newShepherd.
	self remember! !

!DagWood methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartDagWood: trans {Rcvr unused default: NULL}
	"re-initialize the non-persistent part"
	myCachedPosition _ NULL.
	myNavCache _ PrimIndexTable make: 128.! !

!DagWood methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: myRoot hashForEqual! !

!DagWood methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myRoot _ receiver receiveHeaper.
	myTrunk _ receiver receiveHeaper.
	self restartDagWood: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myRoot.
	xmtr sendHeaper: myTrunk.! !