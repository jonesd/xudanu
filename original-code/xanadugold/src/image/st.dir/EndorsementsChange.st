'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:28 pm'!

PropChange subclass: #EndorsementsChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
EndorsementsChange comment:
'Used when the Endorsement part of a BertProp changed'!

(EndorsementsChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!EndorsementsChange methodsFor: 'accessing'!

{BooleanVar} areEqualProps: a {Prop} with: b {Prop}
	"compare the changed parts of two Props"
	^(a cast: BertProp) endorsements isEqual: (b cast: BertProp) endorsements!

{Prop} changed: old {Prop} with: a {Prop}

	| bp {BertProp wimpy} |
	bp _ old cast: BertProp.
	^BertProp make: bp permissions
		with: (a cast: BertProp) endorsements
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
		delta := RegionDelta make: b endorsements with: a endorsements.
		delta isSame ifTrue:
			[^NULL].
		any := AnyRecorderEFinder make: (a permissions cast: IDRegion) with: delta.
		any isEmpty
			ifTrue: [anys := ImmuSet make]
			ifFalse: [anys := ImmuSet newWith: any].
		simple := OriginalResultRecorderEFinder make: element
			with: (a permissions cast: IDRegion)
			with: delta.
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
	^BertProp make: bp permissions
		with: ((a cast: BertProp) endorsements unionWith: bp endorsements)
		with: bp isSensorWaiting
		with: bp isNotPartializable! !

!EndorsementsChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} areEqualPropJoints: a {PropJoint} with: b {PropJoint}
	"compare the changed parts of two PropJoints"
	^(a cast: BertPropJoint) endorsementsJoint isEqual: (b cast: BertPropJoint) endorsementsJoint!

{PropJoint} changedJoint: old {PropJoint} with: a {PropJoint}
	
	| bertprop {BertPropJoint wimpy} |
	bertprop _ old cast: BertPropJoint.
	^BertPropJoint make: bertprop  permissionsJoint
		with: (a cast: BertPropJoint) endorsementsJoint
		with: bertprop isSensorWaiting
		with: bertprop isNotPartializable!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	^(a cast: BertPropJoint) endorsementsJoint unioned isEqual: (b cast: BertProp) endorsements!

{PropJoint} join: old {PropJoint} with: a {PropJoint} with: b {PropJoint}
	"combine two PropJoints with minimum effort, given the previous result"
	| bertprop {BertPropJoint wimpy} |
	bertprop _ old cast: BertPropJoint.
	^BertPropJoint make: bertprop  permissionsJoint
		with: ((a cast: BertPropJoint) endorsementsJoint join: (b cast: BertPropJoint) endorsementsJoint)
		with: bertprop isSensorWaiting
		with: bertprop isNotPartializable!

{PropJoint} joinProp: old {PropJoint} with: a {PropJoint} with: b {PropJoint} with: prop {Prop}
	"combine two PropJoints and a prop with minimum effort, given the previous result"
	| bpj {BertPropJoint wimpy} |
	bpj _ old cast: BertPropJoint.
	^BertPropJoint make: bpj  permissionsJoint
		with: (((a cast: BertPropJoint) endorsementsJoint
			join: (b cast: BertPropJoint) endorsementsJoint)
			with: (prop cast: BertProp) endorsements)
		with: bpj isSensorWaiting
		with: bpj isNotPartializable! !

!EndorsementsChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !