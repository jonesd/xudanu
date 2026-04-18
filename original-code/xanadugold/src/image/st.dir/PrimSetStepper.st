'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:28 pm'!

Stepper subclass: #PrimSetStepper
	instanceVariableNames: '
		myPtrs {PtrArray}
		myIndex {Int4}'
	classVariableNames: 'SomeSteppers {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-primtab'!

(PrimSetStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimSetStepper methodsFor: 'create'!

{Stepper} copy
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^ PrimSetStepper create: myPtrs with: Int32Zero]
		ifFalse: [^ (PrimSetStepper new.Become: result) create: myPtrs with: Int32Zero]!

create: array {PtrArray} with: index {Int32}
	| tmp {Heaper wimpy} |
	super create.
	myPtrs := array.
	myIndex := index.
	[myIndex < myPtrs count and: [(tmp _ myPtrs fetch: myIndex) == NULL or: [tmp == PrimRemovedObject make]]]
		whileTrue: [ myIndex := myIndex + 1 ].!

{void} destroy
	(SomeSteppers store: self) ifFalse:
		[super destroy]! !

!PrimSetStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	myIndex < myPtrs count
		ifTrue: [ ^ myPtrs fetch: myIndex ]
		ifFalse: [ ^ NULL ]!

{BooleanVar} hasValue
	^ myIndex < myPtrs count!

{void} step
	|tmp {Heaper wimpy} |
	myIndex := myIndex + 1.
	[myIndex < myPtrs count and: [(tmp _ myPtrs fetch: myIndex) == NULL or: [tmp == PrimRemovedObject make]]]
		whileTrue: [ myIndex := myIndex + 1 ].! !

!PrimSetStepper methodsFor: 'printint'!

{void} printOn: oo {ostream reference}
	| printedElem {BooleanVar} |
	oo << 'PrimSetStepper on {'.
	printedElem := false.
	Int32Zero almostTo: myPtrs count do: [:i {Int32} |
		(myPtrs fetch: i) ~~ NULL ifTrue: [
			printedElem ifTrue: [oo << ', '].
			oo << (myPtrs fetch: i).
			printedElem := true]].
	oo << '}'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PrimSetStepper class
	instanceVariableNames: ''!

(PrimSetStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PrimSetStepper class methodsFor: 'create'!

{Stepper} make: ptrs {PtrArray}
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^ PrimSetStepper create: ptrs with: Int32Zero]
		ifFalse: [^ (PrimSetStepper new.Become: result) create: ptrs with: Int32Zero]! !

!PrimSetStepper class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeSteppers := InstanceCache make: 8!

linkTimeNonInherited
	SomeSteppers := NULL! !