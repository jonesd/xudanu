'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:37 pm'!

Heaper subclass: #Stand.v1
	instanceVariableNames: 'myTrack {Racetrack}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-stand'!

(Stand.v1 getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Stand.v1 methodsFor: 'accessing'!

{void} printFinalResults

	| victors {ScruSet of: Racer} acc {SetAccumulator of: Racer} |
	myTrack racers stepper forEach: [:car {Racer} |
		car isWrecked
			ifTrue: [self printWreckage: car]].
	acc _ SetAccumulator make.
	myTrack racers stepper forEach: [:car {Racer} |
		car isFinished
			ifTrue: [acc step: car]].
	victors _ acc value cast: Racer.v1.
	victors count > 1
		ifTrue: [self printTie: victors].
	victors count = 1
		ifTrue: [self printVictory: victors theOne]!

{void} runARace

	[	myTrack racers stepper forEach: [:car {Racer} |
			self accelerate: car].
		myTrack tick.
		myTrack isRaceFinished
			ifTrue: [^VOID]
	] repeat!

{void} runRaces

	[	myTrack newRacer: $X.
		myTrack newRacer: $O.
		self displayMap.
		self runARace.
		self printFinalResults. 
		(self confirm: 'Play another game? ') not
			ifTrue: [^VOID].
	] repeat! !

!Stand.v1 methodsFor: 'creation'!

create

	super create.
	myTrack _ Racetrack.v1 make.! !

!Stand.v1 methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Stand.v1 class
	instanceVariableNames: ''!

(Stand.v1 getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Stand.v1 class methodsFor: 'creation'!

make

	^self create! !