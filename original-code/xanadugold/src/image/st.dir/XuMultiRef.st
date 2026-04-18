'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:34 pm'!

XuHyperRef subclass: #XuMultiRef
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
XuMultiRef comment:
'An undifferentiated set of HyperRefs'!

(XuMultiRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMultiRef methodsFor: 'accessing'!

{XuMultiRef} intersect: other {XuMultiRef} 

	"Remove those not in the other Refs from the set."
	
	| retVal {XuMultiRef} |
	(self isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMultiRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMultiRef make: (self getActualFeMultiRef intersect: ((XuPromise getActual: other) cast: FeMultiRef))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMultiRef} minus: other {XuMultiRef} 

	"Remove the other Refs from the set."
	
	| retVal {XuMultiRef} |
	(self isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMultiRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMultiRef make: (self getActualFeMultiRef minus: ((XuPromise getActual: other) cast: FeMultiRef))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuStepper} refs

	"All the HyperRefs in the collection"
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualFeMultiRef refs)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMultiRef} unionWith: other {XuMultiRef} 

	"Add the other Refs into the set."
	
	| retVal {XuMultiRef} |
	(self isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: self].
	(other isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: other].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMultiRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMultiRef make: (self getActualFeMultiRef unionWith: ((XuPromise getActual: other) cast: FeMultiRef))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMultiRef} with: ref {XuHyperRef} 

	"Add a Ref to the set"
	
	| retVal {XuMultiRef} |
	(self isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: self].
	(ref isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: ref].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMultiRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMultiRef make: (self getActualFeMultiRef with: ((XuPromise getActual: ref) cast: FeHyperRef))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuMultiRef} without: ref {XuHyperRef} 

	"Add a Ref to the set"
	
	| retVal {XuMultiRef} |
	(self isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: self].
	(ref isBroken) ifTrue:
		[^XuMultiRef makeBrokenBy: ref].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMultiRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMultiRef make: (self getActualFeMultiRef without: ((XuPromise getActual: ref) cast: FeHyperRef))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuMultiRef methodsFor: 'promise access'!

{FeMultiRef} getActualFeMultiRef
	self isBroken
		ifFalse: [^super actualThing cast: FeMultiRef.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuMultiRef methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeMultiRef {FeMultiRef}
	super create: anFeMultiRef.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuMultiRef class
	instanceVariableNames: ''!

(XuMultiRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuMultiRef class methodsFor: 'pseudo-constructors'!

make: anFeMultiRef {FeMultiRef}
	^self create: anFeMultiRef!

{XuMultiRef} makeBroken: problem {Problem star}
	| broke {XuMultiRef} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuMultiRef} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !