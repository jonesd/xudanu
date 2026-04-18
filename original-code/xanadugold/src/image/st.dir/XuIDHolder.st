'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:15 pm'!

XuRangeElement subclass: #XuIDHolder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuIDHolder comment:
'An object for having an ID in the range of an Edition. Tentative feature.'!

(XuIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIDHolder methodsFor: 'promise access'!

{FeIDHolder} getActualFeIDHolder
	self isBroken
		ifFalse: [^super actualThing cast: FeIDHolder.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuIDHolder methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeIDHolder {FeIDHolder}
	super create: anFeIDHolder.! !

!XuIDHolder methodsFor: 'accessing'!

{XuID} iD

	"Essential.  The ID in this holder."
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeIDHolder iD)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuIDHolder class
	instanceVariableNames: ''!

(XuIDHolder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIDHolder class methodsFor: 'pseudo-constructors'!

make: anFeIDHolder {FeIDHolder}
	^self create: anFeIDHolder!

{XuIDHolder} makeBroken: problem {Problem star}
	| broke {XuIDHolder} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuIDHolder} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !