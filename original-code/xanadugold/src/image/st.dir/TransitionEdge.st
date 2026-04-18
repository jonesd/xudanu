'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:07 pm'!

Heaper subclass: #TransitionEdge
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-EdgeRegion'!
TransitionEdge comment:
'Clients of EdgeManager define concrete subclasses of this, which are then used by the EdgeManager code'!

(TransitionEdge getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!TransitionEdge methodsFor: 'accessing'!

{TransitionEdge} ceiling: other {TransitionEdge}

	(other isGE: self)
		ifTrue: [^other]
		ifFalse: [^self]!

{TransitionEdge} floor: other {TransitionEdge}

	(self isGE: other)
		ifTrue: [^other]
		ifFalse: [^self]! !

!TransitionEdge methodsFor: 'testing'!

{UInt32} actualHashForEqual

	self subclassResponsibility!

{BooleanVar} follows: pos {Position}
	"Whether the position is strictly less than this edge"
	
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}

	self subclassResponsibility!

{BooleanVar} isFollowedBy: next {TransitionEdge}
	"Whether there is precisely one position between this edge and the next one"
	
	self subclassResponsibility!

{BooleanVar} isGE: other {TransitionEdge}
	"Defines a full ordering among all edges in a given CoordinateSpace"
	
	self subclassResponsibility!

{BooleanVar} touches: other {TransitionEdge}
	"Whether this edge touches the same position the other does"
	
	self subclassResponsibility! !

!TransitionEdge methodsFor: 'printing'!

{void} printTransitionOn: oo {ostream reference}
	with: entering {BooleanVar}
	with: touchesPrevious {BooleanVar}
	"Print a description of this transition"
	
	self subclassResponsibility! !

!TransitionEdge methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !