'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:19 pm'!

XuPromise subclass: #XuValue
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!
XuValue comment:
'A boxed representation of a primitive data type'!

(XuValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuValue methodsFor: 'creation'!

create
"foo bar"
	super create.!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anPrimValue {PrimValue}
	super create: anPrimValue.! !

!XuValue methodsFor: 'promise access'!

{PrimValue} getActualPrimValue
	self isBroken
		ifFalse: [^super actualThing cast: PrimValue.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuValue class
	instanceVariableNames: ''!

(XuValue getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuValue class methodsFor: 'pseudo-constructors'!

make: anPrimValue {PrimValue}
	^self create: anPrimValue!

{XuValue} makeBroken: problem {Problem star}
	| broke {XuValue} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuValue} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !

!XuValue class methodsFor: 'smalltalk: testing'!

{Boolean} isNotGenerated
	^ true! !