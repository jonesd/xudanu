'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:12 pm'!

XuPromise subclass: #XuBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuBundle comment:
'Describes a single chunk of information from an Edition'!

(XuBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuBundle methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeBundle {FeBundle}
	super create: anFeBundle.! !

!XuBundle methodsFor: 'promise access'!

{FeBundle} getActualFeBundle
	self isBroken
		ifFalse: [^super actualThing cast: FeBundle.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuBundle methodsFor: 'accessing'!

{XuRegion} region

	"Essential. The positions in the Edition for which I describe the contents"
	
	| retVal {XuRegion} |
	(self isBroken) ifTrue:
		[^XuRegion makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRegion makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRegion make: (self getActualFeBundle region)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuBundle class
	instanceVariableNames: ''!

(XuBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuBundle class methodsFor: 'pseudo-constructors'!

make: anFeBundle {FeBundle}
	^self create: anFeBundle!

{XuBundle} makeBroken: problem {Problem star}
	| broke {XuBundle} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuBundle} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !