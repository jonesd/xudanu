'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:19 pm'!

XuArray subclass: #XuPtrArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(XuPtrArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPtrArray methodsFor: 'promise access'!

{PtrArray} getActualPtrArray
	self isBroken
		ifFalse: [^super actualThing cast: PtrArray.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuPtrArray methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anPtrArray {PtrArray}
	super create: anPtrArray.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuPtrArray class
	instanceVariableNames: ''!

(XuPtrArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPtrArray class methodsFor: 'pseudo-constructors'!

make: anPtrArray {PtrArray}
	^self create: anPtrArray!

{XuPtrArray} makeBroken: problem {Problem star}
	| broke {XuPtrArray} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuPtrArray} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !