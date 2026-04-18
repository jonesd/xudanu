'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:20 pm'!

XuRegion subclass: #XuIntegerRegion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!
XuIntegerRegion comment:
'An IntegerRegion can be thought of as the disjoint union of intervals and inequalities.  The interesting cases to look at are:
	
	The distinctions:
		1) The empty region
		2) The full region
		3) A "left" inequality -- e.g., everything less that 3.
		4) A "right" inequality -- e.g., everything greater than or equal to 7
		
	The non-distinction simple regions:
		5) An interval -- e.g., from 3 inclusive to 7 exclusive
		
	The non-simple regions:
		6) A disjoint union of (in order) an optional left inequality, a set of 
			intervals, and an optional right inequality.  
		
	If a non-empty region has a least element, then it "isBoundedLeft".  Otherwise it extends leftwards indefinitely.  Similarly, if a non-empty region has a greatest element, then it "isBoundedRight".  Otherwise it extends rightwards indefinitely.  (We may figuratively speak of the region extending towards + or - infinity, but we have purposely avoided introducing any value which represents an infinity.)
	
	Looking at cases again:
		1) "isBoundedLeft" and "isBoundedRight" since it doesn''t extent 
			indenfinitely in either direction.  (A danger to watch out for is that 
			this still has niether a greatest nor a least element).
		2) niether.
		3) "isBoundedRight"
		4) "isBoundedLeft"
		5) "isBoundedLeft" and "isBoundedRight"
		6) "isBoundedLeft" iff doesn''t include a left inequality,
			"isBoundedRight" iff doesn''t include a right inequality.
			
	An efficiency note:  Currently many of the method which could be doing an O(log) binary search (such as hasMember) are instead doing a linear search.  This will be fixed if it turns out to be a problem in practice.
	
	See OrderedRegion.'!

(XuIntegerRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntegerRegion methodsFor: 'enumerating'!

{XuStepper} intervals: order {XuOrderSpec default: DefaultNull} 

	"Essential. Break this into an ascending sequence of disjoint intervals (which may be unbounded)."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].
	(order isBroken) ifTrue:
		[^XuStepper makeBrokenBy: order].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualIntegerRegion intervals: ((XuPromise getActual: order) cast: OrderSpec))].
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
		do: 	[retVal _ XuIntValue booleanVar: (self getActualIntegerRegion isInterval)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuIntegerRegion methodsFor: 'accessing'!

{XuIntValue} start

	"I have a start only if I'm not empty and I am isBoundedBelow. I report as my start the smallest position I *do* contain, which is one greater than the largest position I do not contain. The lower bound of the interval from 3 inclusive to 7 exclusive is 3. 
	See 'stop', you may be surprised."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualIntegerRegion start)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} stop

	"I have a stop only if I'm not empty and I am isBoundedAbove. I report as my stop the smallest position I *do not* contain, which is one greater than the largest position I do contain.  The ustop of the interval from 3 inclusive to 7 exclusive is 7.
	See 'start', you may be surprised."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualIntegerRegion stop)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuIntegerRegion methodsFor: 'promise access'!

{IntegerRegion} getActualIntegerRegion
	self isBroken
		ifFalse: [^super actualThing cast: IntegerRegion.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuIntegerRegion methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anIntegerRegion {IntegerRegion}
	super create: anIntegerRegion.! !

!XuIntegerRegion methodsFor: 'smalltalk: defaults'!

{XuStepper} intervals

	^self  intervals: DefaultNull! !

!XuIntegerRegion methodsFor: 'testing'!

{XuIntValue} isBoundedAbove

	"Either I extend indefinitely to plus infinity, or I am bounded above, not both. 
	The empty region is bounded above despite the fact that it has no upper edge."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualIntegerRegion isBoundedAbove)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isBoundedBelow

	"Either I extend indefinitely to minus infinity, or I am bounded below, not both. 
	The empty region is bounded below despite the fact that it has no lower bound."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualIntegerRegion isBoundedBelow)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuIntegerRegion class
	instanceVariableNames: ''!

(XuIntegerRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuIntegerRegion class methodsFor: 'pseudo-constructors'!

make: anIntegerRegion {IntegerRegion}
	^self create: anIntegerRegion!

{XuIntegerRegion} makeBroken: problem {Problem star}
	| broke {XuIntegerRegion} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuIntegerRegion} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !