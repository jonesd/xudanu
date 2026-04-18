'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:18 pm'!

XuArray subclass: #XuIntArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
XuIntArray comment:
'A common superclass for primitive arrays of integral types'!

(XuIntArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntArray methodsFor: 'promise access'!

{PrimIntArray} getActualPrimIntArray
	self isBroken
		ifFalse: [^super actualThing cast: PrimIntArray.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuIntArray methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anPrimIntArray {PrimIntArray}
	super create: anPrimIntArray.! !

!XuIntArray methodsFor: 'accessing'!

{XuIntValue} bitCount

	"Return the maximum precision that can be stored in this array.  The number will be negative for Signed arrays."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualPrimIntArray bitCount)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuIntArray class
	instanceVariableNames: ''!

(XuIntArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntArray class methodsFor: 'pseudo-constructors'!

make: anPrimIntArray {PrimIntArray}
	^self create: anPrimIntArray!

{XuIntArray} makeBroken: problem {Problem star}
	| broke {XuIntArray} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuIntArray} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !