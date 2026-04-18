'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:25 pm'!

Stepper subclass: #PrimPtr2PtrTableStepper
	instanceVariableNames: '
		myFromPtrs {PtrArray}
		myToPtrs {PtrArray}
		myIndex {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-primtab'!

(PrimPtr2PtrTableStepper getOrMakeCxxClassDescription)
	friends:
'/* friends for class PrimPtr2PtrTableStepper */
friend class PrimPtr2PtrTable;';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimPtr2PtrTableStepper methodsFor: 'create'!

{Stepper} copy
	^ PrimPtr2PtrTableStepper create: myFromPtrs with: myToPtrs with: myIndex! !

!PrimPtr2PtrTableStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	myIndex < myToPtrs count ifTrue: [ ^ myToPtrs fetch: myIndex ]
	ifFalse: [ ^ NULL ]!

{BooleanVar} hasValue
	^ myIndex < myToPtrs count!

{Heaper} heaperKey
	myIndex < myFromPtrs count ifTrue: [^ myFromPtrs fetch: myIndex]
	ifFalse: [ ^ NULL ]!

{void} step
	|tmp {Heaper wimpy} |
	myIndex := myIndex + 1.
	[myIndex < myToPtrs count and: [(tmp _ myToPtrs fetch: myIndex) == NULL or: [tmp == PrimRemovedObject make]]]
		whileTrue: [ myIndex := myIndex + 1 ].! !

!PrimPtr2PtrTableStepper methodsFor: 'protected: create'!

create: from {PtrArray} with: to {PtrArray} with: index {Int32}
	| tmp {Heaper wimpy} |
	super create.
	myFromPtrs := from.
	myToPtrs := to.
	myIndex := index.
	[myIndex < myToPtrs count and: [(tmp _ myToPtrs fetch: myIndex) == NULL or: [tmp == PrimRemovedObject make]]]
		whileTrue: [ myIndex := myIndex + 1 ].! !