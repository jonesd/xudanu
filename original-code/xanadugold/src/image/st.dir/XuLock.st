'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:19 pm'!

XuPromise subclass: #XuLock
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
XuLock comment:
'To login to a club, you ask the server for a Lock. If you send the right message to the Lock, it will return you a new KeyMaster with the authority of the club. Each subclass of Lock defines its own protocol for opening. 

For each kind of Lock, there is a corresponding kind of LockSmith which creates it. Each ClubManager has a LockSmith sub-document, and when you ask the server for a Lock to that club, it asks the club`s LockSmith document Wrapper to create a newLock. The LockSmith then creates the corresponding kind of Lock. It may also use information stored in the LockSmith document, such as a password or scramblerName.'!

(XuLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuLock methodsFor: 'promise access'!

{Lock} getActualLock
	self isBroken
		ifFalse: [^super actualThing cast: Lock.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuLock methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anLock {Lock}
	super create: anLock.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuLock class
	instanceVariableNames: ''!

(XuLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuLock class methodsFor: 'pseudo-constructors'!

make: anLock {Lock}
	^self create: anLock!

{XuLock} makeBroken: problem {Problem star}
	| broke {XuLock} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuLock} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !