'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:41 pm'!

XuWrapper subclass: #XuClubDescription
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
XuClubDescription comment:
'Describes the state of Club -- who is in it, which Work is its home (if it has one), and how you can login to it'!

(XuClubDescription getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuClubDescription methodsFor: 'accessing'!

{XuLockSmith} lockSmith

	"Describes how authority for this Club is gained"
	
	| retVal {XuLockSmith} |
	(self isBroken) ifTrue:
		[^XuLockSmith makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuLockSmith makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuLockSmith make: (self getActualFeClubDescription lockSmith)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSet} membership

	"The Clubs which are members of this one."
	
	| retVal {XuSet} |
	(self isBroken) ifTrue:
		[^XuSet makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSet makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSet make: (self getActualFeClubDescription membership)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuClubDescription} withLockSmith: lockSmith {XuLockSmith} 

	"Change how authority is gained"
	
	| retVal {XuClubDescription} |
	(self isBroken) ifTrue:
		[^XuClubDescription makeBrokenBy: self].
	(lockSmith isBroken) ifTrue:
		[^XuClubDescription makeBrokenBy: lockSmith].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuClubDescription makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuClubDescription make: (self getActualFeClubDescription withLockSmith: ((XuPromise getActual: lockSmith) cast: FeLockSmith))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuClubDescription} withMembership: members {XuSet} 

	"Change the entire membership list"
	
	| retVal {XuClubDescription} |
	(self isBroken) ifTrue:
		[^XuClubDescription makeBrokenBy: self].
	(members isBroken) ifTrue:
		[^XuClubDescription makeBrokenBy: members].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuClubDescription makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuClubDescription make: (self getActualFeClubDescription withMembership: ((XuPromise getActual: members) cast: FeSet))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuClubDescription methodsFor: 'promise access'!

{FeClubDescription} getActualFeClubDescription
	self isBroken
		ifFalse: [^super actualThing cast: FeClubDescription.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuClubDescription methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeClubDescription {FeClubDescription}
	super create: anFeClubDescription.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuClubDescription class
	instanceVariableNames: ''!

(XuClubDescription getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuClubDescription class methodsFor: 'pseudo-constructors'!

make: anFeClubDescription {FeClubDescription}
	^self create: anFeClubDescription!

{XuClubDescription} makeBroken: problem {Problem star}
	| broke {XuClubDescription} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuClubDescription} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !