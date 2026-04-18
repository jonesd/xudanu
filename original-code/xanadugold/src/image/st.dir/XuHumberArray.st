'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:17 pm'!

XuArray subclass: #XuHumberArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(XuHumberArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuHumberArray methodsFor: 'promise access'!

{IntegerVarArray} getActualIntegerVarArray
	self isBroken
		ifFalse: [^super actualThing cast: IntegerVarArray.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuHumberArray methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anIntegerVarArray {IntegerVarArray}
	super create: anIntegerVarArray.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuHumberArray class
	instanceVariableNames: ''!

(XuHumberArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuHumberArray class methodsFor: 'pseudo-constructors'!

make: anIntegerVarArray {IntegerVarArray}
	^self create: anIntegerVarArray!

{XuHumberArray} makeBroken: problem {Problem star}
	| broke {XuHumberArray} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuHumberArray} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !