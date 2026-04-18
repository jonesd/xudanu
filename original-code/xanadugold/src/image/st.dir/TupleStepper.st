'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:47 pm'!

Stepper subclass: #TupleStepper
	instanceVariableNames: '
		mySpace {CrossSpace}
		myVirginSteppers {PtrArray of: (Stepper of: Position)}
		mySteppers {PtrArray of: (Stepper of: Position)}
		myLexOrder {PrimIntArray}
		myValue {Tuple | NULL}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cross'!
TupleStepper comment:
'A stepper for stepping through the positions in a simple cross region in order according to a lexicographic composition of OrderSpecs of each of the projections of the region.  See CrossOrderSpec.NOT.A.TYPE '!

(TupleStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!TupleStepper methodsFor: 'private: creation'!

create: space {CrossSpace} 
	with: virginSteppers {PtrArray of: (Stepper of: Position)}
	with: steppers {PtrArray of: (Stepper of: Position)}
	with: lexOrder {PrimIntArray} 
	
	super create.
	mySpace := space.
	myVirginSteppers := virginSteppers.
	mySteppers := steppers.
	myLexOrder := lexOrder.
	self setValueFromSteppers! !

!TupleStepper methodsFor: 'private:'!

{void} setValueFromSteppers

	| coords {PtrArray of: Position} |
	coords := PtrArray nulls: mySteppers count.
	Int32Zero almostTo: mySteppers count do: [:i {Int32} |
		coords at: i store: (((mySteppers fetch: i) cast: Stepper) get cast: Position)].
	myValue := mySpace crossOfPositions: coords! !

!TupleStepper methodsFor: 'operations'!

{Stepper} copy
	
	| newSteppers {PtrArray of: (Stepper of: Position)} |
	self hasValue ifFalse:
		[^Stepper emptyStepper].
	newSteppers := PtrArray nulls: mySteppers count.
	Int32Zero almostTo: mySteppers count do: [:i {Int32} |
		newSteppers at: i store: ((mySteppers fetch: i) cast: Stepper) copy].
	^TupleStepper create: mySpace with: myVirginSteppers with: newSteppers with: myLexOrder!

{Heaper wimpy} fetch

	^myValue!

{BooleanVar} hasValue

	^myValue ~~ NULL!

{void} step
	| stomp {Stepper of: Position} |
	myValue == NULL ifTrue: [^VOID].
	myLexOrder count -1 to: Int32Zero by: -1 do: [:i {Int32} |
		| dim {Int32} |
		dim := (myLexOrder integerAt: i) DOTasLong.
		stomp := (mySteppers fetch: dim) cast: Stepper.
		stomp step.
		stomp hasValue ifTrue:
			[self setValueFromSteppers.
			^VOID].
		mySteppers at: dim store: ((myVirginSteppers fetch: dim) cast: Stepper) copy].
	myValue := NULL! !

!TupleStepper methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySpace _ receiver receiveHeaper.
	myVirginSteppers _ receiver receiveHeaper.
	mySteppers _ receiver receiveHeaper.
	myLexOrder _ receiver receiveHeaper.
	myValue _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySpace.
	xmtr sendHeaper: myVirginSteppers.
	xmtr sendHeaper: mySteppers.
	xmtr sendHeaper: myLexOrder.
	xmtr sendHeaper: myValue.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TupleStepper class
	instanceVariableNames: ''!

(TupleStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!TupleStepper class methodsFor: 'pseudoconstructors'!

{Stepper} make: space {CrossSpace} 
	with: virginSteppers {PtrArray of: (Stepper of: Position)}
	with: lexOrder {PrimIntArray default: NULL} 
	
	| steppers {PtrArray of: (Stepper of: Position)} lexO {PrimIntArray} |
	virginSteppers count = Int32Zero ifTrue:
		[^Stepper itemStepper: (space crossOfPositions: (PtrArray nulls: Int32Zero))].
	steppers := PtrArray nulls: virginSteppers count.
	Int32Zero almostTo: virginSteppers count do: [:i {Int32} |
		| vs {Stepper of: Position} |
		vs := (virginSteppers fetch: i) cast: Stepper.
		vs hasValue ifFalse:
			[^Stepper emptyStepper].
		steppers at: i store: vs copy].
		
	lexOrder == NULL ifTrue:
		[lexO := Int32Array make: virginSteppers count.
		Int32Zero almostTo: virginSteppers count do: [:i {Int32} |
			lexO at: i storeInteger: i]]
	ifFalse:
		[lexO := lexOrder].
	^self create: space with: virginSteppers with: steppers with: lexO! !

!TupleStepper class methodsFor: 'smalltalk: defaults'!

make: space with: virginSteppers
	
	^self make: space with: virginSteppers with: NULL! !