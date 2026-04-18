'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:01 pm'!

XuCoordinateSpace subclass: #XuSequenceSpace
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
XuSequenceSpace comment:
'The space of all Sequences'!

(XuSequenceSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSequenceSpace methodsFor: 'making'!

{XuSequenceRegion} above: sequence {XuSequence} with: inclusive {XuIntValue} 

	"Essential. All sequences >= sequence if inclusive, > sequence if not."
	
	| retVal {XuSequenceRegion} |
	(self isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: self].
	(sequence isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: sequence].
	(inclusive isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: inclusive].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequenceRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequenceRegion make: (self getActualSequenceSpace above: ((XuPromise getActual: sequence) cast: Sequence) with:inclusive getActualBooleanVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequenceRegion} below: sequence {XuSequence} with: inclusive {XuIntValue} 

	"Essential. All sequences <= sequence if inclusive, < sequence if not."
	
	| retVal {XuSequenceRegion} |
	(self isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: self].
	(sequence isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: sequence].
	(inclusive isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: inclusive].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequenceRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequenceRegion make: (self getActualSequenceSpace below: ((XuPromise getActual: sequence) cast: Sequence) with:inclusive getActualBooleanVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequenceRegion} interval: start {XuSequence} with: stop {XuSequence} 

	"Return a region of all sequence >= lower and < upper."
	
	| retVal {XuSequenceRegion} |
	(self isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: self].
	(start isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: start].
	(stop isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: stop].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequenceRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequenceRegion make: (self getActualSequenceSpace interval: ((XuPromise getActual: start) cast: Sequence) with: ((XuPromise getActual: stop) cast: Sequence))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequenceMapping} mapping: shift {XuIntValue} with: translation {XuSequence default: DefaultNull} 

	"A transformation which shifts a value by some number of places and then adds a translation to it."
	
	| retVal {XuSequenceMapping} |
	(self isBroken) ifTrue:
		[^XuSequenceMapping makeBrokenBy: self].
	(shift isBroken) ifTrue:
		[^XuSequenceMapping makeBrokenBy: shift].
	(translation isBroken) ifTrue:
		[^XuSequenceMapping makeBrokenBy: translation].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequenceMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequenceMapping make: (self getActualSequenceSpace mapping:shift getActualIntegerVar with: ((XuPromise getActual: translation) cast: Sequence))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequence} position: arg {XuArray} with: shift {XuIntValue} 

	"Essential. A sequence using the given numbers and shift. Leading and trailing zeros will be stripped, and a copy will be made so that noone modifies it"
	
	| retVal {XuSequence} |
	(self isBroken) ifTrue:
		[^XuSequence makeBrokenBy: self].
	(arg isBroken) ifTrue:
		[^XuSequence makeBrokenBy: arg].
	(shift isBroken) ifTrue:
		[^XuSequence makeBrokenBy: shift].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequence makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequence make: (self getActualSequenceSpace position: ((XuPromise getActual: arg) cast: PrimArray) with:shift getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequenceRegion} prefixedBy: sequence {XuSequence} with: limit {XuIntValue} 

	"Essential. All sequences which match the given one up to and including the given index."
	
	| retVal {XuSequenceRegion} |
	(self isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: self].
	(sequence isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: sequence].
	(limit isBroken) ifTrue:
		[^XuSequenceRegion makeBrokenBy: limit].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequenceRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequenceRegion make: (self getActualSequenceSpace prefixedBy: ((XuPromise getActual: sequence) cast: Sequence) with:limit getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuSequenceSpace methodsFor: 'promise access'!

{SequenceSpace} getActualSequenceSpace
	self isBroken
		ifFalse: [^super actualThing cast: SequenceSpace.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuSequenceSpace methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anSequenceSpace {SequenceSpace}
	super create: anSequenceSpace.! !

!XuSequenceSpace methodsFor: 'smalltalk: defaults'!

{XuSequenceMapping} mapping: shift {XuIntValue} 

	"A transformation which shifts a value by some number of places and then adds a translation to it."
	
	| retVal {XuSequenceMapping} |
	(self isBroken) ifTrue:
		[^XuSequenceMapping makeBrokenBy: self].
	(shift isBroken) ifTrue:
		[^XuSequenceMapping makeBrokenBy: shift].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequenceMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequenceMapping make: (self getActualSequenceSpace mapping:shift getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuSequenceSpace methodsFor: 'temporary'!

{XuSequence} position: numbers {XuArray} 

	"This method has no comment."
	
	| retVal {XuSequence} |
	(self isBroken) ifTrue:
		[^XuSequence makeBrokenBy: self].
	(numbers isBroken) ifTrue:
		[^XuSequence makeBrokenBy: numbers].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequence makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequence make: (self getActualSequenceSpace position: ((XuPromise getActual: numbers) cast: PrimArray))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuSequenceSpace class
	instanceVariableNames: ''!

(XuSequenceSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSequenceSpace class methodsFor: 'pseudo-constructors'!

make: anSequenceSpace {SequenceSpace}
	^self create: anSequenceSpace!

{XuSequenceSpace} makeBroken: problem {Problem star}
	| broke {XuSequenceSpace} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuSequenceSpace} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !