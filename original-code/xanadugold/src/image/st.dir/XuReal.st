'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:58 pm'!

XuPosition subclass: #XuReal
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
XuReal comment:
'Represents some real number exactly.  Not all real numbers can be exactly represented.  See class comment in RealSpace.'!

(XuReal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuReal methodsFor: 'promise access'!

{RealPos} getActualRealPos
	self isBroken
		ifFalse: [^super actualThing cast: RealPos.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuReal methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anRealPos {RealPos}
	super create: anRealPos.! !

!XuReal methodsFor: 'accessing'!

{XuFloatValue} value

	"Essential. Return the number as a PrimFloat object from which you can get it in a variety of representations."
	
	| retVal {XuFloatValue} |
	(self isBroken) ifTrue:
		[^XuFloatValue makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuFloatValue makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuFloatValue make: (self getActualRealPos value)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuReal class
	instanceVariableNames: ''!

(XuReal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuReal class methodsFor: 'pseudo-constructors'!

make: anRealPos {RealPos}
	^self create: anRealPos!

{XuReal} makeBroken: problem {Problem star}
	| broke {XuReal} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuReal} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !