'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:43 pm'!

BranchDescription subclass: #DagBranch
	instanceVariableNames: '
		parent1 {TracePosition}
		parent2 {TracePosition}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Traces'!

(DagBranch getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!DagBranch methodsFor: 'caching'!

{void} cacheRecur: navCache {PrimIndexTable}
	parent1 cacheIn: navCache.
	parent2 cacheIn: navCache! !

!DagBranch methodsFor: 'create'!

create: ft {DagWood}with: p1 {TracePosition} with: p2 {TracePosition}
	super create: ft.
	parent1 _ p1.
	parent2 _ p2.
	self newShepherd.
	self remember! !

!DagBranch methodsFor: 'testing'!

{UInt32} contentsHash

	^(super contentsHash
		bitXor: parent1 hashForEqual)
		bitXor: parent2 hashForEqual! !

!DagBranch methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	parent1 _ receiver receiveHeaper.
	parent2 _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: parent1.
	xmtr sendHeaper: parent2.! !