'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:28 pm'!

PropChange subclass: #DetectorWaitingChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
DetectorWaitingChange comment:
'The "Detector Waiting" property is a Bert Canopy property to remember that an Edition has a Detector waiting for PlaceHolders to be filled in.'!

(DetectorWaitingChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!DetectorWaitingChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) isSensorWaiting == (b cast: BertProp) isSensorWaiting!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	bp isSensorWaiting == abp isSensorWaiting ifTrue: [^old].
	^BertProp make: bp permissions
		with: bp endorsements
		with: abp isSensorWaiting
		with: bp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop unused}
	with: after {Prop unused}
	with: element {BeRangeElement unused}
	with: oldFinder {PropFinder unused | NULL}

	^NULL!

{BooleanVar} isFull

	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	(bp isSensorWaiting or: [abp isSensorWaiting not])
		ifTrue: [^old]
		ifFalse: [^BertProp make: bp permissions
			with: bp endorsements
			with: abp isSensorWaiting
			with: bp isNotPartializable]! !

!DetectorWaitingChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) isSensorWaiting == (b cast: BertPropJoint) isSensorWaiting!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	bpj isSensorWaiting == one isSensorWaiting
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: one isSensorWaiting
				with: bpj isNotPartializable]!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}

	^(a cast: BertPropJoint) isSensorWaiting == (b cast: BertProp) isSensorWaiting!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}

	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	bpj isSensorWaiting == (one isSensorWaiting
			or: [two isSensorWaiting])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting not
				with: bpj isNotPartializable]!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}

	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} p {BertProp wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	p _ prop cast: BertProp.
	bpj isSensorWaiting == (one isSensorWaiting
			or: [two isSensorWaiting
			or: [p isSensorWaiting]])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting not
				with: bpj isNotPartializable]! !

!DetectorWaitingChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !