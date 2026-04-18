'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:19 pm'!

XuLock subclass: #XuChallengeLock
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
XuChallengeLock comment:
'A ChallengeLock challenges the client with a random piece of data that has been encrypted with a publicKey, using an algorithm identified by the encrypterName. The client must decrypt it using the corresponding private key and respond with the decrypted challenge. If it matches the original random data, then the lock will open. The encrypterName and the publicKey are stored in the club`s ChallengeLockSmith. '!

(XuChallengeLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuChallengeLock methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anChallengeLock {ChallengeLock}
	super create: anChallengeLock.! !

!XuChallengeLock methodsFor: 'promise access'!

{ChallengeLock} getActualChallengeLock
	self isBroken
		ifFalse: [^super actualThing cast: ChallengeLock.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuChallengeLock methodsFor: 'accessing'!

{XuIntArray} challenge

	"Essential.  The challenge which must be signed correctly to open the lock."
	
	| retVal {XuIntArray} |
	(self isBroken) ifTrue:
		[^XuIntArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntArray make: (self getActualChallengeLock challenge)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuKeyMaster} response: signedChallenge {XuIntArray} 

	"Essential.  The correctly signed challenge will open the lock."
	
	| retVal {XuKeyMaster} |
	(self isBroken) ifTrue:
		[^XuKeyMaster makeBrokenBy: self].
	(signedChallenge isBroken) ifTrue:
		[^XuKeyMaster makeBrokenBy: signedChallenge].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuKeyMaster makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuKeyMaster make: (self getActualChallengeLock response: ((XuPromise getActual: signedChallenge) cast: PrimIntArray))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuChallengeLock class
	instanceVariableNames: ''!

(XuChallengeLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuChallengeLock class methodsFor: 'pseudo-constructors'!

make: anChallengeLock {ChallengeLock}
	^self create: anChallengeLock!

{XuChallengeLock} makeBroken: problem {Problem star}
	| broke {XuChallengeLock} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuChallengeLock} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !