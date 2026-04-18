'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:05 pm'!

XuPromise subclass: #PxCalcCreator
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fecalc'!

(PxCalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PxCalcCreator methodsFor: 'promise access'!

{FeCalcCreator} getActualFeCalcCreator

	self isBroken ifFalse: [
		^myActualThing cast: FeCalcCreator.]
	ifTrue: [
		Heaper BLAST: #BrokenPromise].! !

!PxCalcCreator methodsFor: 'creation'!

create: anFeCalcCreator {FeCalcCreator}

	super create.
	myActualThing _ anFeCalcCreator.! !

!PxCalcCreator methodsFor: 'accessing'!

{PrCalc} newCalc

	| retVal {PrCalc} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrCalc makeBroken: ex]
		do: 	[retVal _ PrCalc make: (self getActualFeCalcCreator newCalc)].
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

PxCalcCreator class
	instanceVariableNames: ''!

(PxCalcCreator getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PxCalcCreator class methodsFor: 'pseudo-constructors'!

make: anFeCalcCreator {FeCalcCreator}

	^self create: anFeCalcCreator!

makeBroken: problem {Problem star}

	^self create.Problem: problem.! !