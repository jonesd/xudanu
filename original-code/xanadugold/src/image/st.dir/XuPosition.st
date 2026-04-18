'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:00 pm'!

XuPromise subclass: #XuPosition
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!
XuPosition comment:
'This is the superclass of all positions of coordinate spaces.  Each individual position is specific to some one coordinate space.  Positions themselves don''t have much behavior, as most of the interesting aspects of coordinate spaces are defined in the other objects in terms of positions.  Positions do have their own native ordering messages, but for most purposes it''s probably better to compare them using an appropriate OrderSpec.'!

(XuPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPosition methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anPosition {Position}
	super create: anPosition.! !

!XuPosition methodsFor: 'accessing'!

{XuRegion} asRegion

	"Essential.  A region containing this position as its only element."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualPosition asRegion)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuCoordinateSpace} coordinateSpace

	"Essential.  The coordinate space this is a position in. This implies that a position object is only a position in one particular coordinate space."
	
	| retVal {XuCoordinateSpace} |
	(self isBroken) ifTrue:
		[^XuCoordinateSpace makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCoordinateSpace makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCoordinateSpace make: (self getActualPosition coordinateSpace)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuPosition methodsFor: 'promise access'!

{Position} getActualPosition
	self isBroken
		ifFalse: [^super actualThing cast: Position.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuPosition class
	instanceVariableNames: ''!

(XuPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPosition class methodsFor: 'pseudo-constructors'!

make: anPosition {Position}
	^self create: anPosition!

{XuPosition} makeBroken: problem {Problem star}
	| broke {XuPosition} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuPosition} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !