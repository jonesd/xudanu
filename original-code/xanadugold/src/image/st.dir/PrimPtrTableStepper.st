'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:26 pm'!

Stepper subclass: #PrimPtrTableStepper
	instanceVariableNames: '
		myPtrs {PtrArray}
		myIndices {IntegerVarArray}
		myIndex {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!
PrimPtrTableStepper comment:
'Stepper over map from integers to strong or wimpy pointers'!

(PrimPtrTableStepper getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimPtrTableStepper */
friend class PrimPtrTable;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimPtrTableStepper methodsFor: 'protected: create'!

create: from {IntegerVarArray} with: to {PtrArray} with: index {Int32}
	| tmp {Heaper wimpy} |
	super create.
	myIndices := from.
	myPtrs := to.
	myIndex := index.
	[myIndex < myPtrs count and: [(tmp _ myPtrs fetch: myIndex) == NULL or: [tmp == PrimRemovedObject make]]]
		whileTrue: [ myIndex := myIndex + 1 ].! !

!PrimPtrTableStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	myIndex < myPtrs count ifTrue: [ ^ myPtrs fetch: myIndex ]
	ifFalse: [ ^ NULL ]!

{BooleanVar} hasValue
	^ myIndex < myPtrs count!

{IntegerVar} index
	myIndex < myIndices count ifTrue: [^ myIndices integerVarAt: myIndex].
	Heaper BLAST: #EmptyStepper.
	^ NULL "Hush up the compiler"!

{void} step
	|tmp {Heaper wimpy} |
	myIndex := myIndex + 1.
	[myIndex < myPtrs count and: [(tmp _ myPtrs fetch: myIndex) == NULL or: [tmp == PrimRemovedObject make]]]
		whileTrue: [ myIndex := myIndex + 1 ].! !

!PrimPtrTableStepper methodsFor: 'create'!

{Stepper} copy
	^ PrimPtrTableStepper create: myIndices with: myPtrs with: myIndex! !