'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:26 pm'!

XuPromise subclass: #XuWrapper
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
XuWrapper comment:
'An object which wraps an Edition, providing additional functionality for manipulating it and enforcing invariants on the format.

Implementation note:

The fact that you cannot get the spec of a Wrapper is deliberate. You can merely check that it is a kind of Edition you know, but no more; this makes it easy to compatibly add new leaf classes below existing ones.'!

(XuWrapper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWrapper methodsFor: 'promise access'!

{FeWrapper} getActualFeWrapper
	self isBroken
		ifFalse: [^super actualThing cast: FeWrapper.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuWrapper methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeWrapper {FeWrapper}
	super create: anFeWrapper.! !

!XuWrapper methodsFor: 'accessing'!

{XuEdition} edition

	"Essential. The primitive Edition this is wrapping."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeWrapper edition)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuWrapper} inner

	"Essential. The next Wrapper inside this one; blasts if this wraps an Edition directly."
	
	| retVal {XuWrapper} |
	(self isBroken) ifTrue:
		[^XuWrapper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuWrapper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuWrapper make: (self getActualFeWrapper inner)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuWrapper class
	instanceVariableNames: ''!

(XuWrapper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWrapper class methodsFor: 'pseudo-constructors'!

make: anFeWrapper {FeWrapper}
	^self create: anFeWrapper!

{XuWrapper} makeBroken: problem {Problem star}
	| broke {XuWrapper} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuWrapper} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !