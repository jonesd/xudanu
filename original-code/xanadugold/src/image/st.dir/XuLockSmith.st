'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:42 pm'!

XuWrapper subclass: #XuLockSmith
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
XuLockSmith comment:
'Describes how to obtain the authority of a Club.'!

(XuLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuLockSmith methodsFor: 'promise access'!

{FeLockSmith} getActualFeLockSmith
	self isBroken
		ifFalse: [^super actualThing cast: FeLockSmith.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuLockSmith methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeLockSmith {FeLockSmith}
	super create: anFeLockSmith.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuLockSmith class
	instanceVariableNames: ''!

(XuLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuLockSmith class methodsFor: 'pseudo-constructors'!

make: anFeLockSmith {FeLockSmith}
	^self create: anFeLockSmith!

{XuLockSmith} makeBroken: problem {Problem star}
	| broke {XuLockSmith} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuLockSmith} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !