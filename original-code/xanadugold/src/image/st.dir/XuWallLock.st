'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:21 pm'!

XuLock subclass: #XuWallLock
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
XuWallLock comment:
'A Wall cannot be opened. Sorry, dude!!!!

Clubs can have WallLockSmiths for a variety of reasons. Clubs that represent groups of users, and to which noone should be able to login directly (only as a member using loginToSuperClub), will have WallLockSmiths. Or, if you want to make a document read-only, remove all the members from its editClub, make it self-reading, and put a WallLockSmith on it; then, noone can login to the club, either directly or as a member, and noone can change it. '!

(XuWallLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWallLock methodsFor: 'promise access'!

{WallLock} getActualWallLock
	self isBroken
		ifFalse: [^super actualThing cast: WallLock.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuWallLock methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anWallLock {WallLock}
	super create: anWallLock.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuWallLock class
	instanceVariableNames: ''!

(XuWallLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWallLock class methodsFor: 'pseudo-constructors'!

make: anWallLock {WallLock}
	^self create: anWallLock!

{XuWallLock} makeBroken: problem {Problem star}
	| broke {XuWallLock} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuWallLock} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !