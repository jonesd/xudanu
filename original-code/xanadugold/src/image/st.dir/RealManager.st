'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:53 pm'!

EdgeManager subclass: #RealManager
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(RealManager getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!RealManager methodsFor: 'protected:'!

{Position} edgePosition: edge {TransitionEdge}
	
	^(edge cast: RealEdge) position!

{XnRegion} makeNew: startsInside {BooleanVar} with: transitions {PtrArray of: TransitionEdge}

	^RealRegion make: startsInside with: transitions!

{XnRegion} makeNew: startsInside {BooleanVar} with: transitions {PtrArray of: TransitionEdge} with: count {Int32}

	^self makeNew: startsInside with: ((transitions copy: count) cast: PtrArray)!

{PtrArray of: TransitionEdge} posTransitions: pos {Position}

	self unimplemented.
	^NULL "fodder"!

{BooleanVar} startsInside: region {XnRegion}

	^(region cast: RealRegion) startsInside!

{PtrArray of: TransitionEdge} transitions: region {XnRegion}

	^(region cast: RealRegion) secretTransitions!

{Int32 INLINE} transitionsCount: region {XnRegion}

	^(region cast: RealRegion) secretTransitions count! !

!RealManager methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !