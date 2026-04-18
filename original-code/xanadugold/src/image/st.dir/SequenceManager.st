'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:56 pm'!

EdgeManager subclass: #SequenceManager
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
SequenceManager comment:
'Specialized object for managing TumblerSpace objects. Is a type so that inlining could potentially be used.'!

(SequenceManager getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!SequenceManager methodsFor: 'protected:'!

{Position} edgePosition: edge {TransitionEdge}

	^(edge cast: SequenceEdge) sequence!

{XnRegion} makeNew: startsInside {BooleanVar} with: transitions {PtrArray of: TransitionEdge}

	^self makeNew: startsInside with: transitions with: transitions count!

{XnRegion} makeNew: startsInside {BooleanVar} with: transitions {PtrArray of: TransitionEdge} with: count {Int32}

	^SequenceRegion create: startsInside with: transitions with: count!

{PtrArray of: TransitionEdge} posTransitions: pos {Position}

	^ (PrimSpec pointer
		arrayWithTwo: (BeforeSequence make: (pos cast: Sequence))
		with: (AfterSequence make: (pos cast: Sequence))) cast: PtrArray!

{BooleanVar} startsInside: region {XnRegion}

	^(region cast: SequenceRegion) startsInside!

{PtrArray of: TransitionEdge} transitions: region {XnRegion}

	^(region cast: SequenceRegion) secretTransitions!

{Int32} transitionsCount: region {XnRegion}

	^(region cast: SequenceRegion) secretTransitionsCount! !

!SequenceManager methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !