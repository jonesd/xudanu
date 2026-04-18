'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:12 pm'!

XuRegion subclass: #XuCrossRegion
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Cross'!
XuCrossRegion comment:
'A cross region is a distinction if 1) it is empty, 2) it is full, or 3) it is the rectangular cross of full regions and one distinction. Note that case 3 actually subsumes 1 and 2.  Since the simple regions of a space are the intersections of a finite number of distinctions of a space, this implies that A cross region is simple if it is the rectangular cross of simple regions.  In other words, a simple region is identical to the cross of its projections.'!

(XuCrossRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCrossRegion methodsFor: 'promise access'!

{CrossRegion} getActualCrossRegion
	self isBroken
		ifFalse: [^super actualThing cast: CrossRegion.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuCrossRegion methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anCrossRegion {CrossRegion}
	super create: anCrossRegion.! !

!XuCrossRegion methodsFor: 'accessing'!

{XuRegion} projection: index {XuIntValue} 

	"The answer is the projection of this region into the specified dimension of the cross space"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].
	(index isBroken) ifTrue:
		[^XuRegion makeBrokenBy: index].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualCrossRegion projection:index getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPtrArray} projections

	"Essential.  The answer is the projection of this region into each dimension of the cross space. Note that two regions which are different can have the same projections."
	
	| retVal {XuPtrArray} |
	(self isBroken) ifTrue:
		[^XuPtrArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPtrArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPtrArray make: (self getActualCrossRegion projections)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuCrossRegion methodsFor: 'enumerating'!

{XuStepper} boxes

	"Essential. Divide this Region up into a disjoint sequence of boxes. A box is a region which is the cross of its projections."
	
	| retVal {XuStepper} |
	(self isBroken) ifTrue:
		[^XuStepper makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuStepper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuStepper make: (self getActualCrossRegion boxes)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuIntValue} isBox

	"Whether this Region is a box, i.e. is equal to the cross of its projections."
	
	| retVal {XuIntValue} |
	(self isBroken) ifTrue:
		[^XuIntValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuIntValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuIntValue booleanVar: (self getActualCrossRegion isBox)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuCrossRegion class
	instanceVariableNames: ''!

(XuCrossRegion getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCrossRegion class methodsFor: 'pseudo-constructors'!

make: anCrossRegion {CrossRegion}
	^self create: anCrossRegion!

{XuCrossRegion} makeBroken: problem {Problem star}
	| broke {XuCrossRegion} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuCrossRegion} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !