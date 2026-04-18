'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:28 pm'!

XuPromise subclass: #XuFillDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
XuFillDetector comment:
'Client defines subclasses and passes in an instance in order to be notified of new results from Edition::rangeTranscluders () or RangeElement::transcluders (). If passed to Edition::addFillRangeDetector, this subclass merely passes in the Editions in the range one by one, though they may appear in the result in batches.'!

(XuFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFillDetector methodsFor: 'promise access'!

{FeFillDetector} getActualFeFillDetector
	self isBroken
		ifFalse: [^super actualThing cast: FeFillDetector.]
		ifTrue: [Heaper BLAST: #BrokenPromise].! !

!XuFillDetector methodsFor: 'creation'!

create.Problem: problem {Problem}
	super create.Problem: problem.!

create.Promise: promise {XuPromise}
	super create.Promise: promise.!

create: anFeFillDetector {FeFillDetector}
	super create: anFeFillDetector.! !

!XuFillDetector methodsFor: 'triggering'!

{XuVoid} filled: newIdentity {XuRangeElement} 

	"A single PlaceHolder has been filled to become another kind of RangeElement"
	
	| retVal {XuVoid} |
	(self isBroken) ifTrue:
		[^XuVoid makeBrokenBy: self].
	(newIdentity isBroken) ifTrue:
		[^XuVoid makeBrokenBy: newIdentity].

	Heaper problems.AllBlasts 
		handle: [:ex | retVal _ XuVoid makeBroken: ex asProblem. ex return]
		do: 	[retVal _ XuVoid make. (self getActualFeFillDetector filled: ((XuPromise getActual: newIdentity) cast: FeRangeElement))].
	XuPromise inDelayBlock ifFalse:
		[XuPromise force.
		retVal isBroken ifTrue: [retVal explode]].
	^retVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XuFillDetector class
	instanceVariableNames: ''!

(XuFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XuFillDetector class methodsFor: 'pseudo-constructors'!

make: anFeFillDetector {FeFillDetector}
	^self create: anFeFillDetector!

{XuFillDetector} makeBroken: problem {Problem star}
	| broke {XuFillDetector} |
	broke _ self create.Problem: problem.
	XuPromise savePromise: broke.
	^broke!

{XuFillDetector} makeBrokenBy: broken {XuPromise}
	^self create.Promise: broken.! !