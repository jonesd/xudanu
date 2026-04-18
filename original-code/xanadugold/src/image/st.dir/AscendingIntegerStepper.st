'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:13 pm'!

Stepper subclass: #AscendingIntegerStepper
	instanceVariableNames: '
		myEdges {IntegerVarArray}
		myIndex {UInt32}
		myCount {UInt32}
		myPosition {IntegerVar}'
	classVariableNames: 'SomeSteppers {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!

(AscendingIntegerStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!AscendingIntegerStepper methodsFor: 'protected: creation'!

create: edges {IntegerVarArray} with: count {UInt32}

	super create.
	myEdges _ edges.
	myIndex _ 1.
	myCount _ count.
	myCount > Int32Zero
		ifTrue: [myPosition _ myEdges integerVarAt: Int32Zero]
		ifFalse: [myPosition _ IntegerVar0]!

create: edges {IntegerVarArray} with: index {UInt32} with: count {UInt32} with: position {IntegerVar}
	super create.
	myEdges _ edges.
	myIndex _ index.
	myCount _ count.
	myPosition _ position! !

!AscendingIntegerStepper methodsFor: 'creation'!

{Stepper} copy
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^AscendingIntegerStepper create: myEdges with: myIndex with: myCount with: myPosition]
		ifFalse:[^(AscendingIntegerStepper new.Become: result) create: myEdges with: myIndex with: myCount with: myPosition]!

{void} destroy
	(SomeSteppers store: self) ifFalse: [super destroy]! !

!AscendingIntegerStepper methodsFor: 'accessing'!

{Heaper wimpy} fetch
	self hasValue ifTrue: [^myPosition integer] ifFalse: [^NULL]!

{BooleanVar} hasValue
	^myIndex <= myCount!

{void} step
	myPosition _ myPosition + 1.
	(myIndex < myCount and: [myPosition = (myEdges integerVarAt: myIndex)]) ifTrue:
		[myIndex _ myIndex + 2.
		myIndex <= myCount ifTrue:
			[myPosition _ myEdges integerVarAt: myIndex - 1]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AscendingIntegerStepper class
	instanceVariableNames: ''!

(AscendingIntegerStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!AscendingIntegerStepper class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeSteppers := InstanceCache make: 16!

linkTimeNonInherited
	SomeSteppers := NULL! !

!AscendingIntegerStepper class methodsFor: 'creation'!

{Stepper} make: edges {IntegerVarArray} with: count {UInt32}
	| result {Heaper} |
	result := SomeSteppers fetch.
	result == NULL
		ifTrue: [^ self create: edges with: count]
		ifFalse: [^ (self new.Become: result) create: edges with: count]! !