'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:57 pm'!

PropFinder subclass: #OpenPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
OpenPropFinder comment:
'The finder which matches everything.  Used to indicate that everything below here necessarily matches.'!

(OpenPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!OpenPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} isFull
	
	^true!

{BooleanVar} match: prop {Prop unused}
	"tell whether a prop matches this filter"
	^true!

{PropFinder} pass: crum {CanopyCrum unused}

	^self! !

!OpenPropFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: OpenPropFinder! !

!OpenPropFinder methodsFor: 'create'!

create

	super create: UInt32Zero bitInvert! !

!OpenPropFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !