'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:44 pm'!

BranchDescription subclass: #RootBranch
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Traces'!

(RootBranch getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SHEPHERD.ANCESTOR; add: #LOCKED; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!RootBranch methodsFor: 'caching'!

{void} cacheRecur: navCache {PrimIndexTable}
	"The recursion ends here."! !

!RootBranch methodsFor: 'create'!

create: ft {DagWood}
	super create: ft.
	self newShepherd.
	self remember! !

!RootBranch methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !