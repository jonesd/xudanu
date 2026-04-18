'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:00 pm'!

XuMapping subclass: #XuSequenceMapping
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
XuSequenceMapping comment:
'Transforms a Sequence by shifting some amount, and then adding another Sequence to it.'!

(XuSequenceMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSequenceMapping methodsFor: 'promise access'!

{SequenceMapping} getActualSequenceMapping
	self isBroken
		ifFalse: [^super actualThing cast: SequenceMapping.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuSequenceMapping methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anSequenceMapping {SequenceMapping}
	super create: anSequenceMapping.! !

!XuSequenceMapping methodsFor: 'accessing'!

{XuIntValue} shift

	"The amount by which it shifts a sequence"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualSequenceMapping shift)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequence} translation

	"What it adds to a sequence after shifting it"
	
	| retVal {XuSequence} |
	(self isBroken) ifTrue:
		[^XuSequence makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequence makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequence make: (self getActualSequenceMapping translation)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuSequenceMapping class
	instanceVariableNames: ''!

(XuSequenceMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSequenceMapping class methodsFor: 'pseudo-constructors'!

make: anSequenceMapping {SequenceMapping}
	^self create: anSequenceMapping!

{XuSequenceMapping} makeBroken: problem {Problem star}
	| broke {XuSequenceMapping} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuSequenceMapping} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !