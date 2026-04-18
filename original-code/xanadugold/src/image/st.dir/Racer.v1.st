'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:37 pm'!

Heaper subclass: #Racer.v1
	instanceVariableNames: '
		myTrack {Racetrack}
		myName {Character}
		myPlace {Position}
		myVelocity {Dsp}
		myHasWrecked {BooleanVar}
		myHasFinished {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-track'!

(Racer.v1 getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!Racer.v1 methodsFor: 'accessing'!

{void} accelerate: delta {Dsp}

	myVelocity _ myVelocity compose: delta!

{BooleanVar} isFinished

	^myHasFinished!

{BooleanVar} isWrecked

	^myHasWrecked!

{void} moveRacer

	| destination {Position} |
	destination _ myVelocity of: myPlace. 
	(Bresenham make: myPlace with: destination) forEach: [:pos {Position} |
		myPlace _ pos.
		self hack. "should react"
		myHasFinished _ myTrack finishLine hasMember: myPlace.
		self hack. "should react"
		myHasWrecked _ myTrack fence hasMember: myPlace.
		self hack. "should react"
		(myHasFinished or: [myHasWrecked])
			ifTrue: [^VOID]]!

{Character} name

	^myName!

{Position} place

	^myPlace!

{Dsp} velocity

	^myVelocity! !

!Racer.v1 methodsFor: 'creation'!

create: track {Racetrack} with: carName {Character}

	super create.
	myTrack _ track.
	myName _ carName.
	myPlace _ PointPos make.
	myVelocity _ PointTranslateDsp make.
	myHasWrecked _ false.
	myHasFinished _ false.! !

!Racer.v1 methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !