'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:55 pm'!

PropFinder subclass: #ClosedPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
ClosedPropFinder comment:
'The finder which matches nothing.  Used to indicate that this subtree is known to be useless (no matches possible below here).'!

(ClosedPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!ClosedPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} isEmpty
	"Overridden only here"
	^true!

{BooleanVar} match: prop {Prop unused}
	"tell whether a prop matches this filter"
	^false!

{PropFinder} pass: crum {CanopyCrum unused}

	^self! !

!ClosedPropFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: ClosedPropFinder! !

!ClosedPropFinder methodsFor: 'create'!

create

	super create: UInt32Zero! !

!ClosedPropFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !