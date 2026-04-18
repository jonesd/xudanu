'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:26 pm'!

XuPromise subclass: #XuWrapperSpec
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
XuWrapperSpec comment:
'Handles wrapping, certification, and filtering for a wrapper type and its subtypes (if there are any)'!

(XuWrapperSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWrapperSpec methodsFor: 'promise access'!

{FeWrapperSpec} getActualFeWrapperSpec
	self isBroken
		ifFalse: [^super actualThing cast: FeWrapperSpec.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuWrapperSpec methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeWrapperSpec {FeWrapperSpec}
	super create: anFeWrapperSpec.! !

!XuWrapperSpec methodsFor: 'accessing'!

{XuFilter} filter

	"A filter which selects for Editions which have been endorsed as belonging to this type."
	
	| retVal {XuFilter} |
	(self isBroken) ifTrue:
		[^XuFilter makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuFilter makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuFilter make: (self getActualFeWrapperSpec filter)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuSequence} name

	"The name for this type"
	
	| retVal {XuSequence} |
	(self isBroken) ifTrue:
		[^XuSequence makeBrokenBy: self].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuSequence makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuSequence make: (self getActualFeWrapperSpec name)].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal!

{XuWrapper} wrap: edition {XuEdition} 

	"The Edition wrapped with my type of Wrapper. If it does not have endorsements, will attempt to certify. Blasts if there is more than one valid wrapping."
	
	| retVal {XuWrapper} |
	(self isBroken) ifTrue:
		[^XuWrapper makeBrokenBy: self].
	(edition isBroken) ifTrue:
		[^XuWrapper makeBrokenBy: edition].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuWrapper makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuWrapper make: (self getActualFeWrapperSpec wrap: ((XuPromise getActual: edition) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuWrapperSpec class
	instanceVariableNames: ''!

(XuWrapperSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuWrapperSpec class methodsFor: 'pseudo-constructors'!

make: anFeWrapperSpec {FeWrapperSpec}
	^self create: anFeWrapperSpec!

{XuWrapperSpec} makeBroken: problem {Problem star}
	| broke {XuWrapperSpec} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuWrapperSpec} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !