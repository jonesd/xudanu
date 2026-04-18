'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:55 pm'!

TransitionEdge subclass: #SequenceEdge
	instanceVariableNames: 'mySequence {Sequence}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(SequenceEdge getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!SequenceEdge methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self sequence hashForEqual bitXor: self getCategory hashForEqual!

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

!SequenceEdge methodsFor: 'accessing'!

{Sequence} sequence

	^mySequence!

{SequenceEdge} transformedBy: dsp {SequenceMapping}
	"Transform the edge by the given mapping"
	
	self subclassResponsibility! !

!SequenceEdge methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '(' << mySequence << ')'!

{void} printTransitionOn: oo {ostream reference}
	with: entering {BooleanVar}
	with: touchesPrevious {BooleanVar}
	"Print a description of this transition"
	
	self subclassResponsibility! !

!SequenceEdge methodsFor: 'create'!

create: sequence {Sequence}

	super create.
	mySequence := sequence.! !

!SequenceEdge methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySequence _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySequence.! !