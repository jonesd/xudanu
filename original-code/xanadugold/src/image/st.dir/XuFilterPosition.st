'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:18 pm'!

XuPosition subclass: #XuFilterPosition
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filter'!
XuFilterPosition comment:
'Encapsulates a Region in the baseSpace into a Position so that it can be treated as one for polymorphism. See Filter.'!

(XuFilterPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFilterPosition methodsFor: 'promise access'!

{FilterPosition} getActualFilterPosition
	self isBroken
		ifFalse: [^super actualThing cast: FilterPosition.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuFilterPosition methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFilterPosition {FilterPosition}
	super create: anFilterPosition.! !

!XuFilterPosition methodsFor: 'accessing'!

{XuRegion} baseRegion

	"Essential. The region in the base space which I represent."
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFilterPosition baseRegion)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuFilterPosition class
	instanceVariableNames: ''!

(XuFilterPosition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFilterPosition class methodsFor: 'pseudo-constructors'!

make: anFilterPosition {FilterPosition}
	^self create: anFilterPosition!

{XuFilterPosition} makeBroken: problem {Problem star}
	| broke {XuFilterPosition} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuFilterPosition} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !