'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:47 pm'!

Stepper subclass: #GenericCrossSimpleRegionStepper
	instanceVariableNames: '
		mySpace {CrossSpace}
		myBoxes {Stepper of: CrossRegion}
		mySimples {PtrArray of: (Stepper of: XnRegion)}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cross'!

(GenericCrossSimpleRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!GenericCrossSimpleRegionStepper methodsFor: 'operations'!

{Heaper wimpy} fetch

	| result {PtrArray} |
	self hasValue ifFalse:
		[^NULL].
	result := PtrArray nulls: mySpace axisCount.
	Int32Zero almostTo: mySpace axisCount do: [ :i {Int32} |
		result at: i store: ((mySimples get: i) cast: Stepper) get].
	^mySpace crossOfRegions: result!

{BooleanVar} hasValue

	^myBoxes hasValue!

{void} step

	| index {Int32} |
	myBoxes hasValue ifTrue: [
		index := mySpace axisCount - 1.
		[index >= Int32Zero] whileTrue:
			[ | sub {Stepper} |
			sub := (mySimples get: index) cast: Stepper.
			sub step.
			sub hasValue ifTrue:
				[self replenishSteppers: index + 1.
				^VOID].
			index := index - 1].
		myBoxes step.
		myBoxes hasValue ifTrue:
			[self replenishSteppers: Int32Zero]]! !

!GenericCrossSimpleRegionStepper methodsFor: 'private:'!

{void} replenishSteppers: index {Int32}
	"Replenish all steppers starting at index"
	
	| box {CrossRegion} |
	box := myBoxes get cast: CrossRegion.
	index almostTo: mySpace axisCount do: [ :i {Int32} |
		mySimples at: i store: (box projection: i) simpleRegions]! !

!GenericCrossSimpleRegionStepper methodsFor: 'create'!

{Stepper} copy

	| simples {PtrArray} |
	simples := PtrArray nulls: mySimples count.
	Int32Zero almostTo: simples count do: [ :i {Int32} |
		simples at: i store: ((mySimples get: i) cast: Stepper) copy].
	^GenericCrossSimpleRegionStepper create: mySpace with: myBoxes copy with: simples! !

!GenericCrossSimpleRegionStepper methodsFor: 'protected: create'!

create: space {CrossSpace} with: boxes {Stepper}

	super create.
	mySpace := space.
	myBoxes := boxes.
	boxes hasValue ifTrue:
		[mySimples := PtrArray nulls: space axisCount.
		self replenishSteppers: Int32Zero]!

create: space {CrossSpace} with: boxes {Stepper} with: simples {PtrArray}

	super create.
	mySpace := space.
	myBoxes := boxes.
	mySimples := simples.! !

!GenericCrossSimpleRegionStepper methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GenericCrossSimpleRegionStepper class
	instanceVariableNames: ''!

(GenericCrossSimpleRegionStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; add: #NOT.A.TYPE; yourself)!

!GenericCrossSimpleRegionStepper class methodsFor: 'create'!

{Stepper} make: space {CrossSpace} with: boxes {Stepper}

	^self create: space with: boxes! !