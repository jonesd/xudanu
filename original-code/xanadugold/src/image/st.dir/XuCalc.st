'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:52 pm'!

XuPromise subclass: #XuCalc
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!
XuCalc comment:
'Class comment'!

(XuCalc getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCalc methodsFor: 'accessing'!

{XuVoid} plantPopSensor: sensor {FePopSensor} 

	"This method has no comment."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeCalc plantPopSensor: (XuPopSensor make: sensor))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRational} pop

	"pops"
	
	| retVal {XuRational} |
	(self isBroken) ifTrue:
		[^XuRational makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRational makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRational make: (self getActualFeCalc pop)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} push: rat {XuRational} 

	"pushes"
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(rat isBroken) ifTrue:
		[^XuVoid makeBrokenBy: rat].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeCalc push: ((XuPromise getActual: rat) cast: FeRational))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} times

	"This method has no comment."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeCalc times)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} timesArg: rat {XuRational} 

	"This method has no comment."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(rat isBroken) ifTrue:
		[^XuVoid makeBrokenBy: rat].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeCalc timesArg: ((XuPromise getActual: rat) cast: FeRational))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuVoid} timesCurrent

	"This method has no comment."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeCalc timesCurrent)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuCalc methodsFor: 'promise access'!

{FeCalc} getActualFeCalc
	self isBroken
		ifFalse: [^super actualThing cast: FeCalc.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuCalc methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeCalc {FeCalc}
	super create: anFeCalc.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuCalc class
	instanceVariableNames: ''!

(XuCalc getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCalc class methodsFor: 'smalltalk: initialization'!

staticTimeNonInherited

	XuRational definePromiseFluid: #XuCurrentRat with: XuPromise emulsion with: [NULL] with: #CurrentRat with: FeRational.! !

!XuCalc class methodsFor: 'pseudo-constructors'!

make: anFeCalc {FeCalc}
	^self create: anFeCalc!

{XuCalc} makeBroken: problem {Problem star}
	| broke {XuCalc} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuCalc} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !