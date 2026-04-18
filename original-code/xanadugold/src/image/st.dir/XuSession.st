'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:43 pm'!

XuPromise subclass: #XuSession
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nadmin'!
XuSession comment:
'Represent a single unique connection to the server over some underlying bytestream channel.'!

(XuSession getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSession methodsFor: 'promise access'!

{FeSession} getActualFeSession
	self isBroken
		ifFalse: [^super actualThing cast: FeSession.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuSession methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeSession {FeSession}
	super create: anFeSession.! !

!XuSession methodsFor: 'accessing'!

{XuIntValue} connectTime

	"Essential. The clock time at which the connection was initiated."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeSession connectTime)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} endSession: withPrejudice {XuIntValue default: DefaultFalse} 

	"Essential. Terminate this connection.  If withPrejudice is false, it completes the current request and flushes all output before disconnecting."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(withPrejudice isBroken) ifTrue:
		[^XuVoid makeBrokenBy: withPrejudice].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeSession endSession:withPrejudice getActualBooleanVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuID} initialLogin

	"Essential. The ID of the club that the session logged into to get past the perimeter.  Blast of the session is not yet admitted."
	
	| retVal {XuID} |
	(self isBroken) ifTrue:
		[^XuID makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuID makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuID make: (self getActualFeSession initialLogin)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isConnected

	"Return whether the session has sucessfully logged in, and is still logged in."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeSession isConnected)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntArray} port

	"Essential. A system-specific description of the actual transport medium over which the connection is being maintained."
	
	| retVal {XuIntArray} |
	(self isBroken) ifTrue:
		[^XuIntArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntArray make: (self getActualFeSession port)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuSession methodsFor: 'smalltalk: defaults'!

{XuVoid} endSession

	"Essential. Gracefully terminate this connection"
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeSession endSession)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuSession class
	instanceVariableNames: ''!

(XuSession getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSession class methodsFor: 'pseudo-constructors'!

make: anFeSession {FeSession}
	^self create: anFeSession!

{XuSession} makeBroken: problem {Problem star}
	| broke {XuSession} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuSession} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !