'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:24 pm'!

Stepper subclass: #PrimIndexTableStepper
	instanceVariableNames: '
		myPtrs {PtrArray}
		myIndices {IntegerVarArray}
		myIndex {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!
PrimIndexTableStepper comment:
'Stepper over map from pointers to integers'!

(PrimIndexTableStepper getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimIndexTableStepper */
friend class PrimIndexTable;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimIndexTableStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	myIndex < myPtrs count ifTrue: [ ^ IntegerPos make: (myIndices integerVarAt: myIndex) ]
	ifFalse: [ ^ NULL ]!

{BooleanVar} hasValue
	^ myIndex < myPtrs count!

{Heaper}  key
	"This does not necessarily return a Position"
	myIndex < myIndices count ifTrue: [^ myPtrs fetch: myIndex].
	Heaper BLAST: #EmptyStepper.
	^ NULL "Hush up the compiler"!

{void} step
	|tmp {Heaper wimpy} |
	myIndex := myIndex + 1.
	[myIndex < myPtrs count and: [(tmp _ myPtrs fetch: myIndex) == NULL or: [tmp == PrimRemovedObject make]]]
		whileTrue: [ myIndex := myIndex + 1 ].!

{IntegerVar} value
	myIndex < myPtrs count ifTrue: [ ^ myIndices integerVarAt: myIndex]
	ifFalse: [ Heaper BLAST: #EmptyStepper.
			^ NULL ]! !

!PrimIndexTableStepper methodsFor: 'protected: create'!

create: from {PtrArray} with: to {IntegerVarArray} with: index {Int32}
	| tmp {Heaper wimpy} |
	super create.
	myPtrs := from.
	myIndices := to.
	myIndex := index.
	[myIndex < myPtrs count and: [(tmp _ myPtrs fetch: myIndex) == NULL or: [tmp == PrimRemovedObject make]]]
		whileTrue: [ myIndex := myIndex + 1 ].! !

!PrimIndexTableStepper methodsFor: 'create'!

{Stepper} copy
	^ PrimIndexTableStepper create: myPtrs with: myIndices with: myIndex! !