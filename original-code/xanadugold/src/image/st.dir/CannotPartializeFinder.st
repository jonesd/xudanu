'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:53 pm'!

BertPropFinder subclass: #CannotPartializeFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
CannotPartializeFinder comment:
'Used to figure out which Stamps have Orgls on them so that the archiver can knw that they cannot be partialized.  Will go away because the state described is session level state and therefore should be store in NOCOPY variables instead of in the Canopy''s Props.'!

(CannotPartializeFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CannotPartializeFinder methodsFor: 'create'!

create

	super create: BertCrum isNotPartializableFlag! !

!CannotPartializeFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition unused}
	
	^self "inability to partialize is transitive"!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^(prop cast: BertProp) isNotPartializable! !

!CannotPartializeFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: CannotPartializeFinder! !

!CannotPartializeFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	(parent cast: BertPropJoint) isNotPartializable
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!CannotPartializeFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !