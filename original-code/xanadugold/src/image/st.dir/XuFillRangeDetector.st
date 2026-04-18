'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:29 pm'!

XuPromise subclass: #XuFillRangeDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
XuFillRangeDetector comment:
'Client defines a subclass and passes it in to Edition::addFillRangeDetector, to be notified whenever PlaceHolders become any other kind of RangeElement.'!

(XuFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFillRangeDetector methodsFor: 'promise access'!

{FeFillRangeDetector} getActualFeFillRangeDetector
	self isBroken
		ifFalse: [^super actualThing cast: FeFillRangeDetector.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuFillRangeDetector methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeFillRangeDetector {FeFillRangeDetector}
	super create: anFeFillRangeDetector.! !

!XuFillRangeDetector methodsFor: 'triggering'!

{XuVoid} rangeFilled: newIdentities {XuEdition} 

	"Essential.  Some of the PlaceHolders in the Edition on which I was placed have become something else. The Edition has their new identies as its RangeElements, though the keys may bear no relationship to those in the original Edition."
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(newIdentities isBroken) ifTrue:
		[^XuVoid makeBrokenBy: newIdentities].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeFillRangeDetector rangeFilled: ((XuPromise getActual: newIdentities) cast: FeEdition))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuFillRangeDetector class
	instanceVariableNames: ''!

(XuFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFillRangeDetector class methodsFor: 'pseudo-constructors'!

make: anFeFillRangeDetector {FeFillRangeDetector}
	^self create: anFeFillRangeDetector!

{XuFillRangeDetector} makeBroken: problem {Problem star}
	| broke {XuFillRangeDetector} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuFillRangeDetector} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !