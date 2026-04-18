'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:01 pm'!

BertPropFinder subclass: #SensorFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SensorFinder comment:
'Currently unused but will be re-instated.  Used to find which containing Editions have WaitForCompletionDetectors installed on them so that they can be rung when placegholders get filled in.'!

(SensorFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SensorFinder methodsFor: 'create'!

create

	super create: BertCrum isSensorWaitingFlag! !

!SensorFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition unused}
	
	^PropFinder closedPropFinder "Dont look for Detectors past an Edition boundary"!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	^(prop cast: BertProp) isSensorWaiting! !

!SensorFinder methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: SensorFinder! !

!SensorFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	(parent cast: BertPropJoint) isSensorWaiting
		ifTrue: [^self]
		ifFalse: [^PropFinder closedPropFinder]! !

!SensorFinder methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !