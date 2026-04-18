'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:28 pm'!

Stepper subclass: #GrandOverflowStepper
	instanceVariableNames: '
		overflow {GrandOverflow}
		entryIndex {IntegerVar}
		childStepper {GrandOverflowStepper}
		childIndex {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-stuff'!

(GrandOverflowStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!GrandOverflowStepper methodsFor: 'private:'!

{void} verifyEntry
	entryIndex < overflow entryCount
		ifTrue:
			[[entryIndex < overflow entryCount and: [(overflow entryAt: entryIndex) == NULL]]
				whileTrue: [entryIndex _ entryIndex + 1]].

	entryIndex < overflow entryCount ifTrue: [ ^ VOID ].
	
	childIndex < overflow childCount
		ifTrue:
			[[childIndex < overflow childCount and: [(overflow childAt: childIndex) == NULL]]
				whileTrue: [childIndex _ childIndex + 1].
				childIndex < overflow childCount
					ifTrue: [ childStepper _ GrandOverflowStepper create: (overflow childAt: childIndex) ]]! !

!GrandOverflowStepper methodsFor: 'operations'!

{GrandEntry} entry
	childStepper == NULL
		ifTrue: [ ^ overflow entryAt: entryIndex ]
		ifFalse: [ ^ childStepper entry ]!

{Heaper wimpy} fetch
	self shouldNotImplement.
	^ NULL!

{BooleanVar} hasValue
	childStepper ~~ NULL
		ifTrue: [ ^ childStepper hasValue ]
		ifFalse: [ ^ entryIndex < overflow entryCount and: [childIndex < overflow childCount]]!

{void} step
	childStepper ~~ NULL
		ifTrue:
			[childStepper step.
			childStepper hasValue
				ifTrue: [ ^VOID ]
				ifFalse:
					[childStepper destroy.
					childStepper _ NULL.
					childIndex _ childIndex + 1]]
		ifFalse:
			[entryIndex _ entryIndex + 1].
	self verifyEntry! !

!GrandOverflowStepper methodsFor: 'create'!

{Stepper} copy
	^ GrandOverflowStepper create: overflow with: entryIndex with: childStepper with: childIndex!

create: aPage {GrandOverflow}
	super create.
	overflow _ aPage.
	entryIndex _ childIndex _ IntegerVar0.
	childStepper _ NULL.
	self verifyEntry.! !

!GrandOverflowStepper methodsFor: 'protected: creation'!

create: anOverflow {GrandOverflow} with: entryIdx {IntegerVar} with: child {GrandOverflowStepper} with: childIdx {IntegerVar}
	super create.
	overflow _ anOverflow.
	entryIndex _ entryIdx.
	childStepper _ child.
	childIndex _ childIdx.!

{void} destruct
	childStepper ~~ NULL ifTrue: [ childStepper destroy ].
	super destruct.! !