'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:25 pm'!

XuWrapper subclass: #XuSet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
XuSet comment:
'An undifferentiated set of RangeElements.'!

(XuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSet methodsFor: 'promise access'!

{FeSet} getActualFeSet
	self isBroken
		ifFalse: [^super actualThing cast: FeSet.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuSet methodsFor: 'accessing'!

{XuIntValue} count

	"The number of elements in the set"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue integerVar: (self getActualFeSet count)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} includes: value {XuRangeElement} 

	"Whether the set includes the given RangeElement"
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].
	(value isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualFeSet includes: ((XuPromise getActual: value) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSet} intersect: other {XuSet} 

	"Return those elements which are in both sets"
	
	| retVal {XuSet} |
	(self isBroken) ifTrue:
		[^XuSet makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuSet makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSet makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSet make: (self getActualFeSet intersect: ((XuPromise getActual: other) cast: FeSet))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSet} minus: other {XuSet} 

	"Remove some RangeElements from the set"
	
	| retVal {XuSet} |
	(self isBroken) ifTrue:
		[^XuSet makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuSet makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSet makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSet make: (self getActualFeSet minus: ((XuPromise getActual: other) cast: FeSet))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuRangeElement} theOne

	"If there is exactly one element, then return it"
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFeSet theOne)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSet} unionWith: other {XuSet} 

	"Return those elements which are in either set"
	
	| retVal {XuSet} |
	(self isBroken) ifTrue:
		[^XuSet makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuSet makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSet makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSet make: (self getActualFeSet unionWith: ((XuPromise getActual: other) cast: FeSet))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSet} with: value {XuRangeElement} 

	"Add a RangeElement to the set"
	
	| retVal {XuSet} |
	(self isBroken) ifTrue:
		[^XuSet makeBrokenBy: self].
	(value isBroken) ifTrue:
		[^XuSet makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSet makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSet make: (self getActualFeSet with: ((XuPromise getActual: value) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSet} without: value {XuRangeElement} 

	"Remove a RangeElement from the set"
	
	| retVal {XuSet} |
	(self isBroken) ifTrue:
		[^XuSet makeBrokenBy: self].
	(value isBroken) ifTrue:
		[^XuSet makeBrokenBy: value].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSet makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSet make: (self getActualFeSet without: ((XuPromise getActual: value) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuSet methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeSet {FeSet}
	super create: anFeSet.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuSet class
	instanceVariableNames: ''!

(XuSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSet class methodsFor: 'pseudo-constructors'!

make: anFeSet {FeSet}
	^self create: anFeSet!

{XuSet} makeBroken: problem {Problem star}
	| broke {XuSet} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuSet} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !