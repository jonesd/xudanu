'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:36 pm'!

XuHyperRef subclass: #XuSingleRef
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
XuSingleRef comment:
'Represents a single attachment to some material in the context of a Work, and maybe a Path beneath it.'!

(XuSingleRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSingleRef methodsFor: 'promise access'!

{FeSingleRef} getActualFeSingleRef
	self isBroken
		ifFalse: [^super actualThing cast: FeSingleRef.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuSingleRef methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeSingleRef {FeSingleRef}
	super create: anFeSingleRef.! !

!XuSingleRef methodsFor: 'accessing'!

{XuEdition} excerpt

	"The material to which this HyperRef is attached."
	
	| retVal {XuEdition} |
	(self isBroken) ifTrue:
		[^XuEdition makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuEdition makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuEdition make: (self getActualFeSingleRef excerpt)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSingleRef} withExcerpt: excerpt {XuEdition} 

	"Make this Ref point at different material."
	
	| retVal {XuSingleRef} |
	(self isBroken) ifTrue:
		[^XuSingleRef makeBrokenBy: self].
	(excerpt isBroken) ifTrue:
		[^XuSingleRef makeBrokenBy: excerpt].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSingleRef makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSingleRef make: (self getActualFeSingleRef withExcerpt: ((XuPromise getActual: excerpt) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuSingleRef class
	instanceVariableNames: ''!

(XuSingleRef getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuSingleRef class methodsFor: 'pseudo-constructors'!

make: anFeSingleRef {FeSingleRef}
	^self create: anFeSingleRef!

{XuSingleRef} makeBroken: problem {Problem star}
	| broke {XuSingleRef} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuSingleRef} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !