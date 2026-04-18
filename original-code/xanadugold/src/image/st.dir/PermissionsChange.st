'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:29 pm'!

PropChange subclass: #PermissionsChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
PermissionsChange comment:
'Used when the Permissions part of a BertProp changed'!

(PermissionsChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!PermissionsChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) permissions isEqual: (b cast: BertProp) permissions!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: (a cast: BertProp) permissions
		with: bp endorsements
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	before cast: BertProp into: [ :b |
	after cast: BertProp into: [ :a |
		| result {PropFinder} delta {RegionDelta}
		  any {PropFinder} anys {ImmuSet}
		  simple {PropFinder} simples {ImmuSet} |
		delta := RegionDelta make: b permissions with: a permissions.
		delta isSame ifTrue:
			[^NULL].
		any := AnyRecorderPFinder make: delta.
		any isEmpty
			ifTrue: [anys := ImmuSet make]
			ifFalse: [anys := ImmuSet newWith: any].
		simple :=ResultRecorderPFinder make: element
			with: delta
			with: a endorsements.
		simple isEmpty
			ifTrue: [simples := ImmuSet make]
			ifFalse: [simples := ImmuSet newWith: simple].
		oldFinder == NULL ifTrue:
			[result := CumulativeRecorderFinder
				make: anys
				with: simples
				with: ImmuSet make]
		ifFalse:
			[oldFinder cast: CumulativeRecorderFinder into: [ :crf |
				result := CumulativeRecorderFinder
					make: anys
					with: simples
					with: (crf current unionWith: crf others)]].
		result isEmpty
			ifTrue: [^NULL]
			ifFalse: [^result]]].
	^NULL "fodder"!

{BooleanVar} isFull
	"whether this is a complete change of props"
	^false!

{Prop} with: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: ((a cast: BertProp) permissions unionWith: bp permissions)
		with: bp endorsements
		with: bp isSensorWaiting
		with: bp isNotPartializable! !

!PermissionsChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) permissionsJoint isEqual: (b cast: BertPropJoint) permissionsJoint!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bp {BertPropJoint wimpy} |
	bp _ old cast: BertPropJoint.
	^BertPropJoint make: (a cast: BertPropJoint) permissionsJoint
		with: bp endorsementsJoint
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	^(a cast: BertPropJoint) permissionsJoint unioned isEqual: (b cast: BertProp) permissions!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	| bp {BertPropJoint wimpy} |
	bp _ old cast: BertPropJoint.
	^BertPropJoint make: ((a cast: BertPropJoint) permissionsJoint join: (b cast: BertPropJoint) permissionsJoint)
		with: bp endorsementsJoint
		with: bp isSensorWaiting
		with: bp isNotPartializable!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	^BertPropJoint make: (((a cast: BertPropJoint) permissionsJoint
			join: (b cast: BertPropJoint) permissionsJoint)
			with: (prop cast: BertProp) permissions)
		with: bpj endorsementsJoint
		with: bpj isSensorWaiting
		with: bpj isNotPartializable! !

!PermissionsChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !