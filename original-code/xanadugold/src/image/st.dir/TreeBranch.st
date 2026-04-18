'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:45 pm'!

BranchDescription subclass: #TreeBranch
	instanceVariableNames: 'parent {TracePosition}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Traces'!

(TreeBranch getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!TreeBranch methodsFor: 'caching'!

{void} cacheRecur: navCache {PrimIndexTable}
	parent cacheIn: navCache! !

!TreeBranch methodsFor: 'create'!

create: ft {DagWood} with: p {TracePosition}
	super create: ft.
	parent _ p.
	self newShepherd.
	self remember! !

!TreeBranch methodsFor: 'testing'!

{UInt32} contentsHash

	^super contentsHash
		bitXor: parent hashForEqual! !

!TreeBranch methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	parent _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: parent.! !