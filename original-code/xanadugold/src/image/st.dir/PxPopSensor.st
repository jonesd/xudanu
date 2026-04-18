'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:47 pm'!

XuPromise subclass: #PxPopSensor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-sensor'!

(PxPopSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PxPopSensor methodsFor: 'promise access'!

{FePopSensor} getActualFePopSensor

	self isBroken ifFalse: [
		^myActualThing cast: FePopSensor.]
	ifTrue: [
		Heaper BLAST: #BrokenPromise].! !

!PxPopSensor methodsFor: 'creation'!

create: anFePopSensor {FePopSensor}

	super create.
	myActualThing _ anFePopSensor.! !

!PxPopSensor methodsFor: 'accessing'!

{PrVoid} poppedValue: answer {PrRational} 

	| retVal {PrVoid} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrVoid makeBroken: ex]
		do: 	[retVal _ PrVoid make: (self getActualFePopSensor poppedValue: (answer getActualFeRational ))].
	Promise inDelayBlock ifFalse: [
		Promise force.
		retVal isBroken ifTrue: [
			retVal explode]]
	ifTrue: [
		retVal isBroken ifTrue: [
			(retVal problemName contentsEqual: (UInt8Array string: 'BrokenPromise')) ifFalse: [
				Promise savePromise: retVal]]].
	^retVal.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PxPopSensor class
	instanceVariableNames: ''!

(PxPopSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PxPopSensor class methodsFor: 'pseudo-constructors'!

make: anFePopSensor {FePopSensor}

	^self create: anFePopSensor!

makeBroken: problem {Problem star}

	^self create.Problem: problem.! !