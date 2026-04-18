'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:05 pm'!

XuPromise subclass: #PxCalc
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fecalc'!

(PxCalc getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PxCalc methodsFor: 'promise access'!

{FeCalc} getActualFeCalc

	self isBroken ifFalse: [
		^myActualThing cast: FeCalc.]
	ifTrue: [
		Heaper BLAST: #BrokenPromise].! !

!PxCalc methodsFor: 'creation'!

create: anFeCalc {FeCalc}

	super create.
	myActualThing _ anFeCalc.! !

!PxCalc methodsFor: 'accessing'!

{PrVoid} plantPopSensor: sensor {FePopSensor} 

	| retVal {PrVoid} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrVoid makeBroken: ex]
		do: 	[retVal _ PrVoid make: (self getActualFeCalc plantPopSensor: (PrPopSensor make: sensor))].
	Promise inDelayBlock ifFalse: [
		Promise force.
		retVal isBroken ifTrue: [
			retVal explode]]
	ifTrue: [
		retVal isBroken ifTrue: [
			(retVal problemName contentsEqual: (UInt8Array string: 'BrokenPromise')) ifFalse: [
				Promise savePromise: retVal]]].
	^retVal.!

{PrRational} pop

	| retVal {PrRational} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrRational makeBroken: ex]
		do: 	[retVal _ PrRational make: (self getActualFeCalc pop)].
	Promise inDelayBlock ifFalse: [
		Promise force.
		retVal isBroken ifTrue: [
			retVal explode]]
	ifTrue: [
		retVal isBroken ifTrue: [
			(retVal problemName contentsEqual: (UInt8Array string: 'BrokenPromise')) ifFalse: [
				Promise savePromise: retVal]]].
	^retVal.!

{PrVoid} push: rat {PrRational} 

	| retVal {PrVoid} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrVoid makeBroken: ex]
		do: 	[retVal _ PrVoid make: (self getActualFeCalc push: (rat getActualFeRational ))].
	Promise inDelayBlock ifFalse: [
		Promise force.
		retVal isBroken ifTrue: [
			retVal explode]]
	ifTrue: [
		retVal isBroken ifTrue: [
			(retVal problemName contentsEqual: (UInt8Array string: 'BrokenPromise')) ifFalse: [
				Promise savePromise: retVal]]].
	^retVal.!

{PrVoid} times

	| retVal {PrVoid} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrVoid makeBroken: ex]
		do: 	[retVal _ PrVoid make: (self getActualFeCalc times)].
	Promise inDelayBlock ifFalse: [
		Promise force.
		retVal isBroken ifTrue: [
			retVal explode]]
	ifTrue: [
		retVal isBroken ifTrue: [
			(retVal problemName contentsEqual: (UInt8Array string: 'BrokenPromise')) ifFalse: [
				Promise savePromise: retVal]]].
	^retVal.!

{PrVoid} timesArg: rat {PrRational} 

	| retVal {PrVoid} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrVoid makeBroken: ex]
		do: 	[retVal _ PrVoid make: (self getActualFeCalc timesArg: (rat getActualFeRational ))].
	Promise inDelayBlock ifFalse: [
		Promise force.
		retVal isBroken ifTrue: [
			retVal explode]]
	ifTrue: [
		retVal isBroken ifTrue: [
			(retVal problemName contentsEqual: (UInt8Array string: 'BrokenPromise')) ifFalse: [
				Promise savePromise: retVal]]].
	^retVal.!

{PrVoid} timesCurrent

	| retVal {PrVoid} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrVoid makeBroken: ex]
		do: 	[retVal _ PrVoid make: (self getActualFeCalc timesCurrent)].
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

PxCalc class
	instanceVariableNames: ''!

(PxCalc getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PxCalc class methodsFor: 'pseudo-constructors'!

make: anFeCalc {FeCalc}

	^self create: anFeCalc!

makeBroken: problem {Problem star}

	^self create.Problem: problem.! !