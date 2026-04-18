'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:58 pm'!

SensorPropFinder subclass: #PartialityFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
PartialityFinder comment:
'When walking the o-plane to separate out the "partial" part of an Edition, this finder is used to filter the walk according to the sensor canopy.'!

(PartialityFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #COPY; add: #SMALLTALK.ONLY; add: #OBSOLETE; add: #NOT.A.TYPE; add: #CONCRETE; yourself)!

!PartialityFinder methodsFor: 'create'!

create

	super create: SensorCrum isPartialFlag! !

!PartialityFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^(prop cast: SensorProp) isPartial! !

!PartialityFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: PartialityFinder! !

!PartialityFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	(parent cast: SensorPropJoint) isPartial
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!PartialityFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !