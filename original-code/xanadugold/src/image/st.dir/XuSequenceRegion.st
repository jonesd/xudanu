'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:00 pm'!

XuRegion subclass: #XuSequenceRegion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
XuSequenceRegion comment:
'Represents a Region of Sequences. We can efficiently represent unions of intervals, delimited either by individual sequences or by a match with all sequences prefixed by some sequence up to some index.'!

(XuSequenceRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSequenceRegion methodsFor: 'enumerating'!

{XuStepper} intervals: order {XuOrderSpec default: DefaultNull} 

	"Essential. Break this up into disjoint intervals"
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(order isBroken) ifTrue:
		[^XuStepper makeBrokenBy: order].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualSequenceRegion intervals: ((XuPromise getActual: order) cast: OrderSpec))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isInterval

	"Whether this Region is a non-empty interval, i.e. if A, B in the Region and A <= C <= B then C is in the Region. This includes inequalities (e.g. {x | x > 5.3}) and the fullRegion in addition to ordinary two-ended intervals."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualSequenceRegion isInterval)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuSequenceRegion methodsFor: 'accessing'!

{XuSequence} lowerEdge

	"Essential. The Sequence associated with the lower edge of the Region. To find out where the boundary is in relation to this sequence, check lowerEdgeType. BLASTS if unbounded below."
	
	| retVal {XuSequence} |
	(self isBroken) ifTrue:
		[^XuSequence makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequence makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequence make: (self getActualSequenceRegion lowerEdge)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} lowerEdgePrefixLimit

	"Essential. If lowerEdgeType is prefix, then it includes an Sequence matching each integer in the lowerEdge up to and including lowerEdgePrefixLimit."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualSequenceRegion lowerEdgePrefixLimit)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} lowerEdgeType

	"Essential. The kind of Sequence associated with the lower edge of the Region. If SequenceRegion::inclusive then it includes the lowerEdge; if exclusive, then it does not; if prefix, then it includes any Sequence matching each integer in the lowerEdge up to and including lowerEdgePrefixLimit."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualSequenceRegion lowerEdgeType)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequence} upperEdge

	"Essential. The Sequence associated with the upper edge of the Region. To find out where the boundary is in relation to this sequence, check upperEdgeType. BLASTS if unbounded below."
	
	| retVal {XuSequence} |
	(self isBroken) ifTrue:
		[^XuSequence makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequence makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequence make: (self getActualSequenceRegion upperEdge)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} upperEdgePrefixLimit

	"Essential. If upperEdgeType is prefix, then it includes a Sequence matching each integer in the upperEdge up to and including upperEdgePrefixLimit."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualSequenceRegion upperEdgePrefixLimit)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} upperEdgeType

	"Essential. The kind of Sequence associated with the upper edge of the Region. If SequenceRegion::inclusive then it includes the upperEdge; if exclusive, then it does not; if prefix, then it includes any Sequence matching each integer in the upperEdge up to and including upperEdgePrefixLimit."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualSequenceRegion upperEdgeType)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuSequenceRegion methodsFor: 'promise access'!

{SequenceRegion} getActualSequenceRegion
	self isBroken
		ifFalse: [^super actualThing cast: SequenceRegion.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuSequenceRegion methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anSequenceRegion {SequenceRegion}
	super create: anSequenceRegion.! !

!XuSequenceRegion methodsFor: 'smalltalk: defaults'!

{XuStepper} intervals

	^self  intervals: DefaultNull! !

!XuSequenceRegion methodsFor: 'testing'!

{XuIntValue} isBoundedAbove

	"Same meaning as IntegerRegion::isBoundedAbove"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualSequenceRegion isBoundedAbove)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isBoundedBelow

	"Same meaning as IntegerRegion::isBoundedBelow"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualSequenceRegion isBoundedBelow)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuSequenceRegion class
	instanceVariableNames: ''!

(XuSequenceRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSequenceRegion class methodsFor: 'pseudo-constructors'!

make: anSequenceRegion {SequenceRegion}
	^self create: anSequenceRegion!

{XuSequenceRegion} makeBroken: problem {Problem star}
	| broke {XuSequenceRegion} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuSequenceRegion} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !