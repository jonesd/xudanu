'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:43 pm'!

Abraham subclass: #BranchDescription
	instanceVariableNames: '
		lastPosition {UInt32}
		myLeft {BranchDescription}
		myRight {BranchDescription}
		fulltrace {DagWood}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Traces'!
BranchDescription comment:
'Instances of subclasses describe the different kinds of paths in a traceDag.  The 
three kinds are root (no parent), tree (one parent) and dag (two parent) branches.  
The dag caching routine chases up the dag finding the max of all paths.  The special 
case of chasing up the hierarchy is probably not worth the code.

At the moment, these never go away!!!!!!'!

(BranchDescription getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!BranchDescription methodsFor: 'testing'!

{UInt32} contentsHash

	^((super contentsHash
		bitXor: myLeft hashForEqual)
		bitXor: myRight hashForEqual)
		bitXor: fulltrace hashForEqual!

{BooleanVar} does: position {UInt32} include: tracePos {TracePosition} 
	| mark {IntegerVar} |
	[PrimIndexTable] USES.
	mark _ (fulltrace cacheTracePos: tracePos) fetch: self.
	^mark ~~ NULL and: [(Integer IntegerVar: position) <= mark]! !

!BranchDescription methodsFor: 'deferred accessing'!

{void} cacheRecur: navCache {PrimIndexTable}
	"recur toward the root filling in the cache."

	self subclassResponsibility! !

!BranchDescription methodsFor: 'accessing'!

{void} addSuccessorsTo: set {MuSet} 
	"Add the first useable positions for all successor branches to the set."

	set store: (TracePosition make: self with: 3).
	myLeft ~~ NULL ifTrue: [myLeft addSuccessorsTo: set].
	myRight ~~ NULL ifTrue: [myRight addSuccessorsTo: set]!

{ImmuSet} successorsOf: trace {BoundedTrace}
	| set {MuSet} |
	set _ fulltrace successorsOf: trace.
	trace position ~~ lastPosition ifTrue: [set store: (TracePosition make: self with: trace position + 1)].
	^set asImmuSet! !

!BranchDescription methodsFor: 'position making'!

{TracePosition} createAfter: trace {BoundedTrace}
	"Return a new successor to the receiver. The first successor is on the 
	same branch with a higher position. Further successors are allocated 
	in a binary-tree fashion along a new branch."

	lastPosition == trace position
		ifTrue: [^self nextPosition]
		ifFalse: 
			[| branch {BranchDescription} |
			branch _ BranchDescription make: fulltrace with: trace.
			fulltrace installBranch: branch after: trace.
			^branch nextPosition]!

{void} installBranch: branch {BranchDescription} 
	"Install branch as a descendant branch of myself. Walk down the binary tree of 
	branches to find a place to lodge it. This gets called if there was already a 
	branch existing off my root."
	(branch isEqual: self) ifTrue: [^VOID].
	self diskUpdate.
	myLeft == NULL
		ifTrue: [myLeft _ branch]
		ifFalse: 
			[| tmpBr {BranchDescription} |
			myLeft installBranch: branch.
			tmpBr _ myLeft.
			myLeft _ myRight.
			myRight _ tmpBr]!

{void} installBranch: branch {BranchDescription} after: trace {TracePosition}
	fulltrace installBranch: branch after: trace!

{BranchDescription} makeBranch: trace1 {TracePosition} with: trace2 {TracePosition}
	"Create a dag branch that succeeds both trace1 and trace2."

	^BranchDescription make: fulltrace with: trace1 with: trace2!

{TracePosition} nextPosition
	"Return the first available tracePosition on this branch."

	lastPosition _ lastPosition + 1.
	self diskUpdate.
	^TracePosition make: self with: lastPosition! !

!BranchDescription methodsFor: 'protected: protected create'!

create: ft {DagWood}
	super create.
	fulltrace _ ft.
	myLeft _ NULL.
	myRight _ NULL.
	lastPosition _ 2! !

!BranchDescription methodsFor: 'printing'!

{void} printOn: aStream {ostream reference}
	aStream << self hashForEqual! !

!BranchDescription methodsFor: 'smalltalk: smalltalk passe'!

{Boolean} = another {BranchDescription}
	self passe!

{UInt32} ohashForEqual
	"See the comment for isEqual:."
	
	"^myBranchNum * 945737"!

{BooleanVar} oisEqual: another {Heaper}
	"^(another isKindOf: BranchDescription) and: [(another basicCast: BranchDescription) branchNum == myBranchNum]"! !

!BranchDescription methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	lastPosition _ receiver receiveUInt32.
	myLeft _ receiver receiveHeaper.
	myRight _ receiver receiveHeaper.
	fulltrace _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendUInt32: lastPosition.
	xmtr sendHeaper: myLeft.
	xmtr sendHeaper: myRight.
	xmtr sendHeaper: fulltrace.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BranchDescription class
	instanceVariableNames: ''!

(BranchDescription getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #DEFERRED.LOCKED; yourself)!

!BranchDescription class methodsFor: 'instance creation'!

make: fulltrace {DagWood}
	^RootBranch create: fulltrace!

make: fulltrace {DagWood} with: parent {TracePosition}
	^TreeBranch create: fulltrace with: parent!

{BranchDescription} make: fulltrace {DagWood} with: parent1 {TracePosition} with: parent2 {TracePosition}
	^DagBranch create: fulltrace with: parent1 with: parent2! !