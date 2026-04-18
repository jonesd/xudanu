'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:30 pm'!

FullPropChange subclass: #SensorPropChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
SensorPropChange comment:
'Use when it is fine to consider that all aspects of the SensorProp may have changed'!

(SensorPropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!SensorPropChange methodsFor: 'accessing'!

{PropFinder | NULL} fetchFinder: before {Prop unused}
	with: after {Prop unused}
	with: element {BeRangeElement unused}
	with: oldFinder {PropFinder unused | NULL}

	^NULL! !

!SensorPropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	
	a cast: SensorPropJoint into: [ :spj |
	b cast: SensorProp into: [ :sp |
		^(spj relevantEndorsements isEqual: sp relevantEndorsements)
			and: [(spj relevantPermissions isEqual: sp relevantPermissions)
			and: [spj isPartial == sp isPartial]]]].
	^false "fodder"! !

!SensorPropChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !