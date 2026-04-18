'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:27 pm'!

Stepper subclass: #GrandNodeStepper
	instanceVariableNames: '
		node {GrandNode}
		pageStepper {GrandDataPageStepper}
		pageIndex {IntegerVar}
		overflowStepper {GrandOverflowStepper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-stuff'!

(GrandNodeStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!GrandNodeStepper methodsFor: 'protected: creation'!

create: aNode {GrandNode} with: curPageStepper {GrandDataPageStepper} with: curPageIndex {IntegerVar} with: oflowStepper {GrandOverflowStepper}
	super create.
	node _ aNode.
	pageStepper _ curPageStepper.
	pageIndex _ curPageIndex.
	overflowStepper _ oflowStepper.!

{void} destruct
	pageStepper ~~ NULL ifTrue: [ pageStepper destroy ].
	overflowStepper ~~ NULL ifTrue: [ overflowStepper destroy ].
	super destruct.! !

!GrandNodeStepper methodsFor: 'private:'!

{void} verifyEntry
	[pageIndex < node pageCount and: [(node pageAt: pageIndex) isEmpty]]
		whileTrue:
			[pageIndex _ pageIndex + 1].
	pageIndex < node pageCount
		ifTrue:		
			[pageStepper _ GrandDataPageStepper create: (node pageAt: pageIndex)]
		ifFalse:
			[(overflowStepper == NULL and: [node fetchOverflow ~~ NULL])
				ifTrue:
					[overflowStepper _ GrandOverflowStepper create: node fetchOverflow]
				ifFalse:
					[overflowStepper ~~ NULL ifTrue:
						[overflowStepper destroy].
					overflowStepper _ NULL.
					node fetchOldOverflow ~~ NULL ifTrue:
						[overflowStepper _ GrandOverflowStepper create: node fetchOldOverflow]]]! !

!GrandNodeStepper methodsFor: 'operations'!

{GrandEntry} entry
	overflowStepper ~~ NULL 
		ifTrue: [ ^ overflowStepper entry ]
		ifFalse: [ ^ pageStepper entry ]!

{Heaper wimpy} fetch
	self shouldNotImplement.
	^ NULL!

{BooleanVar} hasValue
	overflowStepper ~~ NULL
		ifTrue: [ ^ overflowStepper hasValue ]
		ifFalse: [ ^ pageStepper ~~ NULL and: [pageStepper hasValue] ]!

{void} step
	overflowStepper ~~ NULL
		ifTrue: [ overflowStepper step ]
		ifFalse:
			[pageStepper step.
			pageStepper hasValue ifFalse:
				[pageStepper destroy.
				pageStepper _ NULL.
				pageIndex _ pageIndex + 1.
				self verifyEntry]]! !

!GrandNodeStepper methodsFor: 'create'!

{Stepper} copy
	^ GrandNodeStepper create: node with: pageStepper with: pageIndex with: overflowStepper!

create: aNode {GrandNode}
	super create.
	node _ aNode.
	pageIndex _ IntegerVar0.
	pageStepper _ NULL.
	overflowStepper _ NULL.
	self verifyEntry.! !