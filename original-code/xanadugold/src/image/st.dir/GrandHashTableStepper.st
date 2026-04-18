'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:27 pm'!

TableStepper subclass: #GrandHashTableStepper
	instanceVariableNames: '
		table {GrandHashTable}
		nodeStepper {GrandNodeStepper | NULL}
		nodeIndex {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-stuff'!

(GrandHashTableStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!GrandHashTableStepper methodsFor: 'private: private'!

{void} verifyEntry
	[nodeIndex < table nodeCount and: [(table nodeAt: nodeIndex) isEmpty]]
		whileTrue:
			[nodeIndex _ nodeIndex + 1 ].
	nodeIndex < table nodeCount ifTrue:
		[nodeStepper _ GrandNodeStepper create: (table nodeAt: nodeIndex)]! !

!GrandHashTableStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	(nodeStepper ~~ NULL and: [nodeStepper hasValue])
		ifTrue: [^ nodeStepper entry value]
		ifFalse: [^NULL]!

{BooleanVar} hasValue
	^ nodeStepper ~~ NULL!

{void} step
	nodeStepper step.
	nodeStepper hasValue ifFalse:
		[nodeStepper destroy.
		nodeStepper _ NULL.
		nodeIndex _ nodeIndex + 1.
		self verifyEntry]! !

!GrandHashTableStepper methodsFor: 'special'!

{Position} position
	^ (nodeStepper entry cast: GrandTableEntry) position! !

!GrandHashTableStepper methodsFor: 'create'!

{Stepper} copy
	^ GrandHashTableStepper create: table with: nodeStepper with: nodeIndex!

create: aTable {GrandHashTable}
	super create.
	table _ aTable.
	table moreSteppers.
	nodeIndex _ IntegerVar0.
	nodeStepper _ NULL.
	self verifyEntry! !

!GrandHashTableStepper methodsFor: 'protected: creation'!

create: aTable {GrandHashTable} with: aNodeStepper {GrandNodeStepper} with: aNodeIndex {IntegerVar}
	super create.
	table _ aTable.
	table moreSteppers.
	nodeStepper _ aNodeStepper.
	nodeIndex _ aNodeIndex.!

{void} destruct
	nodeStepper ~~ NULL ifTrue: [ nodeStepper destroy ].
	table fewerSteppers.
	super destruct.! !