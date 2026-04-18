'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:17 pm'!

XuArray subclass: #XuFloatArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(XuFloatArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFloatArray methodsFor: 'promise access'!

{PrimFloatArray} getActualPrimFloatArray
	self isBroken
		ifFalse: [^super actualThing cast: PrimFloatArray.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuFloatArray methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anPrimFloatArray {PrimFloatArray}
	super create: anPrimFloatArray.! !

!XuFloatArray methodsFor: 'accessing'!

{XuIntValue} bitCount

	"Return the maximum precision that can be stored in this array."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimFloatArray bitCount)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuFloatArray class
	instanceVariableNames: ''!

(XuFloatArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFloatArray class methodsFor: 'pseudo-constructors'!

make: anPrimFloatArray {PrimFloatArray}
	^self create: anPrimFloatArray!

{XuFloatArray} makeBroken: problem {Problem star}
	| broke {XuFloatArray} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuFloatArray} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !