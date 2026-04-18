'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:15 pm'!

Stepper subclass: #IntegerEdgeStepper
	instanceVariableNames: '
		myEntering {BooleanVar}
		myIndex {UInt32}
		myCount {UInt32}
		myEdges {IntegerVarArray}'
	classVariableNames: 'SomeEdgeSteppers {InstanceCache} '
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!
IntegerEdgeStepper comment:
'A single instance of this class is cached.  To take advantage of this, a method
that uses IntegerEdgeSteppers should explicitly destroy at least one of them.'!

(IntegerEdgeStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!IntegerEdgeStepper methodsFor: 'operations'!

{Heaper wimpy} fetch
	self hasValue ifTrue: [^IntegerPos make: self edge] ifFalse: [^NULL]!

{BooleanVar INLINE} hasValue
	^myIndex < myCount!

{void INLINE} step
	myEntering _ myEntering not.
	myIndex _ myIndex + 1! !

!IntegerEdgeStepper methodsFor: 'edge accessing'!

{IntegerVar INLINE} edge
	"the current transition"
	(myIndex >= myCount) ifTrue: [ IntegerEdgeStepper outOfBounds ].
	^myEdges integerVarAt: myIndex!

{BooleanVar INLINE} isEntering
	"whether the current transition is entering or leaving the set"
	^myEntering! !

!IntegerEdgeStepper methodsFor: 'protected: create'!

create: entering {BooleanVar} with: count {UInt32} with: edges {IntegerVarArray}
	super create.
	myEntering _ entering.
	myIndex _ Int32Zero.
	myCount _ count.
	myEdges _ edges!

create: entering {BooleanVar} with: index {UInt32} with: count {UInt32} with: edges {IntegerVarArray}
	super create.
	myEntering _ entering.
	myIndex _ index.
	myCount _ count.
	myEdges _ edges! !

!IntegerEdgeStepper methodsFor: 'destroy'!

{void} destroy
	(SomeEdgeSteppers store: self) ifFalse:
		[super destroy]! !

!IntegerEdgeStepper methodsFor: 'create'!

{Stepper} copy
	^IntegerEdgeStepper create: myEntering with: myIndex with: myCount with: myEdges! !

!IntegerEdgeStepper methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '('.
	self hasValue ifTrue:
		[self isEntering ifTrue: 
			[oo << 'entering ']
		ifFalse: 
			[oo << 'leaving '].
		oo << self edge].
	oo << ')'.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerEdgeStepper class
	instanceVariableNames: ''!

(IntegerEdgeStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!IntegerEdgeStepper class methodsFor: 'errors'!

{void} outOfBounds
	self BLAST: #OutOfBounds! !

!IntegerEdgeStepper class methodsFor: 'create'!

make: entering {BooleanVar} with: count {UInt32} with: edges {IntegerVarArray}
	| result {Heaper} |
	result := SomeEdgeSteppers fetch.
	result == NULL ifTrue: [
		^ self create: entering with: count with: edges]
	ifFalse: [
		^ (self new.Become: result) create: entering with: count with: edges]! !

!IntegerEdgeStepper class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	SomeEdgeSteppers := InstanceCache make: 2!

linkTimeNonInherited
	SomeEdgeSteppers := NULL! !