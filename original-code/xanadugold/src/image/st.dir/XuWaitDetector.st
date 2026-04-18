'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:30 pm'!

XuPromise subclass: #XuWaitDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
XuWaitDetector comment:
'Will get sent a single message, once, with no parameters, when something happens. It can be passed in to Server::waitForConsequences and Server::waitForWrite.BY.PROXY '!

(XuWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWaitDetector methodsFor: 'promise access'!

{FeWaitDetector} getActualFeWaitDetector
	self isBroken
		ifFalse: [^super actualThing cast: FeWaitDetector.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuWaitDetector methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeWaitDetector {FeWaitDetector}
	super create: anFeWaitDetector.! !

!XuWaitDetector methodsFor: 'triggering'!

{XuVoid} done

	"Essential.  Whatever I was waiting for has happened"
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeWaitDetector done)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuWaitDetector class
	instanceVariableNames: ''!

(XuWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWaitDetector class methodsFor: 'pseudo-constructors'!

make: anFeWaitDetector {FeWaitDetector}
	^self create: anFeWaitDetector!

{XuWaitDetector} makeBroken: problem {Problem star}
	| broke {XuWaitDetector} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuWaitDetector} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !