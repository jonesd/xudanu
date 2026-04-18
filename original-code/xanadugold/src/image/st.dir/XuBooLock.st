'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:19 pm'!

XuLock subclass: #XuBooLock
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
XuBooLock comment:
'A BooLock is very easy to open. Just say "boo". 

Since anyone can get in, only public clubs with little authority, such as System Public, should have BooLockSmiths.'!

(XuBooLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuBooLock methodsFor: 'promise access'!

{BooLock} getActualBooLock
	self isBroken
		ifFalse: [^super actualThing cast: BooLock.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuBooLock methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anBooLock {BooLock}
	super create: anBooLock.! !

!XuBooLock methodsFor: 'accessing'!

{XuKeyMaster} boo

	"Essential.  This is a very easy lock to open. Just say `boo'."
	
	| retVal {XuKeyMaster} |
	(self isBroken) ifTrue:
		[^XuKeyMaster makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuKeyMaster makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuKeyMaster make: (self getActualBooLock boo)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuBooLock class
	instanceVariableNames: ''!

(XuBooLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuBooLock class methodsFor: 'pseudo-constructors'!

make: anBooLock {BooLock}
	^self create: anBooLock!

{XuBooLock} makeBroken: problem {Problem star}
	| broke {XuBooLock} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuBooLock} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !