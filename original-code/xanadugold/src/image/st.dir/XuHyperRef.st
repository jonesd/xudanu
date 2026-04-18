'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:34 pm'!

XuWrapper subclass: #XuHyperRef
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
XuHyperRef comment:
'Represents a single attachment to some material in context.'!

(XuHyperRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuHyperRef methodsFor: 'accessing'!

{XuWork} originalContext

	"A Work frozen on the contents of the Work at the time the HyperRef was made"
	
	| retVal {XuWork} |
	(self isBroken) ifTrue:
		[^XuWork makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuWork makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuWork make: (self getActualFeHyperRef originalContext)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPath} pathContext

	"The path of labels down from the top-level Edition"
	
	| retVal {XuPath} |
	(self isBroken) ifTrue:
		[^XuPath makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPath makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPath make: (self getActualFeHyperRef pathContext)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuHyperRef} withOriginalContext: work {XuWork} 

	"Change (or remove if NULL) the originalContext"
	
	| retVal {XuHyperRef} |
	(self isBroken) ifTrue:
		[^XuHyperRef makeBrokenBy: self].
	(work isBroken) ifTrue:
		[^XuHyperRef makeBrokenBy: work].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuHyperRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuHyperRef make: (self getActualFeHyperRef withOriginalContext: ((XuPromise getActual: work) cast: FeWork))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuHyperRef} withPathContext: path {XuPath} 

	"Change (or remove if NULL) the pathContext"
	
	| retVal {XuHyperRef} |
	(self isBroken) ifTrue:
		[^XuHyperRef makeBrokenBy: self].
	(path isBroken) ifTrue:
		[^XuHyperRef makeBrokenBy: path].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuHyperRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuHyperRef make: (self getActualFeHyperRef withPathContext: ((XuPromise getActual: path) cast: FePath))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuHyperRef} withWorkContext: work {XuWork} 

	"Change (or remove if NULL) the workContext"
	
	| retVal {XuHyperRef} |
	(self isBroken) ifTrue:
		[^XuHyperRef makeBrokenBy: self].
	(work isBroken) ifTrue:
		[^XuHyperRef makeBrokenBy: work].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuHyperRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuHyperRef make: (self getActualFeHyperRef withWorkContext: ((XuPromise getActual: work) cast: FeWork))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuWork} workContext

	"The Work whose state this is attached to."
	
	| retVal {XuWork} |
	(self isBroken) ifTrue:
		[^XuWork makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuWork makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuWork make: (self getActualFeHyperRef workContext)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuHyperRef methodsFor: 'promise access'!

{FeHyperRef} getActualFeHyperRef
	self isBroken
		ifFalse: [^super actualThing cast: FeHyperRef.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuHyperRef methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeHyperRef {FeHyperRef}
	super create: anFeHyperRef.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuHyperRef class
	instanceVariableNames: ''!

(XuHyperRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuHyperRef class methodsFor: 'pseudo-constructors'!

make: anFeHyperRef {FeHyperRef}
	^self create: anFeHyperRef!

{XuHyperRef} makeBroken: problem {Problem star}
	| broke {XuHyperRef} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuHyperRef} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !