'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:11 pm'!

XuBundle subclass: #XuArrayBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuArrayBundle comment:
'Describes a chunk of information represented as an array. The number of elements in the array are the same as my region, and they are ordered according to OrderSpec given to the retrieve operation which produced me.'!

(XuArrayBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuArrayBundle methodsFor: 'promise access'!

{FeArrayBundle} getActualFeArrayBundle
	self isBroken
		ifFalse: [^super actualThing cast: FeArrayBundle.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuArrayBundle methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeArrayBundle {FeArrayBundle}
	super create: anFeArrayBundle.! !

!XuArrayBundle methodsFor: 'accessing'!

{XuArray} array

	"Essential. The array of elements in this bundle"
	
	| retVal {XuArray} |
	(self isBroken) ifTrue:
		[^XuArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuArray make: (self getActualFeArrayBundle array)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuOrderSpec} ordering

	"Essential. The order relating the elements in the array to the positions in the region."
	
	| retVal {XuOrderSpec} |
	(self isBroken) ifTrue:
		[^XuOrderSpec makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuOrderSpec makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuOrderSpec make: (self getActualFeArrayBundle ordering)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuArrayBundle class
	instanceVariableNames: ''!

(XuArrayBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuArrayBundle class methodsFor: 'pseudo-constructors'!

make: anFeArrayBundle {FeArrayBundle}
	^self create: anFeArrayBundle!

{XuArrayBundle} makeBroken: problem {Problem star}
	| broke {XuArrayBundle} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuArrayBundle} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !