'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:59 pm'!

XuPosition subclass: #XuSequence
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
XuSequence comment:
'Represents an infinite sequence of integers (of which only a finite number can be non-zero). They are lexically ordered, and there is a "decimal point" between the numbers at -1 and 0.

Implementation note:
The array should have no zeros at either end, and noone else should have a pointer to it.'!

(XuSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSequence methodsFor: 'accessing'!

{XuIntValue} firstIndex

	"The smallest index with a non-zero number. Blasts if it is all zeros."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualSequence firstIndex)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} integerAt: index {XuIntValue} 

	"The number at the given index in the Sequence. Returns zeros beyond either end of the array."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(index isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: index].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualSequence integerAt:index getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuArray} integers

	"Essential. The numbers in this Sequence. This is a copy of the array, so you may modify it.
	Note that two Sequences which are isEqual, may actually have arrays of numbers which have different specs. Also, the array will not have any zeros at the beginning or end."
	
	| retVal {XuArray} |
	(self isBroken) ifTrue:
		[^XuArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuArray make: (self getActualSequence integers)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isZero

	"Whether all the numbers in the sequence are zero"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualSequence isZero)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} lastIndex

	"The largest index with a non-zero number. Blasts if it is all zeros."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualSequence lastIndex)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuSequence methodsFor: 'promise access'!

{Sequence} getActualSequence
	self isBroken
		ifFalse: [^super actualThing cast: Sequence.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuSequence methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anSequence {Sequence}
	super create: anSequence.! !

!XuSequence methodsFor: 'operations'!

{XuSequence} with: index {XuIntValue} with: number {XuIntValue} 

	"Change a single element of the sequence."
	
	| retVal {XuSequence} |
	(self isBroken) ifTrue:
		[^XuSequence makeBrokenBy: self].
	(index isBroken) ifTrue:
		[^XuSequence makeBrokenBy: index].
	(number isBroken) ifTrue:
		[^XuSequence makeBrokenBy: number].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequence makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequence make: (self getActualSequence with:index getActualIntegerVar with:number getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuSequence class
	instanceVariableNames: ''!

(XuSequence getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSequence class methodsFor: 'pseudo-constructors'!

make: anSequence {Sequence}
	^self create: anSequence!

{XuSequence} makeBroken: problem {Problem star}
	| broke {XuSequence} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuSequence} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !