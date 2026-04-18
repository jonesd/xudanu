'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:20 pm'!

XuLock subclass: #XuMultiLock
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
XuMultiLock comment:
'A MultiLock allows the client to open the lock with any of a list of Locks. This allows a Club to have different passwords for different people; or, the Locks can use different kinds of native authentication systems such as NIS or Kerberos.'!

(XuMultiLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMultiLock methodsFor: 'promise access'!

{MultiLock} getActualMultiLock
	self isBroken
		ifFalse: [^super actualThing cast: MultiLock.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuMultiLock methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anMultiLock {MultiLock}
	super create: anMultiLock.! !

!XuMultiLock methodsFor: 'accessing'!

{XuLock} lock: name {XuSequence} 

	"Get the named lock. You don't get any authority through a MultiLock directly, you merely get a Lock from which you can get authority."
	
	| retVal {XuLock} |
	(self isBroken) ifTrue:
		[^XuLock makeBrokenBy: self].
	(name isBroken) ifTrue:
		[^XuLock makeBrokenBy: name].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuLock makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuLock make: (self getActualMultiLock lock: ((XuPromise getActual: name) cast: Sequence))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequenceRegion} lockNames

	"Essential. The names identifying the locks in the list"
	
	| retVal {XuSequenceRegion} |
	(self isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequenceRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequenceRegion make: (self getActualMultiLock lockNames)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuMultiLock class
	instanceVariableNames: ''!

(XuMultiLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMultiLock class methodsFor: 'pseudo-constructors'!

make: anMultiLock {MultiLock}
	^self create: anMultiLock!

{XuMultiLock} makeBroken: problem {Problem star}
	| broke {XuMultiLock} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuMultiLock} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !