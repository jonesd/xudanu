'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:43 pm'!

XuLockSmith subclass: #XuWallLockSmith
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
XuWallLockSmith comment:
'Makes WallLocks; see the comment there'!

(XuWallLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWallLockSmith methodsFor: 'promise access'!

{FeWallLockSmith} getActualFeWallLockSmith
	self isBroken
		ifFalse: [^super actualThing cast: FeWallLockSmith.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuWallLockSmith methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeWallLockSmith {FeWallLockSmith}
	super create: anFeWallLockSmith.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuWallLockSmith class
	instanceVariableNames: ''!

(XuWallLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWallLockSmith class methodsFor: 'pseudo-constructors'!

make: anFeWallLockSmith {FeWallLockSmith}
	^self create: anFeWallLockSmith!

{XuWallLockSmith} makeBroken: problem {Problem star}
	| broke {XuWallLockSmith} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuWallLockSmith} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !