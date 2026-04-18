'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:52 pm'!

XuPromise subclass: #XuCalcCreator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!
XuCalcCreator comment:
' '!

(XuCalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCalcCreator methodsFor: 'promise access'!

{FeCalcCreator} getActualFeCalcCreator
	self isBroken
		ifFalse: [^super actualThing cast: FeCalcCreator.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuCalcCreator methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeCalcCreator {FeCalcCreator}
	super create: anFeCalcCreator.! !

!XuCalcCreator methodsFor: 'accessing'!

{XuCalc} newCalc

	"return a new calculator"
	
	| retVal {XuCalc} |
	(self isBroken) ifTrue:
		[^XuCalc makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuCalc makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuCalc make: (self getActualFeCalcCreator newCalc)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuCalcCreator class
	instanceVariableNames: ''!

(XuCalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCalcCreator class methodsFor: 'pseudo-constructors'!

make: anFeCalcCreator {FeCalcCreator}
	^self create: anFeCalcCreator!

{XuCalcCreator} makeBroken: problem {Problem star}
	| broke {XuCalcCreator} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuCalcCreator} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !