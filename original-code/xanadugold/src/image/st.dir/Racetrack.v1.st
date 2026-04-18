'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:37 pm'!

Heaper subclass: #Racetrack.v1
	instanceVariableNames: '
		myRacers {MuSet of: Racer}
		myFence {XnRegion}
		myFinishLine {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-track'!

(Racetrack.v1 getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Racetrack.v1 methodsFor: 'creation'!

create

	super create.
	myRacers _ MuSet make.
	myFence _ PointRegion make.
	myFinishLine _ PointRegion make! !

!Racetrack.v1 methodsFor: 'accessing'!

{XnRegion} fence
	
	^myFence!

{XnRegion} finishLine
	
	^myFinishLine!

{BooleanVar} isRaceFinished
	"Race is finished if any racer has finished or no more than one racer hasn't wrecked"

	| unwrecked {IntegerVar} |
	unwrecked _ IntegerVar0.
	myRacers stepper forEach: [:car {Racer} |
		car isFinished
			ifTrue: [^true].
		car isWrecked not
			ifTrue: [unwrecked _ unwrecked + 1]].
	^unwrecked <= 1!

{Racer} newRacer: name {Character}

	| result {Racer} |
	result _ Racer.v1 create: self with: name.
	myRacers store: result.
	^result!

{ImmuSet of: Racer} racers

	^myRacers asImmuSet!

{void} tick

	myRacers stepper forEach: [:racer {Racer} |
		racer moveRacer]! !

!Racetrack.v1 methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Racetrack.v1 class
	instanceVariableNames: ''!

(Racetrack.v1 getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Racetrack.v1 class methodsFor: 'creation'!

make

	^self create! !