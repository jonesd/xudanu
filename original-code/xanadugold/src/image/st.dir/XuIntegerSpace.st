'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:21 pm'!

XuCoordinateSpace subclass: #XuIntegerSpace
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!
XuIntegerSpace comment:
'The space of all integers.  See the class comments in IntegerRegion, XuInteger, and IntegerDsp for interesting properties of this space.  Especially IntegerRegion.
	
	IntegerSpaces are the most frequently used of the coordinate spaces.  XuArrays are an efficient data structure which we provide as a table whose domain space is an integer space.  In so doing, the notion of an array is made to be simply a particular case of a table indexed by the positions of a coordinate space.  However, IntegerSpaces and XuArrays are both expected to be more efficient than other spaces and tables built on other spaces.  See XuArray'!

(XuIntegerSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntegerSpace methodsFor: 'making'!

{XuIntegerRegion} above: start {XuInteger} with: inclusive {XuIntValue} 

	"Essential. Make a region that contains all integers greater than (or equal if inclusive is true) to start."
	
	| retVal {XuIntegerRegion} |
	(self isBroken) ifTrue:
		[^XuIntegerRegion makeBrokenBy: self].
	(start isBroken) ifTrue:
		[^XuIntegerRegion makeBrokenBy: start].
	(inclusive isBroken) ifTrue:
		[^XuIntegerRegion makeBrokenBy: inclusive].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntegerRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntegerRegion make: (self getActualIntegerSpace above: ((XuPromise getActual: start) cast: IntegerPos) with:inclusive getActualBooleanVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntegerRegion} below: stop {XuInteger} with: inclusive {XuIntValue} 

	"Make a region that contains all integers less than (or equal if inclusive is true) to stop."
	
	| retVal {XuIntegerRegion} |
	(self isBroken) ifTrue:
		[^XuIntegerRegion makeBrokenBy: self].
	(stop isBroken) ifTrue:
		[^XuIntegerRegion makeBrokenBy: stop].
	(inclusive isBroken) ifTrue:
		[^XuIntegerRegion makeBrokenBy: inclusive].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntegerRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntegerRegion make: (self getActualIntegerSpace below: ((XuPromise getActual: stop) cast: IntegerPos) with:inclusive getActualBooleanVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntegerRegion} interval: start {XuInteger} with: stop {XuInteger} 

	"Make a region that contains all integers greater than or equal to start and less than stop."
	
	| retVal {XuIntegerRegion} |
	(self isBroken) ifTrue:
		[^XuIntegerRegion makeBrokenBy: self].
	(start isBroken) ifTrue:
		[^XuIntegerRegion makeBrokenBy: start].
	(stop isBroken) ifTrue:
		[^XuIntegerRegion makeBrokenBy: stop].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntegerRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntegerRegion make: (self getActualIntegerSpace interval: ((XuPromise getActual: start) cast: IntegerPos) with: ((XuPromise getActual: stop) cast: IntegerPos))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuInteger} position: value {XuIntValue} 

	"Essential. Make an integer Position object"
	
	| retVal {XuInteger} |
	(self isBroken) ifTrue:
		[^XuInteger makeBrokenBy: self].
	(value isBroken) ifTrue:
		[^XuInteger makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuInteger makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuInteger make: (self getActualIntegerSpace position:value getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntegerMapping} translation: value {XuIntValue} 

	"Essential. Make a Mapping which adds a fixed amount to any value.
	Should this just be supplanted by CoordinateSpace::mapping ()?"
	
	| retVal {XuIntegerMapping} |
	(self isBroken) ifTrue:
		[^XuIntegerMapping makeBrokenBy: self].
	(value isBroken) ifTrue:
		[^XuIntegerMapping makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntegerMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntegerMapping make: (self getActualIntegerSpace translation:value getActualIntegerVar)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuIntegerSpace methodsFor: 'promise access'!

{IntegerSpace} getActualIntegerSpace
	self isBroken
		ifFalse: [^super actualThing cast: IntegerSpace.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuIntegerSpace methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anIntegerSpace {IntegerSpace}
	super create: anIntegerSpace.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuIntegerSpace class
	instanceVariableNames: ''!

(XuIntegerSpace getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntegerSpace class methodsFor: 'pseudo-constructors'!

make: anIntegerSpace {IntegerSpace}
	^self create: anIntegerSpace!

{XuIntegerSpace} makeBroken: problem {Problem star}
	| broke {XuIntegerSpace} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuIntegerSpace} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !