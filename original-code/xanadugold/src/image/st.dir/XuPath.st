'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:35 pm'!

XuWrapper subclass: #XuPath
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
XuPath comment:
'A sequence of Labels, used for context information in a LinkEnd.'!

(XuPath getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPath methodsFor: 'promise access'!

{FePath} getActualFePath
	self isBroken
		ifFalse: [^super actualThing cast: FePath.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuPath methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFePath {FePath}
	super create: anFePath.! !

!XuPath methodsFor: 'operations'!

{XuRangeElement} follow: edition {XuEdition} 

	"Follow a path down into an Edition and return what is at the end of the path. Fail if at any point there is not precisely one choice."
	
	| retVal {XuRangeElement} |
	(self isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: self].
	(edition isBroken) ifTrue:
		[^XuRangeElement makeBrokenBy: edition].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuRangeElement makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuRangeElement make: (self getActualFePath follow: ((XuPromise getActual: edition) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuPath class
	instanceVariableNames: ''!

(XuPath getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuPath class methodsFor: 'pseudo-constructors'!

make: anFePath {FePath}
	^self create: anFePath!

{XuPath} makeBroken: problem {Problem star}
	| broke {XuPath} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuPath} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !