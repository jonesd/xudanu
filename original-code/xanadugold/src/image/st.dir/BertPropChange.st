'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:27 pm'!

FullPropChange subclass: #BertPropChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-props'!
BertPropChange comment:
'Use when it is fine to consider that all aspects of the BertProp may have changed'!

(BertPropChange getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; add: #NOT.A.TYPE; yourself)!

!BertPropChange methodsFor: 'accessing'!

{PropFinder | NULL} fetchFinder: before {Prop}
	with: after {Prop}
	with: element {BeRangeElement}
	with: oldFinder {PropFinder | NULL}
	
	| p {PropFinder} e {PropFinder} |
	p := PropChange permissionsChange
			fetchFinder: before with: after with: element with: oldFinder.
	e := PropChange endorsementsChange
			fetchFinder: before with: after with: element with: oldFinder.
	p == NULL ifTrue: [^e].
	e == NULL ifTrue: [^p].
	p cast: CumulativeRecorderFinder into: [ :pcrf |
	e cast: CumulativeRecorderFinder into: [ :ecrf |
		^CumulativeRecorderFinder
			make: (pcrf generators unionWith: ecrf generators)
			with: (pcrf current unionWith: ecrf current)
			with: (pcrf others unionWith: ecrf others)]].
	^NULL "fodder"! !

!BertPropChange methodsFor: 'smalltalk: suspended'!

{BooleanVar} isEqualToJointOf: a {PropJoint} with: b {Prop}
	"compare the changed parts of a PropJoint and a Prop"
	| bpj {BertPropJoint wimpy} bp {BertProp wimpy} |
	bpj _ a cast: BertPropJoint.
	bp _ b cast: BertProp.
	^(bpj endorsementsJoint unioned isEqual: bp endorsements)
		and: [(bpj permissionsJoint unioned isEqual: bp permissions)
		and: [bpj isSensorWaiting == bp isSensorWaiting
		and: [bpj isNotPartializable == bp isNotPartializable]]]! !

!BertPropChange methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !