'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:47 pm'!

XuMapping subclass: #XuCrossMapping
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cross'!
XuCrossMapping comment:
'All other crossed mappings must be gotten by factoring the non-dsp aspects out into the generic non-dsp mapping objects.  This class represents what remains after the factoring.'!

(XuCrossMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCrossMapping methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anCrossMapping {CrossMapping}
	super create: anCrossMapping.! !

!XuCrossMapping methodsFor: 'accessing'!

{XuMapping} subMapping: index {XuIntValue} 

	"The Dsp applied to Positions in the given subspace."
	
	| retVal {XuMapping} |
	(self isBroken) ifTrue:
		[^XuMapping makeBrokenBy: self].
	(index isBroken) ifTrue:
		[^XuMapping makeBrokenBy: index].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuMapping makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuMapping make: (self getActualCrossMapping subMapping:index getActualInt32)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuPtrArray} subMappings

	"The Mappings applied to Positions in each of the subspaces. Each of these is already simple enough that it is either the identityMapping or a visible subclass like IntegerMapping."
	
	| retVal {XuPtrArray} |
	(self isBroken) ifTrue:
		[^XuPtrArray makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuPtrArray makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuPtrArray make: (self getActualCrossMapping subMappings)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !

!XuCrossMapping methodsFor: 'promise access'!

{CrossMapping} getActualCrossMapping
	self isBroken
		ifFalse: [^super actualThing cast: CrossMapping.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuCrossMapping class
	instanceVariableNames: ''!

(XuCrossMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuCrossMapping class methodsFor: 'pseudo-constructors'!

make: anCrossMapping {CrossMapping}
	^self create: anCrossMapping!

{XuCrossMapping} makeBroken: problem {Problem star}
	| broke {XuCrossMapping} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuCrossMapping} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !