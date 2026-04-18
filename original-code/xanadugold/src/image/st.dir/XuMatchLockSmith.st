'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:42 pm'!

XuLockSmith subclass: #XuMatchLockSmith
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
XuMatchLockSmith comment:
'Makes MatchLocks; see the comment there'!

(XuMatchLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMatchLockSmith methodsFor: 'promise access'!

{FeMatchLockSmith} getActualFeMatchLockSmith
	self isBroken
		ifFalse: [^super actualThing cast: FeMatchLockSmith.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuMatchLockSmith methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeMatchLockSmith {FeMatchLockSmith}
	super create: anFeMatchLockSmith.! !

!XuMatchLockSmith methodsFor: 'accessing'!

{XuIntArray} scrambledPassword

	"The password in scrambled form. If the scrambler is any good, this should be meaningless."
	
	| retVal {XuIntArray} |
	(self isBroken) ifTrue:
		[^XuIntArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntArray make: (self getActualFeMatchLockSmith scrambledPassword)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntArray} scramblerName

	"The name of scrambler being used to scramble the password."
	
	| retVal {XuIntArray} |
	(self isBroken) ifTrue:
		[^XuIntArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntArray make: (self getActualFeMatchLockSmith scramblerName)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuMatchLockSmith class
	instanceVariableNames: ''!

(XuMatchLockSmith getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMatchLockSmith class methodsFor: 'pseudo-constructors'!

make: anFeMatchLockSmith {FeMatchLockSmith}
	^self create: anFeMatchLockSmith!

{XuMatchLockSmith} makeBroken: problem {Problem star}
	| broke {XuMatchLockSmith} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuMatchLockSmith} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !