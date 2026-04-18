'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:53 pm'!

XuPromise subclass: #XuRational
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(XuRational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRational methodsFor: 'promise access'!

{FeRational} getActualFeRational
	self isBroken
		ifFalse: [^super actualThing cast: FeRational.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuRational methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeRational {FeRational}
	super create: anFeRational.! !

!XuRational methodsFor: 'accessing'!

{XuPromise} asHeaper

	"This method has no comment."
	
	| retVal {XuPromise} |
	(self isBroken) ifTrue:
		[^XuPromise makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPromise makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPromise make: (self getActualFeRational asHeaper)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} denominator

	"This method has no comment."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeRational denominator)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} numerator

	"This method has no comment."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeRational numerator)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuRational class
	instanceVariableNames: ''!

(XuRational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRational class methodsFor: 'pseudo-constructors'!

make: anFeRational {FeRational}
	^self create: anFeRational!

{XuRational} makeBroken: problem {Problem star}
	| broke {XuRational} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuRational} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !