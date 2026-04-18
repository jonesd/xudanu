'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:14 pm'!

Stepper subclass: #DescendingIntegerStepper
	instanceVariableNames: '
		myEdges {IntegerVarArray}
		myIndex {Int32}
		myPosition {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!

(DescendingIntegerStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DescendingIntegerStepper methodsFor: 'protected: create'!

create: edges {IntegerVarArray} with: count {UInt32}
	super create.
	myEdges _ edges.
	myIndex _ count - 2.
	myIndex >= -1
		ifTrue: [myPosition _ (myEdges integerVarAt: myIndex + 1) - 1]
		ifFalse: [myPosition _ IntegerVar0]!

create: edges {IntegerVarArray} with: index {Int32} with: position {IntegerVar}
	super create.
	myEdges _ edges.
	myIndex _ index.
	myPosition _ position! !

!DescendingIntegerStepper methodsFor: 'creation'!

{Stepper} copy
	^DescendingIntegerStepper create: myEdges with: myIndex with: myPosition! !

!DescendingIntegerStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	self hasValue ifTrue: [^myPosition integer] ifFalse: [^NULL]!

{BooleanVar} hasValue
	^myIndex >= -1!

{void} step
	myPosition _ myPosition - 1.
	(myIndex >= Int32Zero and: [myPosition < (myEdges integerVarAt: myIndex)]) ifTrue:
		[myIndex _ myIndex - 2.
		myIndex >= -1 ifTrue:
			[myPosition _ (myEdges integerVarAt: myIndex + 1) - 1]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DescendingIntegerStepper class
	instanceVariableNames: ''!

(DescendingIntegerStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DescendingIntegerStepper class methodsFor: 'creation'!

{Stepper} make: edges {IntegerVarArray} with: count {UInt32}
	^ self create: edges with: count! !