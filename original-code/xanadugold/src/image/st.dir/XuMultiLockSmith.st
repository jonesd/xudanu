'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:42 pm'!

XuLockSmith subclass: #XuMultiLockSmith
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
XuMultiLockSmith comment:
'Makes MultiLocks; see the comment there'!

(XuMultiLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMultiLockSmith methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeMultiLockSmith {FeMultiLockSmith}
	super create: anFeMultiLockSmith.! !

!XuMultiLockSmith methodsFor: 'promise access'!

{FeMultiLockSmith} getActualFeMultiLockSmith
	self isBroken
		ifFalse: [^super actualThing cast: FeMultiLockSmith.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuMultiLockSmith methodsFor: 'accessing'!

{XuLockSmith} lockSmith: name {XuSequence} 

	"The named LockSmith"
	
	| retVal {XuLockSmith} |
	(self isBroken) ifTrue:
		[^XuLockSmith makeBrokenBy: self].
	(name isBroken) ifTrue:
		[^XuLockSmith makeBrokenBy: name].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuLockSmith makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuLockSmith make: (self getActualFeMultiLockSmith lockSmith: ((XuPromise getActual: name) cast: Sequence))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequenceRegion} lockSmithNames

	"The names of all the Locksmiths this uses."
	
	| retVal {XuSequenceRegion} |
	(self isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequenceRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequenceRegion make: (self getActualFeMultiLockSmith lockSmithNames)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMultiLockSmith} with: name {XuSequence} with: smith {XuLockSmith} 

	"Add or change a LockSmith"
	
	| retVal {XuMultiLockSmith} |
	(self isBroken) ifTrue:
		[^XuMultiLockSmith makeBrokenBy: self].
	(name isBroken) ifTrue:
		[^XuMultiLockSmith makeBrokenBy: name].
	(smith isBroken) ifTrue:
		[^XuMultiLockSmith makeBrokenBy: smith].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMultiLockSmith makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMultiLockSmith make: (self getActualFeMultiLockSmith with: ((XuPromise getActual: name) cast: Sequence) with: ((XuPromise getActual: smith) cast: FeLockSmith))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMultiLockSmith} without: name {XuSequence} 

	"Add or change a LockSmith"
	
	| retVal {XuMultiLockSmith} |
	(self isBroken) ifTrue:
		[^XuMultiLockSmith makeBrokenBy: self].
	(name isBroken) ifTrue:
		[^XuMultiLockSmith makeBrokenBy: name].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMultiLockSmith makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMultiLockSmith make: (self getActualFeMultiLockSmith without: ((XuPromise getActual: name) cast: Sequence))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuMultiLockSmith class
	instanceVariableNames: ''!

(XuMultiLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMultiLockSmith class methodsFor: 'pseudo-constructors'!

make: anFeMultiLockSmith {FeMultiLockSmith}
	^self create: anFeMultiLockSmith!

{XuMultiLockSmith} makeBroken: problem {Problem star}
	| broke {XuMultiLockSmith} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuMultiLockSmith} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !