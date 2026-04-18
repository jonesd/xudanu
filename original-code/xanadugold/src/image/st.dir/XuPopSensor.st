'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:53 pm'!

XuPromise subclass: #XuPopSensor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(XuPopSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPopSensor methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFePopSensor {FePopSensor}
	super create: anFePopSensor.! !

!XuPopSensor methodsFor: 'promise access'!

{FePopSensor} getActualFePopSensor
	self isBroken
		ifFalse: [^super actualThing cast: FePopSensor.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuPopSensor methodsFor: 'accessing'!

{XuVoid} poppedValue: answer {XuRational} 

	"This method has no comment."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(answer isBroken) ifTrue:
		[^XuVoid makeBrokenBy: answer].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFePopSensor poppedValue: ((XuPromise getActual: answer) cast: FeRational))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuPopSensor class
	instanceVariableNames: ''!

(XuPopSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPopSensor class methodsFor: 'pseudo-constructors'!

make: anFePopSensor {FePopSensor}
	^self create: anFePopSensor!

{XuPopSensor} makeBroken: problem {Problem star}
	| broke {XuPopSensor} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuPopSensor} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !