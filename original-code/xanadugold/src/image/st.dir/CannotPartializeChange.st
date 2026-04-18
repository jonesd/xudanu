'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:27 pm'!

PropChange subclass: #CannotPartializeChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
CannotPartializeChange comment:
'The "Cannot Partialize" property is a Bert Canopy property to remember that a Stamp is actively being viewed (by a session level Orgl) and therefore cannot be poured-out (made more partial).  Should probably not be a Prop(erty), by rather a NOCOPY session level bit in the BertCrums.'!

(CannotPartializeChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!CannotPartializeChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) isNotPartializable == (b cast: BertProp) isNotPartializable!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	bp isNotPartializable == abp isNotPartializable ifTrue: [^old].
	^BertProp make: bp permissions
		with: bp endorsements
		with: bp isSensorWaiting
		with: abp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop unused}
	with: after {Prop unused}
	with: element {BeRangeElement unused}
	with: oldFinder {PropFinder unused | NULL}

	^NULL!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} abp {BertProp wimpy} |
	bp _ old cast: BertProp.
	abp _ a cast: BertProp.
	(bp isNotPartializable or: [abp isNotPartializable not])
		ifTrue: [^old]
		ifFalse: [^BertProp make: bp permissions
			with: bp endorsements
			with: bp isSensorWaiting
			with: abp isNotPartializable]! !

!CannotPartializeChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) isNotPartializable == (b cast: BertPropJoint) isNotPartializable!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	bpj isNotPartializable == one isNotPartializable
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting
				with: bpj isNotPartializable not]!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	^(a cast: BertPropJoint) isNotPartializable == (b cast: BertProp) isNotPartializable!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	bpj isNotPartializable == (one isNotPartializable
			or: [two isNotPartializable])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting
				with: bpj isNotPartializable not]!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} one {BertPropJoint wimpy} two {BertPropJoint wimpy} p {BertProp wimpy} |
	bpj _ old cast: BertPropJoint.
	one _ a cast: BertPropJoint.
	two _ b cast: BertPropJoint.
	p _ prop cast: BertProp.
	bpj isNotPartializable == (one isNotPartializable
			or: [two isNotPartializable
			or: [p isNotPartializable]])
		ifTrue: [^old]
		ifFalse: [^BertPropJoint make: bpj permissionsJoint
				with: bpj endorsementsJoint
				with: bpj isSensorWaiting
				with: bpj isNotPartializable not]! !

!CannotPartializeChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !