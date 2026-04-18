'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:26 pm'!

Stepper subclass: #GrandHashSetStepper
	instanceVariableNames: '
		set {GrandHashSet}
		nodeStepper {GrandNodeStepper | NULL}
		nodeIndex {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-stuff'!

(GrandHashSetStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!GrandHashSetStepper methodsFor: 'private: private'!

{void} verifyEntry
	[nodeIndex < set nodeCount and: [(set nodeAt: nodeIndex) isEmpty]]
		whileTrue:
			[nodeIndex _ nodeIndex + 1 ].
	nodeIndex < set nodeCount ifTrue:
		[nodeStepper _ GrandNodeStepper create: (set nodeAt: nodeIndex)]! !

!GrandHashSetStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	(nodeStepper ~~ NULL and: [nodeStepper hasValue])
		ifTrue: [^ nodeStepper entry value]
		ifFalse: [^ NULL]!

{BooleanVar} hasValue
	^ (nodeIndex < set nodeCount) and: [nodeStepper hasValue]!

{void} step
	nodeStepper step.
	nodeStepper hasValue ifFalse:
		[nodeStepper destroy.
		nodeStepper _ NULL.
		nodeIndex _ nodeIndex + 1.
		self verifyEntry]! !

!GrandHashSetStepper methodsFor: 'protected: create'!

create: aSet {GrandHashSet} with: aNodeStepper {GrandNodeStepper} with: aNodeIndex {IntegerVar}
	super create.
	set _ aSet.
	set moreSteppers.
	nodeStepper _ aNodeStepper.
	nodeIndex _ aNodeIndex.!

{void} destruct
	nodeStepper ~~ NULL ifTrue: [ nodeStepper destroy ].
	set fewerSteppers.
	super destruct.! !

!GrandHashSetStepper methodsFor: 'create'!

{Stepper} copy
	^ GrandHashSetStepper create: set with: nodeStepper with: nodeIndex!

create: aSet {GrandHashSet}
	super create.
	set _ aSet.
	set moreSteppers.
	nodeIndex _ IntegerVar0.
	nodeStepper _ NULL.
	self verifyEntry! !