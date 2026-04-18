'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:41 pm'!

XuLockSmith subclass: #XuChallengeLockSmith
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
XuChallengeLockSmith comment:
'Makes ChallengeLocks; see the comment there'!

(XuChallengeLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuChallengeLockSmith methodsFor: 'accessing'!

{XuIntArray} encrypterName

	"The type of encrypter used to create encrypted challenges."
	
	| retVal {XuIntArray} |
	(self isBroken) ifTrue:
		[^XuIntArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntArray make: (self getActualFeChallengeLockSmith encrypterName)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntArray} publicKey

	"The public key used to construct challenges."
	
	| retVal {XuIntArray} |
	(self isBroken) ifTrue:
		[^XuIntArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntArray make: (self getActualFeChallengeLockSmith publicKey)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuChallengeLockSmith methodsFor: 'promise access'!

{FeChallengeLockSmith} getActualFeChallengeLockSmith
	self isBroken
		ifFalse: [^super actualThing cast: FeChallengeLockSmith.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuChallengeLockSmith methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeChallengeLockSmith {FeChallengeLockSmith}
	super create: anFeChallengeLockSmith.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuChallengeLockSmith class
	instanceVariableNames: ''!

(XuChallengeLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuChallengeLockSmith class methodsFor: 'pseudo-constructors'!

make: anFeChallengeLockSmith {FeChallengeLockSmith}
	^self create: anFeChallengeLockSmith!

{XuChallengeLockSmith} makeBroken: problem {Problem star}
	| broke {XuChallengeLockSmith} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuChallengeLockSmith} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !