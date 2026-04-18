'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:41 pm'!

XuLockSmith subclass: #XuBooLockSmith
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
XuBooLockSmith comment:
'Makes BooLocks; see the comment there'!

(XuBooLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuBooLockSmith methodsFor: 'promise access'!

{FeBooLockSmith} getActualFeBooLockSmith
	self isBroken
		ifFalse: [^super actualThing cast: FeBooLockSmith.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuBooLockSmith methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeBooLockSmith {FeBooLockSmith}
	super create: anFeBooLockSmith.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuBooLockSmith class
	instanceVariableNames: ''!

(XuBooLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuBooLockSmith class methodsFor: 'pseudo-constructors'!

make: anFeBooLockSmith {FeBooLockSmith}
	^self create: anFeBooLockSmith!

{XuBooLockSmith} makeBroken: problem {Problem star}
	| broke {XuBooLockSmith} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuBooLockSmith} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !