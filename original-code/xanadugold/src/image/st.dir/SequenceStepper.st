'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:22 pm'!

Stepper subclass: #SequenceStepper
	instanceVariableNames: '
		myIndex {Int32}
		myTransitions {PtrArray of: SequenceEdge}
		myTransitionsCount {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-id'!

(SequenceStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SequenceStepper methodsFor: 'operations'!

{Heaper wimpy} fetch

	myIndex < myTransitionsCount ifTrue:
		[^((myTransitions fetch: myIndex) cast: SequenceEdge) sequence]
	ifFalse:
		[^NULL]!

{BooleanVar} hasValue
	^myIndex < myTransitionsCount!

{void} step
	myIndex := myIndex + 2! !

!SequenceStepper methodsFor: 'create'!

{Stepper} copy
	
	^SequenceStepper create: myIndex with: myTransitions with: myTransitionsCount!

create: transitions {PtrArray of: IDEdge} with: count {Int32}

	super create.
	myIndex := Int32Zero.
	myTransitions := transitions.
	myTransitionsCount := count.!

create: index {Int32} with: transitions {PtrArray of: IDEdge} with: count {Int32}

	super create.
	myIndex := index.
	myTransitions := transitions.
	myTransitionsCount := count.! !