'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:05 pm'!

XuPromise subclass: #PxRational
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-fecalc'!

(PxRational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PxRational methodsFor: 'promise access'!

{FeRational} getActualFeRational

	self isBroken ifFalse: [
		^myActualThing cast: FeRational.]
	ifTrue: [
		Heaper BLAST: #BrokenPromise].! !

!PxRational methodsFor: 'creation'!

create: anFeRational {FeRational}

	super create.
	myActualThing _ anFeRational.! !

!PxRational methodsFor: 'accessing'!

{PrInteger} denominator

	| retVal {PrInteger} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrInteger makeBroken: ex]
		do: 	[retVal _ PrInteger make: (self getActualFeRational denominator)].
	Promise inDelayBlock ifFalse: [
		Promise force.
		retVal isBroken ifTrue: [
			retVal explode]]
	ifTrue: [
		retVal isBroken ifTrue: [
			(retVal problemName contentsEqual: (UInt8Array string: 'BrokenPromise')) ifFalse: [
				Promise savePromise: retVal]]].
	^retVal.!

{PrInteger} numerator

	| retVal {PrInteger} |
	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ PrInteger makeBroken: ex]
		do: 	[retVal _ PrInteger make: (self getActualFeRational numerator)].
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

PxRational class
	instanceVariableNames: ''!

(PxRational getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PxRational class methodsFor: 'pseudo-constructors'!

make: anFeRational {FeRational}

	^self create: anFeRational!

makeBroken: problem {Problem star}

	^self create.Problem: problem.! !