'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:15 pm'!

XuBundle subclass: #XuElementBundle
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
XuElementBundle comment:
'Describes a region of an Edition in which all indices in my region hold the same RangeElement.'!

(XuElementBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuElementBundle methodsFor: 'promise access'!

{FeElementBundle} getActualFeElementBundle
	self isBroken
		ifFalse: [^super actualThing cast: FeElementBundle.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuElementBundle methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeElementBundle {FeElementBundle}
	super create: anFeElementBundle.! !

!XuElementBundle methodsFor: 'accessing'!

{XuRangeElement} element

	"Essential. The RangeElement which is at every position in my region"
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFeElementBundle element)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuElementBundle class
	instanceVariableNames: ''!

(XuElementBundle getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuElementBundle class methodsFor: 'pseudo-constructors'!

make: anFeElementBundle {FeElementBundle}
	^self create: anFeElementBundle!

{XuElementBundle} makeBroken: problem {Problem star}
	| broke {XuElementBundle} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuElementBundle} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !