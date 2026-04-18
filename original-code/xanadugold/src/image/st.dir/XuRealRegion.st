'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:59 pm'!

XuRegion subclass: #XuRealRegion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!

(XuRealRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRealRegion methodsFor: 'enumerating'!

{XuStepper} intervals: order {XuOrderSpec default: DefaultNull} 

	"Essential. Break this up into disjoint intervals"
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(order isBroken) ifTrue:
		[^XuStepper makeBrokenBy: order].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualRealRegion intervals: ((XuPromise getActual: order) cast: OrderSpec))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isInterval

	"Whether this Region is a non-empty interval, i.e. if A, B in the Region and A <= C <= B then C is in the Region. This includes inequalities (e.g. {x | x > 5}) and the fullRegion in addition to ordinary two-ended intervals."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualRealRegion isInterval)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuRealRegion methodsFor: 'accessing'!

{XuReal} lowerBound

	"The largest real number such that all the positions in the region are >= it.  Does not necessarily lie in the region.  For example, the region of all numbers > 2 has a lowerBound of 2."
	
	| retVal {XuReal} |
	(self isBroken) ifTrue:
		[^XuReal makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuReal makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuReal make: (self getActualRealRegion lowerBound)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuReal} upperBound

	"The smallest real number such that all the positions in the region are <= it.  Does not necessarily lie in the region.  For example, the region of all numbers < 2 has an upperBound of 2."
	
	| retVal {XuReal} |
	(self isBroken) ifTrue:
		[^XuReal makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuReal makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuReal make: (self getActualRealRegion upperBound)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuRealRegion methodsFor: 'promise access'!

{RealRegion} getActualRealRegion
	self isBroken
		ifFalse: [^super actualThing cast: RealRegion.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuRealRegion methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anRealRegion {RealRegion}
	super create: anRealRegion.! !

!XuRealRegion methodsFor: 'testing'!

{XuIntValue} isBoundedAbove

	"Same meaning as IntegerRegion::isBoundedAbove"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualRealRegion isBoundedAbove)].
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
		do: 	[retVal _ XuIntValue booleanVar: (self getActualRealRegion isBoundedBelow)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuRealRegion methodsFor: 'smalltalk: defaults'!

{XuStepper} intervals

	"This method has no comment."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualRealRegion intervals)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuRealRegion class
	instanceVariableNames: ''!

(XuRealRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuRealRegion class methodsFor: 'pseudo-constructors'!

make: anRealRegion {RealRegion}
	^self create: anRealRegion!

{XuRealRegion} makeBroken: problem {Problem star}
	| broke {XuRealRegion} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuRealRegion} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !