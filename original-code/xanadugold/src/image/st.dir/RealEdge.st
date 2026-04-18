'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:52 pm'!

TransitionEdge subclass: #RealEdge
	instanceVariableNames: 'myPos {RealPos}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(RealEdge getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!RealEdge methodsFor: 'accessing'!

{RealPos} position

	^myPos! !

!RealEdge methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^myPos hashForEqual bitXor: self getCategory hashForEqual!

{BooleanVar} follows: pos {Position}
	
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}

	self subclassResponsibility!

{BooleanVar} isFollowedBy: next {TransitionEdge}
	
	self subclassResponsibility!

{BooleanVar} isGE: other {TransitionEdge}
	
	self subclassResponsibility!

{BooleanVar} touches: other {TransitionEdge}
	
	^myPos isEqual: (other cast: RealEdge) position! !

!RealEdge methodsFor: 'printing'!

{void} printTransitionOn: oo {ostream reference}
	with: entering {BooleanVar}
	with: touchesPrevious {BooleanVar}
	
	self subclassResponsibility! !

!RealEdge methodsFor: 'creation'!

create: pos {RealPos}

	super create.
	myPos := pos.! !

!RealEdge methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myPos _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myPos.! !