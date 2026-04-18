'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:20 pm'!

XuLock subclass: #XuMatchLock
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Locks'!
XuMatchLock comment:
'The correct password will open the lock. The password is actually stored in the club`s MatchLockSmith in scrambled form, using a Scrambler identified by scramblerName(). The scrambled cleartext supplied as a password is compared to the scrambledPassword in the MatchLockSmith. If they match, the lock is opened. 

The actual process is a bit more complicated than this. The user supplies a password in clear, which is encrypted with the current system public key and then sent to the server. There, it is first decrypted with the private key known only to the server. It is then scrambled and compared with the scrambled password stored in the MatchLockSmith of the club. This procedure both avoids sending passwords in clear over the network, and also allows the MatchLockSmith to be made readable without compromising security.'!

(XuMatchLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMatchLock methodsFor: 'promise access'!

{MatchLock} getActualMatchLock
	self isBroken
		ifFalse: [^super actualThing cast: MatchLock.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuMatchLock methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anMatchLock {MatchLock}
	super create: anMatchLock.! !

!XuMatchLock methodsFor: 'accessing'!

{XuKeyMaster} encryptedPassword: encrypted {XuIntArray} 

	"Send the encrypted password to the server to be checked.
	NOTE: (for protocol review) The password must have been encrypted using a (yet-to-be-defined) front end library function, since this sort of front end computation can't be done with Promises."
	
	| retVal {XuKeyMaster} |
	(self isBroken) ifTrue:
		[^XuKeyMaster makeBrokenBy: self].
	(encrypted isBroken) ifTrue:
		[^XuKeyMaster makeBrokenBy: encrypted].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuKeyMaster makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuKeyMaster make: (self getActualMatchLock encryptedPassword: ((XuPromise getActual: encrypted) cast: PrimIntArray))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuMatchLock class
	instanceVariableNames: ''!

(XuMatchLock getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMatchLock class methodsFor: 'pseudo-constructors'!

make: anMatchLock {MatchLock}
	^self create: anMatchLock!

{XuMatchLock} makeBroken: problem {Problem star}
	| broke {XuMatchLock} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuMatchLock} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !