'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:13 pm'!

XuPosition subclass: #XuTuple
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
XuTuple comment:
'A tuple is a Position in a CrossSpace represented by a sequence of Positions in its subSpaces'!

(XuTuple getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuTuple methodsFor: 'promise access'!

{Tuple} getActualTuple
	self isBroken
		ifFalse: [^super actualThing cast: Tuple.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuTuple methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anTuple {Tuple}
	super create: anTuple.! !

!XuTuple methodsFor: 'accessing'!

{XuPosition} coordinate: index {XuIntValue} 

	"The position with in a subspace"
	
	| retVal {XuPosition} |
	(self isBroken) ifTrue:
		[^XuPosition makeBrokenBy: self].
	(index isBroken) ifTrue:
		[^XuPosition makeBrokenBy: index].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPosition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPosition make: (self getActualTuple coordinate:index getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPtrArray} coordinates

	"Essential. An array of the coordinates in each sub space"
	
	| retVal {XuPtrArray} |
	(self isBroken) ifTrue:
		[^XuPtrArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPtrArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPtrArray make: (self getActualTuple coordinates)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuTuple class
	instanceVariableNames: ''!

(XuTuple getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuTuple class methodsFor: 'pseudo-constructors'!

make: anTuple {Tuple}
	^self create: anTuple!

{XuTuple} makeBroken: problem {Problem star}
	| broke {XuTuple} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuTuple} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !